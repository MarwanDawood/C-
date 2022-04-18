// Copyright 2016 The MathWorks, Inc.
#ifndef _MW_JOYSTICK_H_
#define _MW_JOYSTICK_H_
#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif
    
#define ERR_JOYSTICK_BASE               (7000)
#define ERR_JOYSTICK_NOTFOUND           (ERR_JOYSTICK_BASE+1)
#define ERR_JOYSTICK_OPEN               (ERR_JOYSTICK_BASE+2)

int EXT_JOYSTICK_INIT(char *sh_evdevName, uint16_t * FileNameLength);
int EXT_JOYSTICK_READ(char *sh_evdevName, boolean_T *value);

#ifdef __cplusplus
}
#endif
#endif //_MW_JOYSTICK_H_

