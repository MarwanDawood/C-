/* Copyright 2010-2018 The MathWorks, Inc. */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>
#include <getopt.h>             /* getopt_long() */
#include <fcntl.h>              /* low-level i/o */
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <asm/types.h>          /* for videodev2.h */
#include <linux/videodev2.h>
#include "v4l2_cam.h"
#include "availableWebcam.h"

#define WEBCAM_DEV_FILE "/dev/video"

static MW_videoInfo_t hVideoDev[MW_NUM_MAX_VIDEO_DEVICES];

/* Forward declarations */
//static __u32 mwPixFmt2V4L2(__u32 mwPixelFormat);
static void initMmap(MW_videoInfo_t *h);
static void stopCapture(MW_videoInfo_t *h);
static void startCapture(MW_videoInfo_t *h);

static void destroyDevice(MW_videoInfo_t *h);
static void terminateDevice(MW_videoInfo_t *h);
void videoCaptureCleanup(void);

/* Prevent compiler errors on older version of videodev2.h*/
#if !defined(V4L2_PIX_FMT_Y16)
#define V4L2_PIX_FMT_Y16     v4l2_fourcc('Y','1','6',' ') /* 16  Grey-scale     */
#endif
#if !defined(V4L2_PIX_FMT_YUV444)
#define V4L2_PIX_FMT_YUV444  v4l2_fourcc('Y','4','4','4') /* 16  xxxxyyyy uuuuvvvv */
#endif
#if !defined(V4L2_PIX_FMT_YUV555)
#define V4L2_PIX_FMT_YUV555  v4l2_fourcc('Y','U','V','O') /* 16  YUV-5-5-5     */
#endif
#if !defined(V4L2_PIX_FMT_YUV565)
#define V4L2_PIX_FMT_YUV565  v4l2_fourcc('Y','U','V','P') /* 16  YUV-5-6-5     */
#endif
#if !defined(V4L2_PIX_FMT_YUV32)
#define V4L2_PIX_FMT_YUV32   v4l2_fourcc('Y','U','V','4') /* 32  YUV-8-8-8-8   */
#endif


/* Data structures */
typedef struct {
    int CAP_ID;
    const char *capName;
} MW_capStruct_t;

#ifdef _MW_V4L2_DEBUG_
/* Global data */
static MW_capStruct_t deviceCaps[] =
{
    {V4L2_CAP_VIDEO_CAPTURE,        "video capture"},
    {V4L2_CAP_VIDEO_OUTPUT,         "video output"},
    {V4L2_CAP_VIDEO_OVERLAY,        "video overlay"},
    {V4L2_CAP_VBI_CAPTURE,          "VBI capture"},
    {V4L2_CAP_VBI_OUTPUT,           "VBI output"},
    {V4L2_CAP_SLICED_VBI_CAPTURE,   "sliced VBI capture"},
    {V4L2_CAP_SLICED_VBI_OUTPUT,    "sliced VBI output"},
    {V4L2_CAP_RDS_CAPTURE,          "RDS data capture"},
    {V4L2_CAP_VIDEO_OUTPUT_OVERLAY, "video output overlay"},
    {V4L2_CAP_TUNER,                "tuner"},
    {V4L2_CAP_AUDIO,                "audio"},
    {V4L2_CAP_RADIO,                "radio"},
    {V4L2_CAP_READWRITE,            "read() / write()"},
    {V4L2_CAP_ASYNCIO,              "async I/O"},
    {V4L2_CAP_STREAMING,            "streaming I/O"},
};
#endif
static char strBuf[ERR_MSG_BUF_SIZE];

/* Wrapper for IOCTL calls */
static int xioctl(int fd, int request, void * arg)
{
    int res;
    
    do
        res = ioctl (fd, request, arg);
    while ((res == -1) && (errno == EINTR));
    
    return res;
}


/* Translate a V4L2 fourcc to pixel format name */
static const char *pixFmt2Name(int pixelFormat)
{
    static char unknown[24];
    
    switch (pixelFormat) {
        case V4L2_PIX_FMT_RGB332:
            return "RGB332";
        case V4L2_PIX_FMT_RGB555:
            return "RGB555";
        case V4L2_PIX_FMT_RGB565:
            return "RGB565";
        case V4L2_PIX_FMT_RGB555X:
            return "RGB555X";
        case V4L2_PIX_FMT_RGB565X:
            return "RGB565X";
        case V4L2_PIX_FMT_BGR24:
            return "BGR24";
        case V4L2_PIX_FMT_RGB24:
            return "RGB24";
        case V4L2_PIX_FMT_BGR32:
            return "BGR32";
        case V4L2_PIX_FMT_RGB32:
            return "RGB32";
        case V4L2_PIX_FMT_GREY:
            return "GREY";
        case V4L2_PIX_FMT_YVU410:
            return "YVU410";
        case V4L2_PIX_FMT_YVU420:
            return "YVU420";
        case V4L2_PIX_FMT_YUYV:
            return "YUYV";
        case V4L2_PIX_FMT_UYVY:
            return "UYVY";
        case V4L2_PIX_FMT_YUV422P:
            return "YUV422P";
        case V4L2_PIX_FMT_YUV411P:
            return "YUV411P";
        case V4L2_PIX_FMT_Y41P:
            return "Y41P";
        case V4L2_PIX_FMT_NV12:
            return "NV12";
        case V4L2_PIX_FMT_NV21:
            return "NV21";
        case V4L2_PIX_FMT_YUV410:
            return "YUV410";
        case V4L2_PIX_FMT_YUV420:
            return "YUV420";
        case V4L2_PIX_FMT_YYUV:
            return "YYUV";
        case V4L2_PIX_FMT_HI240:
            return "HI240";
        case V4L2_PIX_FMT_WNVA:
            return "WNVA";
        case V4L2_PIX_FMT_MJPEG:
            return "MJPEG";
        case V4L2_PIX_FMT_MPEG:
            return "MPEG";
    }
    sprintf(unknown, "unknown (0x%x)", pixelFormat);
    
    return unknown;
}


#ifdef _MW_V4L2_DEBUG_
/* List device capabilities */
static void listDeviceCapabilities(MW_videoInfo_t *h, struct v4l2_capability *cap)
{
    unsigned int i;
    
    /* List available device capabilities */
    printf("Device capabilities for %s:\n", h->devName);
    for (i = 0; i < sizeof(deviceCaps)/sizeof(MW_capStruct_t); i++) {
        if (deviceCaps[i].CAP_ID & cap->capabilities) {
            printf("%d. %s is supported\n",
                    i, deviceCaps[i].capName);
        }
    }
}

/* Return a descriptive text for color space given v4l2_colorspace enum */
static const char *colorSpace2Name(enum v4l2_colorspace colorSpace)
{
    static char unknown[24];
    
    switch (colorSpace) {
        case V4L2_COLORSPACE_SMPTE170M:
            return "NTSC/PAL (SMPTE 170M, ITU BT.601)";
        case V4L2_COLORSPACE_SMPTE240M:
            return "1125-Line (US) HDTV (SMPTE 240M)";
        case V4L2_COLORSPACE_REC709:
            return "HDTV and modern devices (ITU BT.709)";
        case V4L2_COLORSPACE_BT878:
            return "Broken Bt878 extents[b], ITU BT.601";
        case V4L2_COLORSPACE_470_SYSTEM_M:
            return "M/NTSC[c] according to ITU BT.470, ITU BT.601";
        case V4L2_COLORSPACE_470_SYSTEM_BG:
            return "625-line PAL and SECAM (ITU BT.470, ITU BT.601)";
        case V4L2_COLORSPACE_JPEG:
            return "JPEG YCbCr (JFIF, ITU BT.601)";
        case V4L2_COLORSPACE_SRGB:
            return "sRGB";
    }
    sprintf(unknown, "unknown (0x%x)", colorSpace);
    
    return unknown;
}

/* Print out pixel format */
static void printPixFormat(struct v4l2_pix_format *pixFmt)
{
    printf("\nImage format:\n");
    printf("=============\n");
    printf("[width, height] = [%d, %d]\n", pixFmt->width, pixFmt->height);
    printf("pixelformat = %s\n", pixFmt2Name(pixFmt->pixelformat));
    printf("Field: %d\n", pixFmt->field);
    printf("Bytes per line: %d\n", pixFmt->bytesperline);
    printf("Buffer size = %d\n", pixFmt->sizeimage);
    printf("Color space = %s\n", colorSpace2Name(pixFmt->colorspace));
}

/* Print crop capabilities */
static void printCropCap(struct v4l2_cropcap *cropCap)
{
    printf("\nCropping capabilities:\n");
    printf("======================\n");
    printf("Bounds: [%d, %d, %d, %d]\n",
            cropCap->bounds.left, cropCap->bounds.top,
            cropCap->bounds.width, cropCap->bounds.height);
    printf("Default rectangle: [%d, %d, %d, %d]\n",
            cropCap->defrect.left, cropCap->defrect.top,
            cropCap->defrect.width, cropCap->defrect.height);
    printf("Pixel aspect ratio:%d/%d\n",
            cropCap->pixelaspect.numerator, cropCap->pixelaspect.denominator);
}
#endif

/* Print format description */
static int printFormatDescription(struct v4l2_fmtdesc *fmtDesc, char *buf, size_t size)
{
    int ret;
    
    if (size > 0) {
        ret = sprintf(buf, "%d. %s (%s)\n", (fmtDesc->index + 1),
                pixFmt2Name(fmtDesc->pixelformat), fmtDesc->description);
    }
    
    return ret;
}

/* Open V4L2 device file */
static int openV4L2Device(MW_videoInfo_t *h)
{
    struct stat st;
    
    if (stat((const char *)h->devName, &st) == -1) {
        MW_ERROR_EXIT3("Error: There is no video device called '%s'. System returned (%d): %s. Make sure that you specified the correct video device name.\n",
                h->devName, errno, strerror(errno));
        return -1;
    }
    if (!S_ISCHR(st.st_mode)) {
        MW_ERROR_EXIT1("Error: %s is not a video capture device. Make sure that you specified the correct video device name.\n", h->devName);
        return -1;
    }
    
    /* Open device */
    h->fd = open((const char *)h->devName, O_RDWR, 0);
    if (h->fd == -1) {
        MW_ERROR_EXIT3("Error: Cannot open video device file %s: System returned (%d): %s. "
                "Make sure that you have read / write permissions to access the video device file and that no other application is using the video device.\n",
                h->devName, errno, strerror(errno));
        return -1;
    }
    
    return 0;
}

static void setFrameRate(MW_videoInfo_t *h)
{
    struct v4l2_streamparm streamparm;
    int ret;
    
    streamparm.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    ret = xioctl(h->fd, VIDIOC_G_PARM, &streamparm);
    if (ret < 0) {
#ifdef _MW_V4L2_DEBUG_
        printf("VIDIOC_G_PARM: Failed to get stream parameters\n");
#endif
        return;
    }
    
    if (!(streamparm.parm.capture.capability & V4L2_CAP_TIMEPERFRAME)) {
#ifdef _MW_V4L2_DEBUG_
        printf("V4L2_CAP_TIMEPERFRAME: No frame rate capability\n");
#endif
        return;
    }
    streamparm.parm.capture.timeperframe.numerator   = 1;
    streamparm.parm.capture.timeperframe.denominator = h->frameRate;
    ret = xioctl(h->fd, VIDIOC_S_PARM, &streamparm);
    if (ret < 0) {
#ifdef _MW_V4L2_DEBUG_
        printf("VIDIOC_S_PARM: Unable to set required frame rate\n");
#endif
        return;
    }
    
#ifdef _MW_V4L2_DEBUG_
    /* Get frame rate to confirm */
    ret = xioctl(h->fd, VIDIOC_G_PARM, &streamparm);
    if (ret < 0) {
        return;
    }
    printf("Frame rate: %d/%d\n",
            streamparm.parm.capture.timeperframe.denominator,
            streamparm.parm.capture.timeperframe.numerator);
#endif
}

/* Init device for video capture */
static int initV4L2Device(MW_videoInfo_t *h)
{
    struct v4l2_capability cap;
    struct v4l2_format fmt;
#ifdef _V4L2_ENABLE_VIDEO_CROP_
    struct v4l2_cropcap cropcap;
    struct v4l2_crop crop;
#endif
    
    /* Query device capabilities */
    memset(&cap, 0, sizeof(cap));
    if (xioctl(h->fd, VIDIOC_QUERYCAP, &cap) == -1) {
        if (EINVAL == errno) {
            MW_ERROR_EXIT1("Error: %s is not a V4L2 video capture device.\n", h->devName);
            return -1;
        }
        else {
            MW_ERROR_EXIT3("Error: Cannot query '%s': System returned (%d): %s.\n",
                    h->devName, errno, strerror(errno));
            return -1;
        }
    }
    
    /* Check if device supports video capture */
    if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
#ifdef _MW_V4L2_DEBUG_
        listDeviceCapabilities(h, &cap);
#endif
        MW_ERROR_EXIT1("Error: %s does not support video capture.\n",
                h->devName);
        return -1;
    }
    
    /* Check that device has streaming or read/write capability */
    if (cap.capabilities & V4L2_CAP_STREAMING) {
        h->ioMethod = IO_METHOD_MMAP;
    }
    else {
        MW_ERROR_EXIT1("Error: %s does not support STREAMING mode for video capture.\n", h->devName);
        return -1;
    }
    
#ifdef _V4L2_ENABLE_VIDEO_CROP_
    /* Get cropping parameters */
    memset(&cropcap, 0, sizeof(cropcap));
    cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if (xioctl(h->fd, VIDIOC_CROPCAP, &cropcap) == -1) {
        MW_ERROR_EXIT3("Error: %s does not support crop capability: System returned (%d): %s.\n",
                h->devName, errno, strerror(errno));
        return -1;
    }
#ifdef _MW_V4L2_DEBUG_
    printCropCap(&cropcap);
#endif
    
    /* Set region of interest */
    memset(&crop, 0, sizeof(crop));
    crop.type     = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    crop.c.top    = h->roi.top;
    crop.c.left   = h->roi.left;
    crop.c.width  = h->roi.width;
    crop.c.height = h->roi.height;
    if (xioctl(h->fd, VIDIOC_S_CROP, &crop) == 0) {
        /* Read back */
        if (xioctl(h->fd, VIDIOC_G_CROP, &crop) == -1) {
            MW_ERROR_EXIT3("Error: %s does not support GET crop capability IOCTL. System returned (%d): %s. .\n",
                    h->devName, errno, strerror(errno));
            return -1;
        }
        
        /* Ensure that the requested cropping area is set  */
        /* fixme */
#ifdef _MW_V4L2_DEBUG_
        printf("Region of interest set to: [%d, %d, %d, %d].\n",
                crop.c.top, crop.c.left, crop.c.width, crop.c.height);
#endif
    }
    else {
        /*EINVAL: Device does not support cropping */
#ifdef _MW_V4L2_DEBUG_
        printf("Error: %s does not support SET crop capability IOCTL. System returned (%d): %s.\n",
                h->devName, errno, strerror(errno));
#endif
    }
#endif /* _V4L2_ENABLE_VIDEO_CROP_ */
    
    /* Set data format and images size */
    memset(&fmt, 0, sizeof(fmt));
    fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if (xioctl(h->fd, VIDIOC_G_FMT, &fmt) == -1) {
        MW_ERROR_EXIT3("Error: Cannot get current video format of %s: System returned (%d): %s.\n",
                h->devName, errno, strerror(errno));
        return -1;
    }
#ifdef _MW_V4L2_DEBUG_
    printPixFormat(&fmt.fmt.pix);
#endif /* _V4L2_ENABLE_VIDEO_CROP_ */
    
    /* Try selected format */
    fmt.fmt.pix.width       = h->imFormat.width;
    fmt.fmt.pix.height      = h->imFormat.height;
    fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV; /* mwPixFmt2V4L2(h->imFormat.pixelFormat); */
    if (xioctl(h->fd, VIDIOC_S_FMT, &fmt) == -1) {
        switch (errno) {
            case EBUSY:
                MW_ERROR_EXIT3("Error: %s is not available for I/O. System returned (%d): %s."
                        "Make sure that device is not used by another application.\n",
                        h->devName, errno, strerror(errno));
                return -1;
                break;
            case EINVAL:
            {   struct v4l2_fmtdesc fmtDesc;
                char *errMsgPtr = &strBuf[0];
                size_t size = ERR_MSG_BUF_SIZE;
                size_t ret;
                
                /* Print out format description */
                fmtDesc.type  = V4L2_BUF_TYPE_VIDEO_CAPTURE;
                fmtDesc.index = 0;
                while ((xioctl(h->fd, VIDIOC_ENUM_FMT, &fmtDesc) != -1) && (size > 0)) {
                    ret = printFormatDescription(&fmtDesc, errMsgPtr, size);
                    errMsgPtr += ret;  /* Tag on \0 at the end */
                    size      -= ret;
                    fmtDesc.index += 1;
                }
                MW_ERROR_EXIT2("Error: %s pixel format is not supported by the device. "
                        "Pixel formats supported by device: \n%s\n",
                        pixFmt2Name(fmt.fmt.pix.pixelformat), strBuf);
                return -1;
            }
            break;
            default:
                MW_ERROR_EXIT3("Error: VIDIOC_S_FMT call failed for device %s: %d, %s.",
                        h->devName, errno, strerror(errno));
                return -1;
                break;
        }
        
    }
    
    /* Note VIDIOC_S_FMT may change width and height. */
    if ((h->imFormat.width != fmt.fmt.pix.width) ||
            (h->imFormat.height != fmt.fmt.pix.height)) {
        MW_ERROR_EXIT4("Error: Image size of [%d, %d] is not supported. "
                "The closest image size supported by the device is [%d, %d].",
                h->imFormat.width, h->imFormat.height,
                fmt.fmt.pix.width, fmt.fmt.pix.height);
        return -1;
    }
    
    /* Set frame rate */
    setFrameRate(h);
    
    /* Initialize device for I/O */
    initMmap(h);
    
    /* Start data capture */
    startCapture(h);
    
    return 0;
}

/* Stop video capture */
static void stopCapture(MW_videoInfo_t *h)
{
    enum v4l2_buf_type type;
    
    switch (h->ioMethod) {
        case IO_METHOD_READ:
            /* Nothing to do. */
            break;
        case IO_METHOD_MMAP:
        case IO_METHOD_USERPTR:
            type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
            if (xioctl(h->fd, VIDIOC_STREAMOFF, &type) == -1) {
                MW_ERROR_EXIT("Error: Cannot stop video capture.");
            }
            h->v4l2CaptureStarted = 0;
            break;
    }
}

/* Start capturing video frames */
static void startCapture(MW_videoInfo_t *h)
{
    unsigned int i;
    enum v4l2_buf_type type;
    
    switch (h->ioMethod) {
        case IO_METHOD_USERPTR:
        case IO_METHOD_READ:
            /* Nothing to do. */
            break;
        case IO_METHOD_MMAP:
            for (i = 0; i < h->v4l2BufCount; ++i) {
                struct v4l2_buffer buf;
                
                memset(&buf, 0, sizeof(buf));
                buf.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
                buf.memory = V4L2_MEMORY_MMAP;
                buf.index  = i;
                if (xioctl(h->fd, VIDIOC_QBUF, &buf) == -1) {
                    MW_ERROR_EXIT2("Error queuing video buffer. System returned (%d): %s.", errno, strerror(errno));
                }
            }
            
            /* Start video stream */
            type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
            if (xioctl(h->fd, VIDIOC_STREAMON, &type) == -1) {
                MW_ERROR_EXIT2("Error starting capture. System returned (%d): %s.", errno, strerror(errno));
            }
            h->v4l2CaptureStarted = 1;
            break;
    }
}


/* Initialize MMAP operation */
static void initMmap(MW_videoInfo_t *h)
{
    struct v4l2_requestbuffers req;
    unsigned int i;
    
    /* Request MMAP buffers */
    memset(&req, 0, sizeof(req));
    req.count  = MW_NUM_V4L2_BUFFERS;
    req.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    req.memory = V4L2_MEMORY_MMAP;
    if (xioctl(h->fd, VIDIOC_REQBUFS, &req) == -1) {
        if (errno == EINVAL) {
            MW_ERROR_EXIT1("Error: %s does not support memory mapping.\n", h->devName);
        }
        else {
            MW_ERROR_EXIT("Error requesting MMAP buffers.");
        }
    }
#ifdef _MW_V4L2_DEBUG_
    printf("Number of MMAP buffers = %d\n", req.count);
#endif
    
    /* Check number of buffers */
    if (req.count < 2) {
        MW_ERROR_EXIT1("Error: Insufficient buffer memory on %s\n", h->devName);
    }
    h->v4l2BufCount = req.count; /* Record buffer count for feature reference */
    
    /* Queue all buffer to device */
    for (i = 0; i < h->v4l2BufCount; i++) {
        struct v4l2_buffer buf;
        
        memset(&buf, 0, sizeof(buf));
        buf.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        buf.memory = V4L2_MEMORY_MMAP;
        buf.index  = i;
        if (xioctl(h->fd, VIDIOC_QUERYBUF, &buf) == -1) {
            MW_ERROR_EXIT("Error querying video buffer.");
        }
        h->frm[i].start  = mmap(NULL, buf.length, PROT_READ | PROT_WRITE,
                MAP_SHARED, h->fd, buf.m.offset);
        if (h->frm[i].start == MAP_FAILED) {
            MW_ERROR_EXIT("Error: mmap operation failed.");
        }
        h->frm[i].length = buf.length;
    }
}

/* Convert from YUYV (interleaved) format to YUV planar */
static void yuyv2yuv(uint8_T *yuyv, uint8_T *y, uint8_T *u, uint8_T *v, uint32_T width, uint32_T height)
{
    uint32_T i;
    
    for (i = 0; i < (height * (width >> 1)); i++) {
        *y++ = *yuyv++;
        *u++ = *yuyv++;
        *y++ = *yuyv++;
        *v++ = *yuyv++;
    }
}

#define RCr    358  /* (1.402 * 255) */
#define GCb    88   /* (0.34414 * 255) */
#define GCr    182  /* (0.71414 * 255) */
#define BCb    452  /* (1.772 * 255) */
static uint8_T clamp(int16_T x)
{
    /*(x > 255) ? 255 : ((x < 0) ? 0 : x);*/
    if (x > 255) {
        x = 255;
    } else if (x < 0) {
        x = 0;
    }
    
    return (x);
}
/* Convert from YUYV (interleaved) format to YUV planar */
static void yuyv2rgb(uint8_T *yuyv, uint8_T *r, uint8_T *g, uint8_T *b, uint32_T width, uint32_T height)
{
    uint32_T i;
    int16_T Y0, Y1, Cb, Cr;
    
    for (i = 0; i < (height * (width >> 1)); i++) {
        /* Y0 U0 Y1 V0 Y2 U1 Y3 V1 */
        /* MSDN
         * C = Y - 16
         * D = U - 128
         * E = V - 128
         * R = clip(( 298 * C           + 409 * E + 128) >> 8)
         * G = clip(( 298 * C - 100 * D - 208 * E + 128) >> 8)
         * B = clip(( 298 * C + 516 * D           + 128) >> 8)
         *
         * Formula used here is:
         * R = Y + 1.402 (Cr-128)
         * G = Y - 0.34414 (Cb-128) - 0.71414 (Cr-128)
         * B = Y + 1.772 (Cb-128)
         */
        Y0 = *yuyv++;
        Cb = *yuyv++ - 128;
        Y1 = *yuyv++;
        Cr = *yuyv++ - 128;
        
        *r++ = clamp(Y0 + ((RCr * Cr) >> 8));
        *g++ = clamp(Y0 - ((GCb * Cb + GCr * Cr) >> 8));
        *b++ = clamp(Y0 + ((BCb * Cb) >> 8));
        *r++ = clamp(Y1 + ((RCr * Cr) >> 8));
        *g++ = clamp(Y1 - ((GCb * Cb + GCr * Cr) >> 8));
        *b++ = clamp(Y1 + ((BCb * Cb) >> 8));
    }
}

/* Reads a single video frame from a V4L2 device */
static void readV4L2Frame(MW_videoInfo_t *h, uint8_T *pln0, uint8_T *pln1, uint8_T *pln2)
{
    struct v4l2_buffer buf;
    
    switch (h->ioMethod) {
        case IO_METHOD_USERPTR:
        case IO_METHOD_READ:
            /* Nothing to do. */
            break;
        case IO_METHOD_MMAP:
            /* Request a new buffer */
            memset(&buf, 0, sizeof(buf));
            buf.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
            buf.memory = V4L2_MEMORY_MMAP;
            if (xioctl(h->fd, VIDIOC_DQBUF, &buf) == -1) {
                switch (errno) {
                    case EAGAIN:
                    case EIO:
                    default:
                        fprintf(stderr, "Error: Failure reading image buffer. System returned (%d): %s.\n",
                                errno, strerror(errno));
                }
            }
            if (buf.index >= h->v4l2BufCount) {
                MW_ERROR_EXIT("Error: Frame buffer index out of range.");
            }
            
            /* Copy acquired frame to output signal line */
            if (h->pixelOrder == PIXEL_ORDER_PLANAR) {
                switch(h->imFormat.pixelFormat) {
                    case MW_YCBCR422:
                        yuyv2yuv((uint8_T *)h->frm[buf.index].start, pln0, pln1, pln2,
                                h->imFormat.width, h->imFormat.height);
                        break;
                    case MW_RGB:
                        yuyv2rgb((uint8_T *)h->frm[buf.index].start, pln0, pln1, pln2,
                                h->imFormat.width, h->imFormat.height);
                        break;
                }
            }
            else {
                /* Note pln1 and pln2 are not updated */
                memcpy(pln0, h->frm[buf.index].start, (h->imFormat.width) * (h->imFormat.height));
            }
            
            /* Return buffer back to device */
            if (xioctl(h->fd, VIDIOC_QBUF, &buf) == -1) {
                fprintf(stderr, "Error: Failure returning video buffer to device %s. System returned (%d): %s.\n",
                        h->devName, errno, strerror(errno));
            }
            break;
    }
}

/* Close V4L2 device */
static void closeV4L2Device(MW_videoInfo_t *h)
{
    unsigned int i;
    
    if ( (h != NULL) && (h->fd > 0)) {
        /* Stop streaming */
        if (h->v4l2CaptureStarted == 1) {
            stopCapture(h);
        }
        
        /* Unmap / free buffers allocated for capture */
        switch (h->ioMethod) {
            case IO_METHOD_USERPTR:
            case IO_METHOD_READ:
                /* Nothing to do. */
                break;
            case IO_METHOD_MMAP:
                for (i = 0; i < h->v4l2BufCount; ++i) {
                    if ((h->frm[i].length > 0) &&
                            (munmap(h->frm[i].start, h->frm[i].length) == -1)) {
                        printf("Warning: munmap call failed. System returned (%d): %s.",
                                errno, strerror(errno));
                    }
                }
                break;
        }
        
        /* Close device file */
        if (close(h->fd) == -1) {
            printf("Warning: cannot close device file %s. System returned (%d): %s.",
                    h->devName, errno, strerror(errno));
        }
        h->fd = -1;
    }
}

////////////////////////
/* Device termination function */
static void terminateDevice(MW_videoInfo_t *h)
{
    /* De-allocate buffers and close device file */
    if (h != NULL) {
        closeV4L2Device(h);
        
        if(h->devName) {
            free(h->devName);
        }
        destroyDevice(h);
    }
}

/* Clean-up routine that gets executed */
/* when MW_ERROR_EXIT? macro is called */
void videoCaptureCleanup(void) {
    uint32_T i;
    
    for (i = 0; i < MW_NUM_MAX_VIDEO_DEVICES; i++) {
#ifdef _MW_V4L2_DEBUG_LVL2_
        printf("Cleaning up resources for %s. PID = %d\n", hVideoDev[i].devName, getpid());
#endif
        terminateDevice(&hVideoDev[i]);
    }
}

/* Return a handle to device instance given device names */
static MW_videoInfo_t *getDeviceHandle(const char *devName)
{
    int devIndx = -1;
    unsigned int i;
    
    /* We have to search all entries since blocks can be called out of order */
    for (i = 0; i < MW_NUM_MAX_VIDEO_DEVICES; i++) {
        if ((hVideoDev[i].fd != 0) && (strcmp((const char *)hVideoDev[i].devName, (const char *)devName) == 0)) {
            devIndx = i;
            break;
        }
    }
    
    if (devIndx == -1) {
        return NULL;
    }
    else {
        return(&hVideoDev[i]);
    }
}

/* Return number of bytes required to store a single horizontal line */
/* of image given format */
uint32_T getBytesPerLine(uint32_T pixelFormat, uint32_T width)
{
    uint32_T bytesPerLine;
    
    switch (pixelFormat) {
        case MW_YCBCR422:
            bytesPerLine = 2 * width;
            break;
        case MW_RGB:
            bytesPerLine = 3 * width;
            break;
        default:
            bytesPerLine = 0;
            break;
    }
    
    return bytesPerLine;
}

/* Create a new device instance */
static MW_videoInfo_t *newDevice(void)
{
    MW_videoInfo_t *h;
    uint32_T i;
    
    /* Find an unused video device */
    h = NULL;
    for (i = 0; i < MW_NUM_MAX_VIDEO_DEVICES; i++) {
        if (hVideoDev[i].fd == 0) {
            h = &hVideoDev[i];
            memset(h, 0, sizeof(MW_videoInfo_t));
            h->fd = -1; /* -1 indicates device is not opened yet  */
            break;
        }
    }
    if (h == NULL) {
        MW_ERROR_EXIT1("Too many video devices. Number of video devices must be smaller than %d\n",
                MW_NUM_MAX_VIDEO_DEVICES);
    }
    
    return h;
}

/* Destroy a device instance */
static void destroyDevice(MW_videoInfo_t *h)
{
    if (h != NULL) {
        memset(h, 0, sizeof(MW_videoInfo_t));
    }
}


/* Check device parameters for validity */
/* 1. Each video device must use a unique device name */
/* 2. Live video capture is not supported in Windows  */
static void checkDeviceParams(const char *devName, uint32_T pixelFormat, uint32_T imWidth)
{
    MW_videoInfo_t *h;
    
    /* Check if we have a device instance with the same name */
    h = getDeviceHandle(devName);
    if (h != NULL) {
        MW_ERROR_EXIT1("Each Video Capture block must use a unique Video device name. "
                "Video device name %s is already used.", devName);
    }
    
    /* Check that pixel format is in range */
    if ((pixelFormat != MW_YCBCR422) && (pixelFormat != MW_RGB)) {
        MW_ERROR_EXIT1("Unknown Pixel format %d.", pixelFormat);
    }
    
    /* Image width must be even in YCbCr 4:2:2 mode */
    if ((pixelFormat == MW_YCBCR422) && ((imWidth & 0x1) != 0)) {
        MW_ERROR_EXIT1("%s: Image width must be even when Pixel order is YCbCr 4:2:2. "
                "This format has half as many chroma samples as that of luminance plane.",  devName);
    }
}

/* Initialization routine for video capture module */
int EXT_webcamInit
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
        )
{
    
    MW_videoInfo_t *h;
    unsigned int i;
    int ret = 0;
    char devName[50];
    uint32_T imageWidth, imageHeight;
    if (isMLTGT != 0)
    {
        /* MATLAB Targeting codegen*/
        strcpy(devName,wc[id].Address);
    }else{
        snprintf(devName, sizeof(devName), WEBCAM_DEV_FILE "%d", id);
    }
    
    /* Check device parameters for validity */
    checkDeviceParams(devName, pixelFormat, imWidth);
    
    /* Create a new video device instance */
    h                       = newDevice();
    h->devName = (uint8_T*)malloc(strlen((char*)devName)+1);
    if (h->devName == NULL) {
        MW_ERROR_EXIT("Memory allocation error.");
        return -1;
    }
    strcpy((char*)h->devName, (char*)devName);
    h->roi.top              = roiTop;         /* Stores cropping rectangle (ROI from block mask) */
    h->roi.left             = roiLeft;
    h->roi.width            = roiWidth;
    h->roi.height           = roiHeight;
    h->imFormat.width       = imWidth;        /* Capture width */
    h->imFormat.height      = imHeight;       /* Capture height */
    h->imFormat.pln12Width  = 0;              /* Used for chroma sub-sampled formats */
    h->imFormat.pixelFormat = pixelFormat;    /* Stores image size and pixel format */
    h->pixelOrder           = pixelOrder;     /* Interleave / planar selection */
    h->hRgbRefLine          = NULL;
    h->frameRate            = 1.0/sampleTime; /* Frame rate */
    h->simOutput            = simOutput;      /* Generated output in simulation */
    h->frmCount             = 0;
    h->v4l2BufCount         = 0;
    h->v4l2CaptureStarted   = 0;
    for (i = 0; i < MW_NUM_V4L2_BUFFERS; i++) {
        h->frm[i].start  = NULL;
        h->frm[i].length = 0;
    }
    
    if (openV4L2Device(h) != 0) {
        return -2;
    }
    if (initV4L2Device(h) != 0) {
        return -3;
    }
    
    return 0;
}



/* Simulink interface for video capture terminate function */
int EXT_webcamTerminate(uint8_T isMLTGT,uint8_T id)
{
    char devName[50];
    if (isMLTGT != 0)
    {
        /* MATLAB Targeting codegen*/
        strcpy(devName,wc[id].Address);
    }else{
        snprintf(devName, sizeof(devName), WEBCAM_DEV_FILE "%d", id);
    }
    
    MW_videoInfo_t *h = getDeviceHandle(devName);
    
#ifdef _MW_V4L2_DEBUG_LVL2_
    printf("\nTerminate for device %s\n", devName);
#endif
    if (h != NULL) {
        terminateDevice(h);
    }
    return 0;
}


/* Outputs an image frame */
/* In simulation mode either a synthetic image or live video (on Linux only) */
/* is output. In code generation, always outputs live video */
int EXT_webcamCapture(uint8_T isMLTGT,uint8_T id, uint8_T *pln0, uint8_T *pln1, uint8_T *pln2)
{
    char devName[50];
    
    if (isMLTGT != 0)
    {
        /* MATLAB Targeting codegen*/
        strcpy(devName,wc[id].Address);
    }else{
        snprintf(devName, sizeof(devName), WEBCAM_DEV_FILE "%d", id);
    }
    
    MW_videoInfo_t *h = getDeviceHandle(devName);
    
    readV4L2Frame(h, pln0, pln1, pln2);
    
    return 0;
}



/* LocalWords: getopt videodev xxxxyyyy uuuuvvvv YUV VBI RDS async fourcc
 * LocalWords:  dev mw BGR YVU YUYV UYVY YYUV WNVA MJPEG MPEG colorspace NTSC
 * LocalWords:  SMPTE ITU BT Bt SECAM YCb JFIF pixelformat VIDIOC PARM
 * LocalWords:  TIMEPERFRAME EINVAL im MMAP mmap MSDN pln munmap */
/*[EOF] */
