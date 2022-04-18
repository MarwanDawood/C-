/* Copyright 2014-2015 The MathWorks, Inc. */
#ifndef _MW_ALSA_AUDIO_CAPTURE_MACRO_H_
#define _MW_ALSA_AUDIO_CAPTURE_MACRO_H_

#if defined(ARM_PROJECT) || defined(_RUNONTARGETHARDWARE_BUILD_)
 #include "MW_alsa_audio.h"
#else
#define audioCaptureInit(device, sampleRate, queueDuration, frameSize) 
 #define audioCapture(device, outData, frameSize) 
#define audioCaptureTerminate(device) 
#endif

#endif
 
