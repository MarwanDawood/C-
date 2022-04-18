// Copyright 2013 The MathWorks, Inc.
#ifndef _MW_SPI_H_
#define _MW_SPI_H_
#include "common.h"

// Error codes
#define ERR_SPI_BASE                (4000)
#define ERR_SPI_INIT                (ERR_SPI_BASE)
#define ERR_SPI_READ_READ           (ERR_SPI_BASE+1)
#define ERR_SPI_WRITE_WRITE         (ERR_SPI_BASE+2)
#define ERR_SPI_WRITEREAD_IOCTL     (ERR_SPI_BASE+3)

// SPI function interface
extern int EXT_SPI_init(const unsigned int channel, const uint8_T mode,
        const uint8_T bitsPerWord, const uint32_T speed);
extern int EXT_SPI_writeRead(const unsigned int channel, void *data,
        const uint8_T bitsPerWord, const uint32_T count);
extern int EXT_SPI_terminate(const unsigned int channel);

#endif //_MW_SPI_H_

