// Copyright 2012 The MathWorks, Inc.
#ifndef _MW_GPIO_H_
#define _MW_GPIO_H_
#include "common.h"

// Error codes
#define ERR_GPIO_BASE               (2000)
#define ERR_GPIO_INIT_EXPORT        (ERR_GPIO_BASE+1)
#define ERR_GPIO_INIT_DIRECTION     (ERR_GPIO_BASE+2)
#define ERR_GPIO_INIT_OPEN          (ERR_GPIO_BASE+3)
#define ERR_GPIO_INIT_UNEXPORT      (ERR_GPIO_BASE+4)
#define ERR_GPIO_TERMINATE_UNEXPORT (ERR_GPIO_BASE+5)
#define ERR_GPIO_READ_READ          (ERR_GPIO_BASE+6)
#define ERR_GPIO_WRITE_WRITE        (ERR_GPIO_BASE+7)
#define ERR_GPIO_GET_DIRECTION_OPEN (ERR_GPIO_BASE+8)
#define ERR_GPIO_GET_DIRECTION_READ (ERR_GPIO_BASE+9)

// GPIO function interface
extern int EXT_GPIO_init(const unsigned int gpio, const uint8_T direction);
extern int EXT_GPIO_terminate(const unsigned int gpio);
extern int EXT_GPIO_read(const unsigned int gpio, boolean_T *value);
extern int EXT_GPIO_write(const unsigned int gpio, const boolean_T value);
extern int EXT_GPIO_getStatus(const unsigned int gpio, uint8_T *pinStatus);

#endif //_MW_GPIO_H_

