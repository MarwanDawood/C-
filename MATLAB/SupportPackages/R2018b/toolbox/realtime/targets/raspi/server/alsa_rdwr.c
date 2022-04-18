/* Copyright 2018 The MathWorks, Inc. */

/**
 * File:    alsa_rdwr.c
 * Description: This file contains routines to test the audio devide.
 *  
 */
/*----------------------------------------------------------------------------
 *        Headers
 *----------------------------------------------------------------------------*/
#include <stdio.h>
#include<signal.h>
#include <unistd.h>
#include <sched.h>
#include <malloc.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <fcntl.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <time.h>
#include <locale.h>
#include <alsa/asoundlib.h>
#include <assert.h>
#include <termios.h>
#include <sys/poll.h>
#include <sys/uio.h>
#include <sys/time.h>
#include <sys/signal.h>
#include <sys/stat.h>
#include <asm/byteorder.h>
#include <sys/types.h>
#include <inttypes.h>
#include <byteswap.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <mqueue.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <alsa/asoundlib.h>
#include <sys/time.h>
#include <math.h>
#include "alsa_rdwr.h"
#include "handler.h"


/*----------------------------------------------------------------------------
 *        Global Variables
 *----------------------------------------------------------------------------*/
pthread_t eowtid;
void ex_program(int32_t sig);
int8_t *buffer;


#if __BYTE_ORDER == __LITTLE_ENDIAN
#else /* __BIG_ENDIAN */
#define LE_SHORT(v)             bswap_16(v)
#endif
#include <math.h>

static int32_t set_hwparams(struct audioHandleData *audioData, 
    snd_pcm_hw_params_t *params, 
    snd_pcm_access_t access, 
    snd_pcm_format_t   format,
    int32_t channels,
    int32_t rate,
    int32_t type)
{
    snd_pcm_uframes_t  size;
    uint32_t rrate;
    int32_t          err;
    snd_pcm_uframes_t     period_size_min;
    snd_pcm_uframes_t     period_size_max;
    snd_pcm_uframes_t     buffer_size_min;
    snd_pcm_uframes_t     buffer_size_max;

    /* choose all parameters */
    err = snd_pcm_hw_params_any(audioData->cHandleG, params);
    if (err < 0) {
        fprintf(stderr, "Broken configuration for playback: no configurations available: %s\n", snd_strerror(err));
        return err;
    }

    /* set the interleaved read/write format */
    err = snd_pcm_hw_params_set_access(audioData->cHandleG, params, access);
    if (err < 0) {
        fprintf(stderr, "Access type not available for playback: %s\n", snd_strerror(err));
        return err;
    }

    /* set the sample format */
    err = snd_pcm_hw_params_set_format(audioData->cHandleG, params, format);
    if (err < 0) {
        fprintf(stderr, "Sample format not available for playback: %s\n", snd_strerror(err));
        return err;
    }

    /* set the count of channels */
    err = snd_pcm_hw_params_set_channels(audioData->cHandleG, params, channels);
    if (err < 0) {
        fprintf(stderr, "Channels count (%i) not available for playbacks: %s\n", channels, snd_strerror(err));
        return err;
    }

    /* set the stream rate */
    rrate = rate;
    err = snd_pcm_hw_params_set_rate(audioData->cHandleG, params, rate, 0);
    if (err < 0) {
        fprintf(stderr, "Rate %iHz not available for playback: %s\n", rate, snd_strerror(err));
        return err;
    }

    if (rrate != rate) {
        fprintf(stderr, "Rate doesn't match (requested %iHz, get %iHz, err %d)\n", rate, rrate, err);
        return -EINVAL;
    }

    //printf("Rate set to %iHz (requested %iHz)\n", rrate, rate);
    /* set the buffer time */
    err = snd_pcm_hw_params_get_buffer_size_min(params, &buffer_size_min);
    err = snd_pcm_hw_params_get_buffer_size_max(params, &buffer_size_max);
    err = snd_pcm_hw_params_get_period_size_min(params, &period_size_min, NULL);
    err = snd_pcm_hw_params_get_period_size_max(params, &period_size_max, NULL);

    /* set the buffer time */
    err = snd_pcm_hw_params_set_buffer_time_near(audioData->cHandleG, params, &audioData->bufferTime, NULL);
    if (err < 0) {
        printf("Unable to set buffer time %i for playback: %s\n", audioData->bufferTime, snd_strerror(err));
        return err;
    }
    err = snd_pcm_hw_params_get_buffer_size(params, &size);
    if (err < 0) {
        printf("Unable to get buffer size for playback: %s\n", snd_strerror(err));
        return err;
    }
    audioData->bufferSize = size;

    if (audioData->periodTime > 0) {
        err = snd_pcm_hw_params_set_period_time_near(audioData->cHandleG, params, &audioData->periodTime, NULL);
        if (err < 0) {
            printf("Unable to set period time %u us for playback: %s\n",
                    audioData->periodTime, snd_strerror(err));
            return err;
        }
    }
    /* write the parameters to device */
    err = snd_pcm_hw_params(audioData->cHandleG, params);
    if (err < 0) {
        fprintf(stderr, "Unable to set hw params for playback: %s\n", snd_strerror(err));
        return err;
    }
    snd_pcm_hw_params_get_buffer_size(params, &audioData->bufferSize);
    snd_pcm_hw_params_get_period_size(params, &audioData->periodSize, NULL);
    if (type == CAPTURE){
        audioData->cBufferSize = audioData->bufferSize;
        audioData->cPeriodSizeG = audioData->periodSize;
    }
    return 0;
}

static int32_t set_swparams(struct audioHandleData *audioData, snd_pcm_sw_params_t *swparams, int32_t type) 
{
    int32_t err;
    audioData->bufferSize = audioData->cBufferSize;
    audioData->periodSize = audioData->cPeriodSizeG;
    /* get the current swparams */
    err = snd_pcm_sw_params_current(audioData->cHandleG, swparams);
    if (err < 0) {
        fprintf(stderr, "Unable to determine current swparams for playback: %s\n", snd_strerror(err));
        return err;
    }

    /* start the transfer when a buffer is full */
    err = snd_pcm_sw_params_set_start_threshold(audioData->cHandleG, swparams, audioData->bufferSize);
    if (err < 0) {
        fprintf(stderr, "Unable to set start threshold mode for playback: %s\n", snd_strerror(err));
        return err;
    }

    /* allow the transfer when at least period_size frames can be processed */
    err = snd_pcm_sw_params_set_avail_min(audioData->cHandleG, swparams, audioData->periodSize);
    if (err < 0) {
        fprintf(stderr, "Unable to set avail min for playback: %s\n", snd_strerror(err));
        return err;
    }

    /* write the parameters to the playback device */
    err = snd_pcm_sw_params(audioData->cHandleG, swparams);
    if (err < 0) {
        fprintf(stderr, "Unable to set sw params for playback: %s\n", snd_strerror(err));
        return err;
    }
    return 0;
}
int checkDevice( char *devName)
{
    snd_pcm_t *cHandleG;
    int err=-1;
    if ((err = snd_pcm_open(&cHandleG, devName, SND_PCM_STREAM_CAPTURE, SND_PCM_NONBLOCK)) < 0) 
    {
        printf("Capture  open error: %d,%s\n", err,snd_strerror(err));
        return -1;
    }
    else
    {
        err = snd_pcm_close(cHandleG);
        if(err == 0)
        {
#if DEBUG
            printf(" audio snd_pcm_close sucessfull\n");
#endif
        }
        else
        {
            perror(" AUDIO and_pcm_close  error:");
        }
        return 0;
    }
    return 0;
}

/* This function will initialize the pcm */

int32_t pcminit(unsigned int samplesPerFrame,unsigned short sampleRate, char *devName, short logType, struct audioHandleData *audioData)
{
    float c=((float)samplesPerFrame/(float)sampleRate);
    audioData->periodTime=(unsigned int)(c*1000000);
    audioData->bufferTime=(unsigned int)(c*10000000);
    snd_pcm_hw_params_t *cparams; 
    snd_pcm_sw_params_t *cswparams;
    snd_output_t *log;
    int32_t err = 0;
    /* Audio parameters, these parameters have to be tune */
    snd_pcm_access_t access = SND_PCM_ACCESS_RW_INTERLEAVED;
    snd_pcm_format_t format =  SND_PCM_FORMAT_S16_LE;
    int32_t channels = 1; /* for mono */
    int32_t rate = sampleRate + 2;; /* sample rate */ 
    snd_pcm_hw_params_alloca(&cparams);
    snd_pcm_sw_params_alloca(&cswparams);
    (void) signal(SIGINT, ex_program);
    snd_output_stdio_attach(&log, stderr, 0);
    if ((err = snd_pcm_open(&audioData->cHandleG, devName, SND_PCM_STREAM_CAPTURE, SND_PCM_NONBLOCK)) < 0) {
        printf("Record open error: %s\n", snd_strerror(err));
        goto out;
    }

    if ((err = set_hwparams(audioData, cparams, access, format, channels, rate, CAPTURE)) < 0) {
        printf("Setting of hwparams failed: %s\n", snd_strerror(err));
        snd_pcm_close(audioData->cHandleG);
        goto out;
    }

    if ((err = set_swparams(audioData, cswparams, CAPTURE)) < 0) {
        snd_pcm_close(audioData->cHandleG);
        goto out;
    }
    return err;
out:
    return err;
}
/*
 *  Underrun and suspend recovery
 */
static int32_t xrun_recovery(snd_pcm_t *handle, int32_t err) {
    if (err == -EPIPE) {  /* under-run */
        err = snd_pcm_prepare(handle);
        if (err < 0)
            fprintf(stderr, "Can't recovery from underrun, prepare failed: %s\n", snd_strerror(err));
        return 0;
    }
    else if (err == -ESTRPIPE) {

        while ((err = snd_pcm_resume(handle)) == -EAGAIN)
            sleep(1); /* wait until the suspend flag is released */

        if (err < 0) {
            err = snd_pcm_prepare(handle);
            if (err < 0)
                fprintf(stderr, "Can't recovery from suspend, prepare failed: %s\n", snd_strerror(err));
        }
        return 0;
    }
    return err;
}


/*
 * Transfer method - write only
 */

int32_t pcmwritebuf(snd_pcm_t *handle, int8_t *ptr, int32_t cptr)
{
    int32_t err;
    while (cptr > 0) {
        err = snd_pcm_writei(handle, ptr, cptr);
        if (err == -EAGAIN)
            continue;
        if (err < 0) {
            fprintf(stderr, "Write error: %d,%s\n", err, snd_strerror(err));
            if (xrun_recovery(handle, err) < 0) {
                fprintf(stderr, "xrun_recovery failed: %d,%s\n", err, snd_strerror(err));
                return -1;
            }
            break;    /* skip one period */
        }
        ptr += snd_pcm_frames_to_bytes(handle, err);
        cptr -= err;
    }
    return 0;
}

long pcmreadbuf(snd_pcm_t *handle, uint8_t *buf, long len)
{
    long r;
    do {
        /* Read interleaved frames from a PCM.*/
        /*Parameters:
         * pcm    PCM handle
         *  buffer    frames containing buffer
         *  size    frames to be written
         * Returns:
         * a positive number of frames actually read otherwise a negative error code */ 

        r = snd_pcm_readi(handle, buf, len);
        if (r > 0) {
            buf += snd_pcm_frames_to_bytes(handle, r);
            len -= r;
        }
    } while (r >= 1 && len > 0);
    return r;
}


/* This function will close the pcm */
void pcmexit( struct audioHandleData *audioData)
{
    int err;
    err = snd_pcm_drop(audioData->cHandleG);
    if(err == 0)
    {
#if DEBUG
        printf(" audio snd_pcm_drain sucessfull\n");
#endif
    }
    else
    {
        perror(" AUDIO and_pcm_drain  error:");
    }
    err = snd_pcm_close(audioData->cHandleG);
    if(err == 0)
    {
#if DEBUG
        printf(" audio snd_pcm_close sucessfull\n");
#endif
    }
    else
    {
        perror(" AUDIO and_pcm_close  error:");
    }
    free(buffer);
}

/* This function will exit the application */
void ex_program(int32_t sig) 
{
    fprintf(stderr,"Closing Handlers...!!\n");

    exit(1);
}




