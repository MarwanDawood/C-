// Copyright 2013 The MathWorks, Inc.
#ifndef _MW_SERIAL_H_
#define _MW_SERIAL_H_
#include "common.h"

// Error codes
#define ERR_SERIAL_BASE             (5000)
#define ERR_SERIAL_INIT             (ERR_SERIAL_BASE)
#define ERR_SERIAL_READ_READ        (ERR_SERIAL_BASE+1)
#define ERR_SERIAL_WRITE_WRITE      (ERR_SERIAL_BASE+2)
#define ERR_SERIAL_TERMINATE        (ERR_SERIAL_BASE+3)

#define SERIAL_PARITY_NONE          (0)
#define SERIAL_PARITY_EVEN          (1)
#define SERIAL_PARITY_ODD           (2)

// SPI function interface
extern int EXT_SERIAL_init(const char *port, const uint32_T baudRate,
        const uint32_T dataBits, const uint32_T Parity, 
        const uint32_T stopBits, uint32_T *devNo);
extern int EXT_SERIAL_terminate(const uint32_T devNo);
extern int EXT_SERIAL_write(const uint32_T devNo, void *data, const uint32_T count);
extern int EXT_SERIAL_read(const uint32_T devNo, void *data, uint32_T *count, const int32_T timeoutInMs);

#endif //_MW_SERIAL_H_

