/* Copyright 2012-2015 The MathWorks, Inc. */
#ifndef _MW_ALSA_AUDIO_H_
#define _MW_ALSA_AUDIO_H_
#include "rtwtypes.h"
#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    MW_AUDIO_SUCCESS = 0x00,
    MW_AUDIO_ERROR   = 0x01,
} MW_Audio_Status_Type;

typedef enum {
    MW_AUDIO_IN = 0,
    MW_AUDIO_OUT,
} MW_Audio_Direction_Type;

typedef enum {
    MW_AUDIO_8 = 0,
    MW_AUDIO_16,
    MW_AUDIO_32,
} MW_Audio_Data_Type;


#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
/* Used in rapid accelerator mode */
#define audioPlaybackInit(device, sampleRate, numberOfChannels, queueDuration, frameSize, audioDataType)
#define audioCaptureInit(device, sampleRate, numberOfChannels, queueDuration, frameSize, audioDataType)
#define MW_AudioRead(device, audioDataType, outData)
#define MW_AudioWrite(device, audioDataType, inData)
#define MW_AudioClose(device,direction)

#else 
void audioPlaybackInit(
        const uint8_T *device,
        const uint32_T sampleRate,
		const uint32_T numberOfChannels,
        const real_T queueDuration,
        const uint32_T samplesPerFrame,
        const MW_Audio_Data_Type audioDataType);
		
void audioCaptureInit(
        const uint8_T *device,
        const uint32_T sampleRate,
		const uint32_T numberOfChannels,
        const real_T queueDuration,
        const uint32_T frameSize,
        const MW_Audio_Data_Type audioDataType);

MW_Audio_Status_Type MW_AudioRead(const uint8_T *deviceName, const MW_Audio_Data_Type audioDataType, void *data);

MW_Audio_Status_Type MW_AudioWrite(const uint8_T *deviceName, const MW_Audio_Data_Type audioDataType, const void *data);
 
MW_Audio_Status_Type MW_AudioClose(const uint8_T *deviceName, 
        const MW_Audio_Direction_Type direction);
		
#endif

#ifdef __cplusplus
}
#endif
#endif


