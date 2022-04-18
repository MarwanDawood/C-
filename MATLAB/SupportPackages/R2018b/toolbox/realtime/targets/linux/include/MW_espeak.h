/* Copyright 2016 The MathWorks, Inc. */
#ifndef _MW_ESPEAK_H_
#define _MW_ESPEAK_H_
#include "rtwtypes.h"
#ifdef __cplusplus
extern "C"
{
#endif
    
#if (defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER))
 /* This will be run in Rapid Accelerator Mode */
 #define MW_ESPEAK_output(text)  (0)
#else    
 // ESPEAK C-code interface
 int32_T MW_ESPEAK_output(const uint8_T *text);
#endif

#ifdef __cplusplus
}
#endif
#endif 
