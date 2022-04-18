/* Copyright 2012-2016 The MathWorks, Inc. */
#ifndef _MW_GPIO_H_
#define _MW_GPIO_H_
#include "rtwtypes.h"
#ifdef __cplusplus
extern "C" {
#endif

#if (defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER))
 /* This will be run in Rapid Accelerator Mode */
 #define MW_gpioInit(pin, direction)  (0)
 #define MW_gpioTerminate(pin)        (0)
 #define MW_gpioRead(pin)             (0)    
 #define MW_gpioWrite(pin, value)     (0)
#else    
 #define GPIO_DIRECTION_INPUT         (0) 
 #define GPIO_DIRECTION_OUTPUT        (1)
 void MW_gpioInit(const uint32_T pin, const boolean_T direction);
 void MW_gpioTerminate(const uint32_T pin);
 boolean_T MW_gpioRead(const uint32_T pin);
 void MW_gpioWrite(const uint32_T pin, const boolean_T value);
#endif

#ifdef __cplusplus
}
#endif
#endif

