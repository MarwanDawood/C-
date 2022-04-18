/* Copyright 2018 The MathWorks, Inc. */
#ifndef _AVAILABLEWEBCAM_H_
#define _AVAILABLEWEBCAM_H_
#if defined(_MATLABIO_)
    #include "rpi_rtwtypes.h" 
#else
    #include "rtwtypes.h"
#endif

#define MW_REPORT_ERROR(msg)                    fprintf(stderr, msg); 
#define MW_REPORT_ERROR_ARGS1(msg, arg1) fprintf(stderr, msg, arg1); 
#define MW_REPORT_ERROR_ARGS2(msg, arg1, arg2) fprintf(stderr, msg, arg1, arg2); 
#define MW_REPORT_ERROR_ARGS3(msg, arg1, arg2, arg3) fprintf(stderr, msg, arg1, arg2, arg3); 

struct webCamResolution
{
	char resolution[32];
	int imWidth;
	int imHeight;
};

struct webCam
{
    char Name[150];
    char Address[150];
    struct webCamResolution wcr[16];
};
struct webCam wc[10];
static int numberOfConnetions = 0, numSupportedRes[10];

void MW_trim(char* str);
void getCameraList();
int getCameraAddrIndex(char* cameraName);
void getCameraResolution();
int validateResolution(int camIndex, int imwidth, int imheight);
int MW_convertstring2num(char* numString);
void MW_stringSplit(char* OrignalStr, char* search, char* str1, char* str2);
#endif /* _MW_COMMON_H_ */
