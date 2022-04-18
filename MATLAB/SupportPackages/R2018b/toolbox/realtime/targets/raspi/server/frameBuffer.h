// Copyright 2016 The MathWorks, Inc.
#ifndef _MW_FRAMEBUFFER_H_
#define _MW_FRAMEBUFFER_H_
#include "common.h"
#if defined(_MATLABIO_)
  #include "rpi_rtwtypes.h"
#else
  #include "rtwtypes.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif
    
#define ERR_FRAMEBUFFER_BASE               (7500)
#define ERR_FRAMEBUFFER_NOTFOUND           (ERR_FRAMEBUFFER_BASE+1)
#define ERR_FRAMEBUFFER_OPEN               (ERR_FRAMEBUFFER_BASE+2)
#define ERR_FRAMEBUFFER_ORIENTATION        (ERR_FRAMEBUFFER_BASE+3)

int32_T EXT_FRAMEBUFFER_INIT(char *sh_fbname, uint16_t *FileNameLength);
int32_T EXT_FRAMEBUFFER_WRITEPIXEL(char *sh_fbname, const uint16_t pxllocation, const uint16_t pxlvalue);
int32_T EXT_FRAMEBUFFER_DISPLAYIMAGE(char *sh_fbname, const uint8_t flip, const uint16_t *imgArray);
int32_T EXT_FRAMEBUFFER_DISPLAYMESSAGE(char *sh_fbname, uint16_t *strArray, const uint16_t strArrayLen, const uint16_t orientation, const uint16_t scrollSpeed);
int32_T EXT_FRAMEBUFFER_CLEAR(char *sh_fbname);

#ifdef __cplusplus
}
#endif
#endif 

