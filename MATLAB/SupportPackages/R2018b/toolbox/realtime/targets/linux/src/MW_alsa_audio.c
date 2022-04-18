/* Copyright 2010-2015 The MathWorks, Inc. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#define ALSA_PCM_NEW_HW_PARAMS_API
#include <alsa/asoundlib.h>
#include <sys/time.h>
#include <sys/signal.h>
#include "MW_alsa_audio.h"

/* #define _DEBUG                   (1)*/
#define NUM_BYTES_PER_SAMPLE     (2)
#define USEC_FACTOR              (1000000u)
#define MAX_DEVICE_NAME          (80)
#define MAX_NUM_CHANNELS         (16)
#define PERIOD_TIME              (0.1)
#define QF_FACTOR                (5)
#define GET_CHUNK_SIZE(count, periodSize) ((count) > (periodSize) ? (periodSize):(count))
#ifdef _DEBUG
 #define DEBUG_PRINT(format, ...) printf(format, __VA_ARGS__)
#else
 #define DEBUG_PRINT(format, ...)
#endif
#define INFO_PRINT(format, ...) printf(format, __VA_ARGS__)


typedef struct {
    char device[MAX_DEVICE_NAME];
    int type;        /* Capture or playback */
    int rate;
    int resample;
    int channels;
    double queueDuration;
    double frameDuration;
    void *buf;
    snd_pcm_t *handle;
    snd_pcm_access_t access;
    snd_pcm_format_t format;
    snd_pcm_uframes_t periodSize;
    snd_pcm_uframes_t bufferSize;
    uint32_T frameSize;
    snd_pcm_uframes_t startThreshold;
#ifdef _DEBUG
    snd_output_t *output;
#endif
} audioDeviceParams_t;
static int numAudioDevices = 0;
static audioDeviceParams_t *audioDevices = NULL;


/* Function used to keep track of number of samples */
#ifdef _DEBUG
void showstat(snd_pcm_t *handle, int frameCounter)
{
    int err;
    snd_pcm_status_t *status;
    
    snd_pcm_status_alloca(&status);
    if ((err = snd_pcm_status(handle, status)) < 0) {
        DEBUG_PRINT("Error reading stream status: %s\n", snd_strerror(err));
        return;
    }
    DEBUG_PRINT("frm,%d,%ld\n", frameCounter, snd_pcm_status_get_avail(status));
}
#endif


/* Sets ALSA software parameters */
static int set_swparams(audioDeviceParams_t *devPtr)
{
    int err;
    snd_pcm_sw_params_t *swparams;
    
    if ((err = snd_pcm_sw_params_malloc(&swparams)) < 0) {
        INFO_PRINT("snd_pcm_sw_params_malloc: %s\n",
                snd_strerror (err));
        return err;
    }
    
    /* get the current swparams */
    err = snd_pcm_sw_params_current(devPtr->handle, swparams);
    if (err < 0) {
        INFO_PRINT("snd_pcm_sw_params_current: %s\n",
                snd_strerror(err));
        return err;
    }
    
    /* PLAYBACK: start the transfer when the buffer is almost full */
    /* CAPTURE : start the transfer when there is one sample captured */
    err = snd_pcm_sw_params_set_start_threshold(devPtr->handle, swparams, devPtr->startThreshold);
    if (err < 0) {
        INFO_PRINT("snd_pcm_sw_params_set_start_threshold: %s\n",
                snd_strerror(err));
        return err;
    }
    
    /* allow the transfer when at least periodSize samples can be processed */
    err = snd_pcm_sw_params_set_avail_min(devPtr->handle, swparams, devPtr->periodSize);
    if (err < 0) {
        INFO_PRINT("snd_pcm_sw_params_set_avail_min: %s\n", 
                snd_strerror(err));
        return err;
    }
    
    /* write the parameters to the playback device */
    err = snd_pcm_sw_params(devPtr->handle, swparams);
    if (err < 0) {
        INFO_PRINT("snd_pcm_sw_params: %s\n", 
                snd_strerror(err));
        return err;
    }
    snd_pcm_sw_params_free(swparams);
    
    return 0;
}

/* Sets ALSA hardware parameters */
static int set_hwparams(audioDeviceParams_t *devPtr)
{
    unsigned int rrate;
    snd_pcm_uframes_t size, maxBufferSize;
    int err, dir;
    snd_pcm_hw_params_t *params;
    unsigned int max_queueDuration;
    unsigned int buffer_time, period_time;
    
    if ((err = snd_pcm_hw_params_malloc(&params)) < 0) {
        INFO_PRINT("snd_pcm_hw_params_malloc: %s\n",
                snd_strerror(err));
        return err;
    }
    
    /* choose all parameters */
    err = snd_pcm_hw_params_any(devPtr->handle, params);
    if (err < 0) {
        INFO_PRINT("snd_pcm_hw_params_any: %s\n",
                snd_strerror(err));
        return err;
    }
    
    /* set hardware resampling */
    err = snd_pcm_hw_params_set_rate_resample(devPtr->handle, params, devPtr->resample);
    if (err < 0) {
        INFO_PRINT("snd_pcm_hw_params_set_rate_resample: %s\n", 
                snd_strerror(err));
        return err;
    }
    
    /* set interleaved/non-interleaved access */
    err = snd_pcm_hw_params_set_access(devPtr->handle, params, SND_PCM_ACCESS_RW_NONINTERLEAVED);
    if (err < 0) {
        err = snd_pcm_hw_params_set_access(devPtr->handle, params, SND_PCM_ACCESS_RW_INTERLEAVED);
        if (err < 0) {
            INFO_PRINT("snd_pcm_hw_params_set_access: %s\n",
                    snd_strerror(err));
            return err;
        }
        devPtr->access = SND_PCM_ACCESS_RW_INTERLEAVED;
    }
    else {
        devPtr->access = SND_PCM_ACCESS_RW_NONINTERLEAVED;
    }
    
    /* set the sample format */
    err = snd_pcm_hw_params_set_format(devPtr->handle, params, devPtr->format);
    if (err < 0) {
        INFO_PRINT("snd_pcm_hw_params_set_format: %s\n", 
                snd_strerror(err));
        return err;
    }
    
    /* set number of channels */
    err = snd_pcm_hw_params_set_channels(devPtr->handle, params, devPtr->channels);
    if (err < 0) {
        INFO_PRINT("Channel count (%i) not available for playback: %s\n",
                devPtr->channels, snd_strerror(err));
        devPtr->channels = 1;
        err = snd_pcm_hw_params_set_channels(devPtr->handle, params, devPtr->channels);
        if (err < 0) {
            INFO_PRINT("Error setting number of channels to (%i): %s\n",
                    devPtr->channels, snd_strerror(err));
            return err;
        }
    }
    
    /* set the stream rate */
    rrate = devPtr->rate;
    err = snd_pcm_hw_params_set_rate_near(devPtr->handle, params, &rrate, 0);
    if (err < 0) {
        INFO_PRINT("Sampling rate of %iHz not available for playback: %s\n", 
                devPtr->rate, snd_strerror(err));
        return err;
    }
    if (rrate != devPtr->rate) {
        INFO_PRINT("Requested sampling rate is not available: (requested %iHz, got %iHz)\n", 
                devPtr->rate, rrate);
        return -EINVAL;
    }
    
    /* Set buffer size */
    buffer_time = devPtr->queueDuration * USEC_FACTOR;
    err = snd_pcm_hw_params_set_buffer_time_near(devPtr->handle, params, &buffer_time, 0);
    if (err < 0) {
        INFO_PRINT("snd_pcm_hw_params_set_buffer_time_near: %s\n", 
                snd_strerror(err));
        return err;
    }
    
    /* Set period size */ 
    period_time = PERIOD_TIME * USEC_FACTOR;
    period_time = ((QF_FACTOR * period_time) > buffer_time) ? (buffer_time/QF_FACTOR):period_time;
    snd_pcm_hw_params_set_period_time_near(devPtr->handle, params, &period_time, 0);
    if (err < 0) {
        INFO_PRINT("snd_pcm_hw_params_set_period_time_near: %s\n", 
                snd_strerror(err));
        return err;
    }
    
    /* Get actual buffer size & period size */
    err = snd_pcm_hw_params_get_buffer_size(params, &devPtr->bufferSize);
    if (err < 0) {
        INFO_PRINT("snd_pcm_hw_params_get_buffer_size: %s\n", 
                snd_strerror(err));
        return err;
    }
    snd_pcm_hw_params_get_period_size(params, &devPtr->periodSize, 0);
    if (err < 0) {
        INFO_PRINT("snd_pcm_hw_params_get_period_size: %s\n", 
                snd_strerror(err));
        return err;
    }
    
    /* Write HW parameters to device */
    err = snd_pcm_hw_params(devPtr->handle, params);
    if (err < 0) {
        INFO_PRINT("snd_pcm_hw_params: %s\n", snd_strerror(err));
        return err;
    }
    
    /* Release resources */
    snd_pcm_hw_params_free(params);
    
    return 0;
}

/* Recover from overrun / underrun errors */
static int xrun_recovery(snd_pcm_t *handle, int err)
{
    if (err == -EPIPE) {
        err = snd_pcm_prepare(handle);
        if (err < 0) {
            INFO_PRINT("snd_pcm_prepare (EPIPE): %s\n",
                    snd_strerror(err));
        }
    }
    else if (err == -ESTRPIPE) {
        while ((err = snd_pcm_resume(handle)) == -EAGAIN) {
            /* wait until the suspend flag is released */
        }
        if (err < 0) {
            err = snd_pcm_prepare(handle);
            if (err < 0) {
                INFO_PRINT("snd_pcm_prepare (ESTRPIPE): %s\n",
                        snd_strerror(err));
            }
        }
    }
    return err;
}

/* Return a pointer to audio device structure for a given device name */
audioDeviceParams_t *MW_getDeviceInfo(const char *device, const int type)
{
    int i;
    audioDeviceParams_t *ptr;
    
    ptr = NULL;
    for (i = 0; i < numAudioDevices; i++) {
        if ((strncmp(audioDevices[i].device, device, MAX_DEVICE_NAME) == 0) &&
                (audioDevices[i].type == type)) {
            ptr = &audioDevices[i];
            break;
        }
    }
    
    return ptr;
}

/* Terminate function for one device */
void MW_audioTerminate(const uint8_T *device, int type)
{
    audioDeviceParams_t *devPtr;
    static int32_T numClosedAudioDevices = 0;
    
    devPtr = MW_getDeviceInfo(device, type);
    if (devPtr == NULL) {
        return;
    }
    if (devPtr->handle != NULL) {
        snd_pcm_close(devPtr->handle);
        devPtr->handle == NULL;
    }
    numClosedAudioDevices++;
    if ((numClosedAudioDevices == numAudioDevices) && !audioDevices) {
        free(audioDevices);
    }
}

/* Return resources used for audio devices in case of a fatal error */
void MW_audioExit(void)
{
    int i;
    
    for (i = 0; i < numAudioDevices; i++) {
        MW_audioTerminate(audioDevices[i].device, audioDevices[i].type);
    }
    exit(EXIT_FAILURE);
}

static void adjust_queueDuration(audioDeviceParams_t *devPtr)
{
    /* Make queueDuration an integer multiple of frameDuration */
    devPtr->queueDuration = ((int)(devPtr->queueDuration / devPtr->frameDuration + 0.5)) * devPtr->frameDuration;
    
    /* queuDuration should be at least four times frameDuration */
    devPtr->queueDuration = (devPtr->queueDuration < (QF_FACTOR*devPtr->frameDuration)) ?
        (QF_FACTOR*devPtr->frameDuration):devPtr->queueDuration;
}

/* Audio initialization function */
void MW_audioInit(
        const uint8_T *device,
        const uint32_T sampleRate,
        const uint32_T numChannels,
        const real_T queueDuration,
        const uint32_T frameSize,
        const MW_Audio_Data_Type audioDataType,
        const int32_T type)
{
    int err;
    int numBytes = 2;
    audioDeviceParams_t *devPtr;
    
    audioDevices = realloc(audioDevices, (numAudioDevices + 1) * sizeof(audioDeviceParams_t));
    if (audioDevices == NULL) {
        INFO_PRINT("Error allocating memory for audio device '%s'.\n", device);
        MW_audioExit();
    }
    devPtr = audioDevices + numAudioDevices;
    
    /* Initialize hardware parameters */
    strncpy(&devPtr->device[0], device, MAX_DEVICE_NAME);
    devPtr->type          = type;
    devPtr->resample      = 1;
    devPtr->access        = SND_PCM_ACCESS_RW_NONINTERLEAVED;
    devPtr->channels      = numChannels;
    devPtr->rate          = sampleRate;
    devPtr->queueDuration = queueDuration;
    devPtr->frameSize     = frameSize;
    devPtr->frameDuration = ((double)frameSize) / ((double)sampleRate);

    switch (audioDataType){
        case MW_AUDIO_8:
            devPtr->format = SND_PCM_FORMAT_S8;
            numBytes = 1;
            break;
        case MW_AUDIO_16:
            devPtr->format = SND_PCM_FORMAT_S16_LE;
            numBytes = 2;
            break;
        case MW_AUDIO_32:
            devPtr->format = SND_PCM_FORMAT_S32_LE;
            numBytes = 4;
            break;
        default:
            devPtr->format = SND_PCM_FORMAT_S16_LE;
            numBytes = 2;
            break;
    }
    numAudioDevices++;
    
    /* Adjust queue duration to be a multiple of frameSize*/
    adjust_queueDuration(devPtr);
    
    /* Open PCM device. The last parameter of this function is the mode. */
    if ((err = snd_pcm_open(&devPtr->handle, devPtr->device, devPtr->type, 0)) < 0) {
        INFO_PRINT("Cannot open audio device '%s': %s\n",
                devPtr->device, snd_strerror(err));
        MW_audioExit();
    }
    
    /* Set hw parameters */
    if ((err = set_hwparams(devPtr)) < 0) {
        INFO_PRINT("Error setting audio hardware parameters for '%s': %s\n", 
                devPtr->device, snd_strerror(err));
        MW_audioExit();
    }
    
    /* Initialize software parameters */
    if (devPtr->type == SND_PCM_STREAM_CAPTURE) {
        devPtr->startThreshold = 1;
    }
    else {
        devPtr->startThreshold = devPtr->bufferSize - devPtr->periodSize;
    }
    if ((err = set_swparams(devPtr)) < 0) {
        INFO_PRINT("Error setting audio software parameters for '%s': %s\n", 
                devPtr->device, snd_strerror(err));
        MW_audioExit();
    }
    
    /* Allocate playback buffer */
    if (devPtr->access == SND_PCM_ACCESS_RW_INTERLEAVED) {
        devPtr->buf = malloc(devPtr->frameSize * devPtr->channels * numBytes);
        if (devPtr->buf == NULL) {
            fprintf(stderr, "Cannot allocate memory for audio buffer.\n");
            MW_audioExit();
        }
    }
    
    /* Prepare PCM device for use */
    if ((err = snd_pcm_prepare(devPtr->handle)) < 0) {
        INFO_PRINT("snd_pcm_prepare: %s\n", snd_strerror(err));
        MW_audioExit();
    }
    
#ifdef _DEBUG
    err = snd_output_stdio_attach(&devPtr->output, stdout, 0);
    if (err < 0) {
        DEBUG_PRINT("snd_output_stdio_attach: %s\n", snd_strerror(err));
    }
    snd_pcm_dump(devPtr->handle, devPtr->output);
#endif
}

/* Hook functions */
void audioPlaybackInit(
        const uint8_T *device, 
        const uint32_T sampleRate, 
        const uint32_T numChannels,
        const real_T queueDuration, 
        const uint32_T frameSize,
        const MW_Audio_Data_Type audioDataType)
{
    /* Use common initialization function */
    MW_audioInit(device, sampleRate, numChannels, queueDuration, frameSize, audioDataType, SND_PCM_STREAM_PLAYBACK);
}

void audioCaptureInit(
        const uint8_T *device, 
        const uint32_T sampleRate, 
        const uint32_T numChannels,
        const real_T queueDuration, 
        const uint32_T frameSize,
        const MW_Audio_Data_Type audioDataType)
{
    /* Use common initialization function */
    MW_audioInit(device, sampleRate, numChannels, queueDuration, frameSize, audioDataType, SND_PCM_STREAM_CAPTURE);
}


// De-interleaver for int16/uint16
void MW_deinterleave_16(void *dst, void *src, uint32_T frameSize, uint32_T numChannels)
{
    int i, j; 
    int16_T *pSrc = src, *pDst = dst;
    
    for (i = 0; i < frameSize; i++) { 
        for (j = 0; j < numChannels; j++) { 
            *(pDst + j*frameSize) = *pSrc++;
        } 
        pDst++; 
    } 
} 

// De-interleaver for int32
void MW_deinterleave_32(void *dst, void *src, uint32_T frameSize, uint32_T numChannels)
{
    int i, j; 
    int32_T *pSrc = src, *pDst = dst;
    
    for (i = 0; i < frameSize; i++) { 
        for (j = 0; j < numChannels; j++) { 
            *(pDst + j*frameSize) = *pSrc++;
        } 
        pDst++; 
    } 
} 

// De-interleaver for int8
void MW_deinterleave_8(void *dst, void *src, uint32_T frameSize, uint32_T numChannels)
{
    int i, j; 
    int8_T *pSrc = src, *pDst = dst;
    
    for (i = 0; i < frameSize; i++) { 
        for (j = 0; j < numChannels; j++) { 
            *(pDst + j*frameSize) = *pSrc++;
        } 
        pDst++; 
    } 
} 

// Interleaver for int8
void MW_interleave_8(void *dst, void *src, uint32_T frameSize, uint32_T numChannels)
{
    int i,j,numBytes = 1;
    int8_T *pSrc = src, *pDst = dst;
    if (numChannels == 1) {
        /*No need to convert */
        memcpy(dst,(const void *)src, frameSize * numBytes);
    }
    else {
        for (i = 0; i< frameSize; i++) {
            for (j = 0; j < numChannels; j++) {
                *pDst++ = *(pSrc + (j*frameSize));
            }
            pDst++;
        }
    }
}

// Interleaver for int16
void MW_interleave_16(void *dst, void *src, uint32_T frameSize, uint32_T numChannels)
{
    int i,j,numBytes = 2;
    int16_T *pSrc = src, *pDst = dst;
    if (numChannels == 1) {
        /*No need to convert */
        memcpy(dst,(const void *)src, frameSize * numBytes);
    }
    else {
        for (i = 0; i< frameSize; i++) {
            for (j = 0; j < numChannels; j++) {
                *pDst++ = *(pSrc + (j*frameSize));
            }
            pDst++;
        }
    }
}

// Interleaver for int32
void MW_interleave_32(void *dst, void *src, uint32_T frameSize, uint32_T numChannels)
{
    int i,j,numBytes = 4;
    int32_T *pSrc = src, *pDst = dst;
    if (numChannels == 1) {
        /*No need to convert */
        memcpy(dst,(const void *)src, frameSize * numBytes);
    }
    else {
        for (i = 0; i< frameSize; i++) {
            for (j = 0; j < numChannels; j++) {
                *pDst++ = *(pSrc + (j*frameSize));
            }
            pDst++;
        }
    }
}

static void readInterleaved(audioDeviceParams_t *devPtr, MW_Audio_Data_Type audioDataType, void *outData, const uint32_T frameSize)
{
    int ret;
    void *p;
    snd_pcm_uframes_t count;
    size_t numBytes = 2;
    
    p = devPtr->buf;
    count = (snd_pcm_uframes_t) frameSize;
    while (count > 0) {
        ret = snd_pcm_readi(devPtr->handle, p, count);
        if (ret == -EAGAIN) {
            continue;
        }
        if(ret < 0) {
            INFO_PRINT("Capture overrun: errno=%d (%s)\n", ret, snd_strerror(ret));
            if (xrun_recovery(devPtr->handle, ret) < 0) {
                INFO_PRINT("Cannot recover from overrun: %s\n",
                        snd_strerror(ret));
            }
        }
        else {
            switch (audioDataType){
                case MW_AUDIO_8:
                    p = (void *)((int8_T *)p + (ret * devPtr->channels));
                    numBytes = 1;
                    break;
                case MW_AUDIO_16:
                    p = (void *)((int16_T *)p + (ret * devPtr->channels));
                    numBytes = 2;
                    break;
                case MW_AUDIO_32:
                    p = (void *)((int32_T *)p + (ret * devPtr->channels));
                    numBytes = 4;
                    break;
                default:
                    p = (void *)((int16_T *)p + (ret * devPtr->channels));
                    numBytes = 2;
                    break;
            }
            //p     += ret * devPtr->channels;
            count -= ret;
        }
    }
    
    /* De-interleave audio samples */
    if (devPtr->channels > 1) {
        switch (audioDataType){
            case MW_AUDIO_8:
                MW_deinterleave_8(outData, devPtr->buf, frameSize, devPtr->channels);
                break;
            case MW_AUDIO_16:
                MW_deinterleave_16(outData, devPtr->buf, frameSize, devPtr->channels);
                break;
            case MW_AUDIO_32:
                MW_deinterleave_32(outData, devPtr->buf, frameSize, devPtr->channels);
                break;
            default:
                MW_deinterleave_16(outData, devPtr->buf, frameSize, devPtr->channels);
                break;
        }  
    }
    else  {
        memcpy((void *)outData, (const void *)devPtr->buf, frameSize * numBytes);
    }
}

static void readNoninterleaved(audioDeviceParams_t *devPtr, MW_Audio_Data_Type audioDataType, void *outData, const uint32_T frameSize)
{
    int ret, i;
    void *bufPtr[MAX_NUM_CHANNELS];
    snd_pcm_uframes_t count;
    
    /* Read samples fome PCM device */
    for (i = 0; i < devPtr->channels; i++) {
        switch (audioDataType){
            case MW_AUDIO_8:
                bufPtr[i] = (void *)((int8_T *)outData + i * frameSize);
                break;
            case MW_AUDIO_16:
                bufPtr[i] = (void *)((int16_T *)outData + i * frameSize);
                break;
            case MW_AUDIO_32:
                bufPtr[i] = (void *)((int32_T *)outData + i * frameSize);
                break;
            default:
                bufPtr[i] = (void *)((int16_T *)outData + i * frameSize);
                break;
        }
    }
    count = (snd_pcm_uframes_t) frameSize;
    while (count > 0) {
        ret = snd_pcm_readn(devPtr->handle, bufPtr, count);
        if (ret == -EAGAIN) {
            continue;
        }
        if(ret < 0) {
            INFO_PRINT("Capture overrun: errno=%d (%s)\n", ret, snd_strerror(ret));
            if (xrun_recovery(devPtr->handle, ret) < 0) {
                INFO_PRINT("Cannot recover from overrun: %s\n",
                        snd_strerror(ret));
            }
        }
        else {
            for (i = 0; i < devPtr->channels; i++) {
                switch (audioDataType){
                    case MW_AUDIO_8:
                        bufPtr[i] = (void *)((int8_T *)bufPtr[i] + ret);
                        break;
                    case MW_AUDIO_16:
                        bufPtr[i] = (void *)((int16_T *)bufPtr[i] + ret);
                        break;
                    case MW_AUDIO_32:
                        bufPtr[i] = (void *)((int32_T *)bufPtr[i] + ret);
                        break;
                    default:
                        bufPtr[i] = (void *)((int16_T *)bufPtr[i] + ret);
                        break;
                }
            }
            count -= ret;
        }
    }
}

static void writeInterleaved(audioDeviceParams_t *devPtr, MW_Audio_Data_Type audioDataType, void *inData, const uint32_T frameSize)
{
    int i, j, ret;
    void *p;
    snd_pcm_uframes_t count;
    
    switch (audioDataType){
        case MW_AUDIO_8:
            MW_interleave_8((void *)devPtr->buf, (void *)inData, frameSize, devPtr->channels);
            break;
        case MW_AUDIO_16:
            MW_interleave_16((void *)devPtr->buf, (void *)inData, frameSize, devPtr->channels);
            break;
        case MW_AUDIO_32:
            MW_interleave_32((void *)devPtr->buf, (void *)inData, frameSize, devPtr->channels);
            break;
        default:
            MW_interleave_16((void *)devPtr->buf, (void *)inData, frameSize, devPtr->channels);
            break;
    }
    
    /* Write interleaved samples to PCM device */
    p = devPtr->buf;
    count = (snd_pcm_uframes_t)frameSize;
    while (count > 0) {
        ret = snd_pcm_writei(devPtr->handle, p, count);
        if (ret == -EAGAIN) {
            continue;
        }
        if (ret < 0) {
            INFO_PRINT("Playback underrun: errno=%d (%s)\n", ret, snd_strerror(ret));
            if (xrun_recovery(devPtr->handle, ret) < 0) {
                INFO_PRINT("Cannot recover from underrun: %s\n",
                        snd_strerror(ret));
            }
        }
        else {
            switch (audioDataType){
                case MW_AUDIO_8:
                    p = (void *)((int8_T *)p + (ret * devPtr->channels));
                    break;
                case MW_AUDIO_16:
                    p = (void *)((int16_T *)p + (ret * devPtr->channels));
                    break;
                case MW_AUDIO_32:
                    p = (void *)((int32_T *)p + (ret * devPtr->channels));
                    break;
                default:
                    p = (void *)((int16_T *)p + (ret * devPtr->channels));
                    break;
            }
            //p     += ret * devPtr->channels;
            count -= ret;
        }
    }
}

static void writeNoninterleaved(audioDeviceParams_t *devPtr, const MW_Audio_Data_Type audioDataType, const void *inData, const uint32_T frameSize)
{
    int i, ret;
    void *bufPtr[MAX_NUM_CHANNELS];
    snd_pcm_uframes_t count;
    
    /* Write samples to PCM device */
    for (i = 0; i < devPtr->channels; i++) {
        switch (audioDataType){
            case MW_AUDIO_8:
                bufPtr[i] = (void *)((int8_T *)inData + i * frameSize);
                break;
            case MW_AUDIO_16:
                bufPtr[i] = (void *)((int16_T *)inData + i * frameSize);
                break;
            case MW_AUDIO_32:
                bufPtr[i] = (void *)((int32_T *)inData + i * frameSize);
                break;
            default:
                bufPtr[i] = (void *)((int16_T *)inData + i * frameSize);
                break;
        }
    }
    count = (snd_pcm_uframes_t)frameSize;
    while (count > 0) {
        ret = snd_pcm_writen(devPtr->handle, bufPtr, count);
        if (ret == -EAGAIN) {
           continue;
        }
        if (ret < 0) {
            INFO_PRINT("Playback underrun: errno=%d (%s)\n", ret, snd_strerror(ret));
            if (xrun_recovery(devPtr->handle, ret) < 0) {
                INFO_PRINT("Cannot recover from underrun: %s\n",
                        snd_strerror(ret));
            }
        }
        else {
            for (i = 0; i < devPtr->channels; i++) {
                switch (audioDataType){
                    case MW_AUDIO_8:
                        bufPtr[i] = (void *)((int8_T *)bufPtr[i] + ret);
                        break;
                    case MW_AUDIO_16:
                        bufPtr[i] = (void *)((int16_T *)bufPtr[i] + ret);
                        break;
                    case MW_AUDIO_32:
                        bufPtr[i] = (void *)((int32_T *)bufPtr[i] + ret);
                        break;
                    default:
                        bufPtr[i] = (void *)((int16_T *)bufPtr[i] + ret);
                        break;
                }
            }
            count -= ret;
        }
    }
}

/* Move audio samples from device driver to application */
MW_Audio_Status_Type MW_AudioRead(const uint8_T *deviceName, const MW_Audio_Data_Type audioDataType, void *data)
{
    int ret;
    audioDeviceParams_t *devPtr;
#ifdef _DEBUG
    static int frameCounter = 0;
#endif
    
    /* Get handle to audio device */
    devPtr = MW_getDeviceInfo(deviceName, SND_PCM_STREAM_CAPTURE);
    if (devPtr == NULL || devPtr->handle == NULL) {
        return;
    }
    
    /* Read samples from the capture buffer */
    if (devPtr->access == SND_PCM_ACCESS_RW_NONINTERLEAVED) {
        readNoninterleaved(devPtr, audioDataType, data, devPtr->frameSize);
    }
    else {
        readInterleaved(devPtr, audioDataType, data, devPtr->frameSize);
    }
    
#ifdef _DEBUG
    showstat(devPtr->handle, frameCounter);
    frameCounter++;
#endif

	return MW_AUDIO_SUCCESS;
}



/* Move audio samples from application to device driver */
MW_Audio_Status_Type MW_AudioWrite(const uint8_T *deviceName, const MW_Audio_Data_Type audioDataType, const void *data)
{
    int ret;
    audioDeviceParams_t *devPtr;
#ifdef _DEBUG
    static int frameCounter = 0;
#endif
   
    /* Get handle to audio device */
    devPtr = MW_getDeviceInfo(deviceName, SND_PCM_STREAM_PLAYBACK);
    if (devPtr == NULL || devPtr->handle == NULL) {
        return;
    }
    
    /* Write samples to playback buffer */
    if (devPtr->access == SND_PCM_ACCESS_RW_NONINTERLEAVED) {
        writeNoninterleaved(devPtr, audioDataType, data, devPtr->frameSize);
    }
    else {
        writeInterleaved(devPtr, audioDataType, data, devPtr->frameSize);
    }
    
#ifdef _DEBUG
    showstat(devPtr->handle, frameCounter);
    frameCounter++;
#endif
    return MW_AUDIO_SUCCESS;
}

/* Close audio device */
MW_Audio_Status_Type MW_AudioClose(const uint8_T *deviceName, 
        const MW_Audio_Direction_Type direction)
{
    if (direction == MW_AUDIO_IN) {
        MW_audioTerminate(deviceName, SND_PCM_STREAM_CAPTURE);
    }
    else {
        MW_audioTerminate(deviceName, SND_PCM_STREAM_PLAYBACK);
    }
    
    return MW_AUDIO_SUCCESS;
}

/* EOF */

