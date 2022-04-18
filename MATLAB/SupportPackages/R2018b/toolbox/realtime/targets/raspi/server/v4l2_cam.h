/* Copyright 2015-2018 The MathWorks, Inc. */
#ifndef _MW_V4L2_CAPTURE_H_
#define _MW_V4L2_CAPTURE_H_
#if defined(_RUNONTARGETHARDWARE_BUILD_) || defined(ARM_PROJECT)
#include "rtwtypes.h"
#else
#include "rpi_rtwtypes.h"
#endif

//#define _MW_V4L2_DEBUG_LVL2_  (1)
//#define _MW_V4L2_DEBUG_       (1)

enum MW_PIXEL_FORMAT {
    MW_YCBCR422 = 1,      /* Index starts at zero to match MATLAB conventions */
    MW_RGB,
    NOT_SUPPORTED, /* Not supported from down here */
};

typedef enum {
    PIXEL_ORDER_INTERLEAVED = 1, /* Index starts at zero to match MATLAB conventions */
    PIXEL_ORDER_PLANAR,
} MW_PIXEL_ORDER;

/* Code generation */
#define MW_ERROR_EXIT(msg)                    fprintf(stderr, msg); \
videoCaptureCleanup();
#define MW_ERROR_EXIT1(msg, arg1)             fprintf(stderr, msg, arg1); \
videoCaptureCleanup();
#define MW_ERROR_EXIT2(msg, arg1, arg2)       fprintf(stderr, msg, arg1, arg2); \
videoCaptureCleanup();
#define MW_ERROR_EXIT3(msg, arg1, arg2, arg3) fprintf(stderr, msg, arg1, arg2, arg3); \
videoCaptureCleanup();
#define MW_ERROR_EXIT4(msg, arg1, arg2, arg3, arg4) fprintf(stderr, msg, arg1, arg2, arg3, arg4); \
videoCaptureCleanup();
#define MW_WARNING3(msg, arg1, arg2, arg3)    fprintf(stderr, msg, arg1, arg2, arg3)

#define MW_NUM_V4L2_BUFFERS      (4)
#define MW_NUM_MAX_VIDEO_DEVICES (8)
#define MW_NUM_COLOR_PLANES      (3)
#define ERR_MSG_BUF_SIZE         (512)

typedef enum {
    IO_METHOD_READ,
    IO_METHOD_MMAP,
    IO_METHOD_USERPTR,
} MW_IO_METHOD;

typedef enum {
    SIM_OUTPUT_COLORBARS = 1,    /* Index starts at zero to match MATLAB conventions */
    SIM_OUTPUT_BLACK,
    SIM_OUTPUT_WHITE,
    SIM_OUTPUT_LIVE_VIDEO,
} MW_SIM_OUTPUT;

typedef struct {
    int32_T top;
    int32_T left;
    int32_T width;
    int32_T height;
} MW_rect_t;

typedef struct {
    uint32_T width;
    uint32_T height;
    uint32_T pln12Width;
    uint32_T pixelFormat;
} MW_imFormat_t;

typedef struct {
    void *start;
    size_t length;
} MW_frmInfo_t;

/* Structure holding device information */
typedef struct {
    int fd;                         /* handle to device */
    uint8_T *devName;                  /* i.e. "/dev/video0" */
    MW_rect_t roi;                  /* Stores cropping rectangle (ROI from block mask) */
    MW_imFormat_t imFormat;         /* Stores image size and pixel format */
    int pixelOrder;                 /* Interleave / planar selection */
    real_T frameRate;               /* 1/sampletime */
    int simOutput;                  /* Generated output in simulation */
    unsigned int frmCount;
    unsigned int v4l2BufCount;
    unsigned int v4l2CaptureStarted;
    MW_frmInfo_t frm[MW_NUM_V4L2_BUFFERS];
    uint8_T *hRgbRefLine;           /* RGB reference line for sim devices */
    MW_IO_METHOD ioMethod;          /* I/O method used */
} MW_videoInfo_t;


extern int EXT_webcamInit
(       
        uint8_T isMLTGT,        /* p1 */
        uint8_T id,             /* p2 */
        int32_T roiTop,         /* p3 */
        int32_T roiLeft,        /* p4 */
        int32_T roiWidth,       /* p5 */
        int32_T roiHeight,      /* p6 */
        uint32_T imWidth,       /* p7 */
        uint32_T imHeight,      /* p8 */
        uint32_T pixelFormat,   /* p9 */
        uint32_T pixelOrder,    /* p10 */
        uint32_T simOutput,     /* p11 */
        real_T sampleTime       /* p12 */
        );
extern int EXT_webcamCapture(uint8_T isMLTGT,uint8_T id, uint8_T *pln0, uint8_T *pln1, uint8_T *pln2);
extern int EXT_webcamTerminate(uint8_T isMLTGT,uint8_T id);
extern uint32_T getBytesPerLine(uint32_T pixelFormat, uint32_T width);

#endif /*_MW_V4L2_CAPTURE_H_*/

/* LocalWords:  dev sampletime
 */
