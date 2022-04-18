/* Copyright 2018 The MathWorks, Inc. */
#include <stdio.h>
#include <pthread.h>
#include "common.h"
#include "handler.h"

#define AUDIO_DEVICE_AVAILABLE	1
#define AUDIO_DEVICE_NOT_AVAILABLE	0
/** audioRecordThread:- thread function for audio peripheral.
  * pdata:- Pointer to struct peripheralData structure.
  * It return NULL pointer.
**/
extern void *audioRecordThread(void *pdata );

/* This variable used to check availability of audio device if device is available it's value will be 1. */
extern int  deviceAvailableflag;

