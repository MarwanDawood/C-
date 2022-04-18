/* Copyright 2016 The MathWorks, Inc.*/

#ifndef _MW_JOYSTICKBLOCK_H_
#define _MW_JOYSTICKBLOCK_H_
#include "rtwtypes.h"

#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
#define JOYSTICK_BLOCK_INIT() 0
#define JOYSTICK_BLOCK_READ(fd) 0
#define JOYSTICK_BLOCK_TERMINATE(fd) 0
#else
int JOYSTICK_BLOCK_INIT();
int JOYSTICK_BLOCK_READ(int fd);
int JOYSTICK_BLOCK_TERMINATE(int fd);
#endif


#endif /*_MW_JOYSTICKBLOCK_H_*/

