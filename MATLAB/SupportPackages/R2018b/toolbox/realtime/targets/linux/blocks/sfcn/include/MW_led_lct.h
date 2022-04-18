#ifndef MW_LED_LCT_H
#define MW_LED_LCT_H

#if defined(_RUNONTARGETHARDWARE_BUILD_)
/* This will be called by the target compiler:    */
#include "MW_led.h"

#else
/* This will be compiled by MATLAB to create the Simulink block:            */

/* Model Start function*/
#define MW_ledInit(deviceFile) (0)

/* Model Step function*/
#define MW_ledWrite(deviceFile,inData) (0)

/* Model Terminate function*/
#define MW_ledTerminate(deviceFile) (0)

#endif /*MATLAB_MEX_FILE*/
#endif /*MW_led_lct.h*/
 
