// Copyright 2015 The MathWorks, Inc.
#ifndef _MW_I2C_H_
#define _MW_I2C_H_
#include "common.h"
#if defined(_MATLABIO_)
#include "rpi_rtwtypes.h"
#else
#include "rtwtypes.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif
    
// Error codes
#define ERR_I2C_BASE                  (3000)
#define ERR_I2C_INIT                  (ERR_I2C_BASE)
#define ERR_I2C_READ_READ             (ERR_I2C_BASE+1)
#define ERR_I2C_WRITE_WRITE           (ERR_I2C_BASE+2)
#define ERR_I2C_READ_REGISTER_WRITE   (ERR_I2C_BASE+3)
#define ERR_I2C_READ_REGISTER_READ    (ERR_I2C_BASE+4)
#define ERR_I2C_WRITE_REGISTER_WRITE  (ERR_I2C_BASE+5)
    
// I2C function interface
int EXT_I2C_isBusAvailable(const unsigned int bus, boolean_T *available);
int EXT_I2C_init(const unsigned int bus);
int EXT_I2C_terminate(const unsigned int bus);
    
// New register read / write functions using combined I2C_RDWR ioctl
int EXT_I2C_read(const unsigned int bus, const uint8_T address, void *data, const int count);
int EXT_I2C_write(const unsigned int bus, const uint8_T address, const void *data, const int count);
int EXT_I2C_readRegister(const unsigned int bus, const uint8_T address,
            const uint8_T register, void *data, const int count);
int EXT_I2C_writeRegister(const unsigned int bus, const uint8_T address,
            const uint8_T reg, const void *data, const int count);
    
#ifdef __cplusplus
}
#endif
#endif //_MW_I2C_H_

