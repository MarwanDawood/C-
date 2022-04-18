/* Copyright 2016 The MathWorks, Inc. */

#ifndef _MW_FBBLOCK_H_
#define _MW_FBBLOCK_H_

#include "rtwtypes.h"
#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )

#define FRAMEBUFFER_INIT() 0
#define FRAMEBUFFER_WRITEPIXEL( fd,  pxllocation,   pxlvalue) 0
#define FRAMEBUFFER_DISPLAYIMAGE( fd, flip, imgArray) 0
#define FRAMEBUFFER_TERMINATE( fd) 0

#else

int FRAMEBUFFER_INIT();
int FRAMEBUFFER_WRITEPIXEL(int fd, uint16_T pxllocation,  uint16_T pxlvalue);
int FRAMEBUFFER_DISPLAYIMAGE(int fd,uint8_T flip,uint16_T *imgArray);
int FRAMEBUFFER_TERMINATE(int fd);
#endif 

#endif /*_MW_FBBLOCK_H_*/