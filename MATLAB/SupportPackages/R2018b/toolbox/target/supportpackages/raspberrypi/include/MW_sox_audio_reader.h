/* Copyright 2016 The MathWorks, Inc. */
#ifndef _MW_SOX_AUDIO_READER_H_
#define _MW_SOX_AUDIO_READER_H_
#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
#define sox_format_t void
#else
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sox.h>
#endif
#include "rtwtypes.h"
#ifdef __cplusplus
extern "C"
{
#endif

#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
#define MW_sox_init(fileName) 0
#define MW_sox_read(in,data,count) 0
#define MW_sox_terminate(in) 0
#else
// SpxAudioReader C-code interface
sox_format_t * MW_sox_init(const uint8_T *fileName);
int32_T MW_sox_read(sox_format_t **in, int32_T *data, size_t count);
int32_T MW_sox_terminate(sox_format_t *in);
#endif 

#ifdef __cplusplus
}
#endif
#endif 
