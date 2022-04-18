/* Copyright 2010-2012 The MathWorks, Inc. */
#include "v4l2_capture.h"

/* Functions needed for synthetic image generation */
/* for simulation */
static void closeSimDevice(MW_videoInfo_t *h);

static uint8_T colorBarTbl[8][3] = 
{
	{255, 255, 255}, /* 1. white  */
	{255, 255, 0},   /* 2. yellow */
	{0,   255, 255}, /* 3. cyan   */
	{0,   255, 0},   /* 4. green  */
	{255, 0,   255}, /* 5. magenta*/
	{255, 0,   0},   /* 6. red    */
	{0,   0,   255}, /* 7. blue   */
	{0,   0,   0},   /* 8. black  */
};

/* Return true if image format is YUV */
static uint32_T isYuvFormat(uint32_T pixelFormat)
{
    uint32_T res;

    switch (pixelFormat) {
        case MW_YCBCR422:
            res = 1;
            break;
        default:
            res = 0;
            break;
    }

    return res;
}


/* Generates a reference line for synthetic image generation in */
/* simulation */
static void genRGBLine(uint8_T *lineBuf, uint32_T width, uint32_T simOutput)
{
	switch (simOutput)
	{
	case SIM_OUTPUT_COLORBARS:
		{
			uint32_T colorBarWidth; /*8-colors*/
			uint32_T i, numRepeats; 
            int lastColorBarWidth;
			uint8_T *rPtr, *gPtr, *bPtr;

			colorBarWidth     = (width + 7) >> 3;
			numRepeats        = width / colorBarWidth;
			lastColorBarWidth = width - (numRepeats * colorBarWidth);
			if (lastColorBarWidth < 0) {
				numRepeats -= 1;
                lastColorBarWidth = width - (numRepeats * colorBarWidth);
			}
	        
			rPtr = lineBuf;
			gPtr = rPtr + (2 * width);
			bPtr = gPtr + (2 * width);
			for (i = 0; i < numRepeats; i++) {
				memset(rPtr, colorBarTbl[i][0], colorBarWidth);
				memset(gPtr, colorBarTbl[i][1], colorBarWidth);
				memset(bPtr, colorBarTbl[i][2], colorBarWidth);
				rPtr += colorBarWidth;
				gPtr += colorBarWidth;
				bPtr += colorBarWidth;
			}
			if (lastColorBarWidth > 0) {
				memset(rPtr, colorBarTbl[i][0], lastColorBarWidth);
				memset(gPtr, colorBarTbl[i][1], lastColorBarWidth);
				memset(bPtr, colorBarTbl[i][2], lastColorBarWidth);
				rPtr += lastColorBarWidth;
				gPtr += lastColorBarWidth;
				bPtr += lastColorBarWidth;
			}

			/* Generate 2nd line */
			memcpy(rPtr, lineBuf, width); 
			memcpy(gPtr, rPtr + width, width); 
			memcpy(bPtr, gPtr + width, width);
		}
		break;
	case SIM_OUTPUT_BLACK:
		memset(lineBuf, 0, width * 3 * 2);
		break;
	case SIM_OUTPUT_WHITE:
		memset(lineBuf, 0xFF, width * 3 * 2);
		break;
	}
}

/* Color space conversion from RGB to YUV (YCbCr actually) */
/* Coefficients are for MJPEG and MPEG4  */
static void rgb2yuv(uint8_T *rgbBuf, uint32_T width)
{
    uint8_T *rPtr, *gPtr, *bPtr;
	uint8_T y, u, v;
	uint32_T i;

    rPtr = rgbBuf;
    gPtr = rPtr + (2 * width);
	bPtr = gPtr + (2 * width);
	for (i = 0; i < (2 * width); i++) {
        /* JPEG / MPEG RGB to YUV */
		y = (( 66 * (*rPtr) + 129 * (*gPtr) +  25 * (*bPtr) + 128) >> 8) +  16;
        u = ((-38 * (*rPtr) -  74 * (*gPtr) + 112 * (*bPtr) + 128) >> 8) + 128;
        v = ((112 * (*rPtr) -  94 * (*gPtr) -  18 * (*bPtr) + 128) >> 8) + 128;
		*rPtr++ = y;
		*gPtr++ = u;
		*bPtr++ = v;
	}
}

/* Convert YUV planar format to YUYV */
static void yuv2yuyv(uint8_T *refBuf, uint32_T width)
{
    
	uint32_T i;
	uint8_T *y, *u, *v, *yuyv;

	/* Allocate a temporary buffer for interleaving */
	yuyv = (uint8_T *) malloc(2 * width); /* width(2y + 1u + 1v) */
	if (yuyv == NULL) {
		printf("Frame buffer memory allocation failed\n");
        exit(EXIT_FAILURE);
	}

	/* Interleave YUV samples */
	y = refBuf;
    u = y + (2 * width);
	v = u + (2 * width);
	for (i = 0; i < (width >> 1); i++) {
		*yuyv++ = *y++;
        *yuyv++ = *u++;
		*yuyv++ = *y++;
		*yuyv++ = *v++;

		/* Decimate u & v samples by two */
		u++;   
		v++;
	}

	/* Copy temporary yuyv buffer to refBuf */
	yuyv -= (2 * width);  /* Set position to the beginning of the buffer */
	memcpy(refBuf,               yuyv, (2 * width));
	memcpy(refBuf + (2 * width), yuyv, (2 * width));

	/* Free temporary buffer */
    free(yuyv);
}

/* Decimate input buffer (in place) by two */
static void decimateByTwo(uint8_T *refBuf, uint32_T width)
{
	uint32_T i;

	for (i = 0; i < (width >> 1); i++) {
		refBuf[i] = refBuf[i << 1];
	}
}

/* Convert RGB Planar to RGB24 */
static void rgb2rgb24(uint8_T *refBuf, uint32_T width)
{
	uint32_T i;
	uint8_T *r, *g, *b, *rgb24;

	/* Allocate temporary buffer for interleaving */
	rgb24 = (uint8_T *) malloc(3 * width);
	if (rgb24 == NULL) {
		MW_ERROR_EXIT("Frame buffer memory allocation failed\n");
    }

	/* Interleave RGB samples into rgb24 buffer */
	r = refBuf;
	g = r + (2 * width);
	b = g + (2 * width);
	for (i = 0; i < width; i++) {
        *rgb24++ = *r++;
		*rgb24++ = *g++;
		*rgb24++ = *b++;
	}

	/* Copy the contents of the temporary rgb24 buffer to refBuf */
	rgb24 -= (3 * width); /* Set position to the beginning of the buffer */
	memcpy(refBuf,               rgb24, 3 * width);
	memcpy(refBuf + (3 * width), rgb24, 3 * width);
    free(rgb24);
}

/* Generate simulation output */
static void genSimOutput(MW_videoInfo_t *h, uint8_T *pln0, uint8_T *pln1, uint8_T *pln2)
{
	uint32_T i;
	uint8_T *refPln0;
    uint32_T offset, offset12;
    
    offset   = ((h->frmCount) << 1) % (h->imFormat.width);
    if( h->imFormat.pixelFormat == MW_YCBCR422) {
        offset12 = offset >> 1;
    }
    else {
        offset12 = offset;
    }
	refPln0 = h->hRgbRefLine;
	if (h->pixelOrder == PIXEL_ORDER_INTERLEAVED) {
		uint32_T copySize = getBytesPerLine(h->imFormat.pixelFormat, h->imFormat.width);

		for (i = 0; i < h->imFormat.height; i++) {
			memcpy(pln0, refPln0 + offset, copySize);
			pln0 += copySize;
		}
	}
	else {
		uint8_T *refPln1, *refPln2;

		refPln1 = refPln0 + (2 * h->imFormat.width);
		refPln2 = refPln1 + (2 * h->imFormat.width); 
		for (i = 0; i < h->imFormat.height; i++) {
			memcpy(pln0, refPln0 + offset, h->imFormat.width);
			memcpy(pln1, refPln1 + offset12, h->imFormat.pln12Width);
			memcpy(pln2, refPln2 + offset12, h->imFormat.pln12Width);
			pln0 += h->imFormat.width;
			pln1 += h->imFormat.pln12Width;
			pln2 += h->imFormat.pln12Width;
		}
	}
}

/* Open simulation device */
static void openSimDevice(MW_videoInfo_t *h)
{
    /* Mark file descriptor as open */
	h->fd = 1;
}

/* Initialize simulation device */
static void initSimDevice(MW_videoInfo_t *h)
{
	/* Allocate a reference buffer to hold two lines of RGB data */
	h->hRgbRefLine = (uint8_T *) malloc(3 * (h->imFormat.width * 2));
	if (h->hRgbRefLine == NULL) {
		MW_ERROR_EXIT1("Frame buffer memory allocation failed for %s\n", h->devName);
	}

	/* Generate 2-lines of reference to be used in the final output */
	/* image construction */
    genRGBLine(h->hRgbRefLine, h->imFormat.width, h->simOutput);
	if (isYuvFormat(h->imFormat.pixelFormat)) {
        rgb2yuv(h->hRgbRefLine, h->imFormat.width);
	}

	/* Convert reference frame to output format */
	switch (h->imFormat.pixelFormat) {
		case MW_YCBCR422:
			if (h->pixelOrder == PIXEL_ORDER_INTERLEAVED) {
				yuv2yuyv(h->hRgbRefLine, h->imFormat.width);
			}
			else {
			    decimateByTwo(h->hRgbRefLine + (2 * h->imFormat.width), (2 * h->imFormat.width)); /* Subsample u */
                decimateByTwo(h->hRgbRefLine + (4 * h->imFormat.width), (2 * h->imFormat.width)); /* Subsample v */
				h->imFormat.pln12Width = (h->imFormat.width) >> 1;
			}
			break;
		case MW_RGB:
			if (h->pixelOrder == PIXEL_ORDER_INTERLEAVED) {
			    rgb2rgb24(h->hRgbRefLine, h->imFormat.width);
		    }
			else {
				h->imFormat.pln12Width = h->imFormat.width;
			}
			break;
	}
}

/* Close simulation device */
static void closeSimDevice(MW_videoInfo_t *h)
{
	if (h != NULL) {
		if (h->hRgbRefLine != NULL) {
	        free(h->hRgbRefLine);
		}
		h->fd = -1;
	}
}

/*[EOF]*/