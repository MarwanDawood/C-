/* Copyright 2013-2019 The MathWorks, Inc. */
#ifndef _MW_COMMON_H_
#define _MW_COMMON_H_
#if defined(_MATLABIO_)
    #include "rpi_rtwtypes.h" 
#else
    #include "rtwtypes.h"
#endif

#define __MATLAB_SERVER_VERSION_YEAR   (18)   /* Release year */
#define __MATLAB_SERVER_VERSION_REL     (2)   /* 1 for 'a', 2 for 'b' */
#define __MATLAB_SERVER_VERSION_BUILD   (2)   /* Build number */
#ifdef _DEBUG
   #define LOG_PRINT(fd, format, ...) fprintf(fd, format, __VA_ARGS__); fflush(fd)
#else 
   #define LOG_PRINT(fd, msg, ...)
#endif 

#endif /* _MW_COMMON_H_ */
