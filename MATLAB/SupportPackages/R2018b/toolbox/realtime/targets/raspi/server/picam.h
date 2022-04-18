// Copyright 2013 The MathWorks, Inc.
#ifndef _MW_PICAM_H_
#define _MW_PICAM_H_
#include "common.h"

// Error codes
#define ERR_CAMERABOARD_BASE           (6000)
#define ERR_CAMERABOARD_INIT           (ERR_CAMERABOARD_BASE+1)
#define ERR_CAMERABOARD_CONTROL        (ERR_CAMERABOARD_BASE+2)

// SPI function interface
extern int EXT_CAMERABOARD_terminate(void);
extern int EXT_CAMERABOARD_snapshot(uint8_T *data, uint32_T *dataSize);
extern int EXT_CAMERABOARD_control(const char *controlParams);
extern int EXT_CAMERABOARD_init(const int width, const int height, 
        const int frameRate, const int quality, const char *cameraParamsStr);
int8_T isRaspividRunning(void);

#endif //_MW_PICAM_H_

