// Copyright 2013 The MathWorks, Inc.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/spi/spidev.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "common.h"
#include "devices.h"
#include "SPI.h"

// Local defines
#define MAX_BUF_SIZE            (32)
#define SPI_BUS_AVAILABLE       (1)
#define SPI_BUS_UNAVAILABLE     (0)
#define NUM_MAX_BUSSES          (2)
#define SPI_DEV_FILE            "/dev/spidev0."

static uint32_T SPIchannelSpeed[2] = {500000, 500000};
    
// Open SPI channel
static int SPI_open(const unsigned int channel)
{
    int fd;
    char buf[MAX_BUF_SIZE];
    
    snprintf(buf, sizeof(buf), SPI_DEV_FILE "%d", channel);
    fd = open(buf, O_RDWR);
    if (fd < 0) {
        perror("SPI_open/open");
    }
    return fd;
}

// Close SPI channel
static void SPI_close(int fd)
{
    int ret;
    
    ret = close(fd);
    if (ret < 0) {
        // EBADF, EINTR, EIO: In all cases, descriptor is torn down
        perror("SPI_close/close");
    }
}

// Full duplex SPI transfer
int EXT_SPI_writeRead(const unsigned int channel, void *data, 
        const uint8_T bitsPerWord, const uint32_T count)
{
    DEV_entry_t *dev;
    int ret;
	struct spi_ioc_transfer tr;
    
    // Setup SPI transfer structure
    memset(&tr, 0, sizeof(struct spi_ioc_transfer));
    tr.tx_buf = (unsigned long)data;
    tr.rx_buf = (unsigned long)data;
    tr.len    = count;

    // Execute IOCTL call to perform a full-duplex transfer
    dev = DEV_get(DEV_SPI_0 + channel);
    ret = ioctl(dev->fd, SPI_IOC_MESSAGE(1), &tr);
    if (ret != count) {
        perror("EXT_SPI_writeRead/ioctl");
        return ERR_SPI_WRITEREAD_IOCTL;
    }

    return 0;
}

// Initialize SPI channel
int EXT_SPI_init(const unsigned int channel, const uint8_T mode,
        const uint8_T bitsPerWord, const uint32_T speed)
{
    DEV_entry_t *dev;
    int ret;
    
    // Get device handle
    dev = DEV_get(DEV_SPI_0 + channel);
    if (dev->fd < 0) {
        dev->fd = SPI_open(channel);
        if (dev->fd < 0) {
            perror("SPI_init/SPI_open");
            return ERR_SPI_INIT;
        }
    }
    
    // Set mode
    ret = ioctl(dev->fd, SPI_IOC_WR_MODE, &mode);
    if (ret < 0){
        perror("SPI_init/SPI_IOC_WR_MODE");
        return ERR_SPI_INIT;
    }
    ret = ioctl(dev->fd, SPI_IOC_RD_MODE, &mode);
    if (ret < 0) {
        perror("SPI_init/SPI_IOC_RD_MODE");
        return ERR_SPI_INIT;
    }
    
    // Set bits per word
    ret = ioctl(dev->fd, SPI_IOC_WR_BITS_PER_WORD, &bitsPerWord);
	if (ret < 0) {
        perror("SPI_init/SPI_IOC_RD_MODE");
        return ERR_SPI_INIT;
    }
	ret = ioctl(dev->fd, SPI_IOC_RD_BITS_PER_WORD, &bitsPerWord);
	if (ret < 0) {
        perror("SPI_init/SPI_IOC_RD_MODE");
        return ERR_SPI_INIT;
    }
    
    // Set maximum speed
    SPIchannelSpeed[channel] = speed;
    ret = ioctl(dev->fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
	if (ret < 0) {
        perror("SPI_init/SPI_IOC_RD_MODE");
        return ERR_SPI_INIT;
    }
	ret = ioctl(dev->fd, SPI_IOC_RD_MAX_SPEED_HZ, &speed);
	if (ret < 0) {
        perror("SPI_init/SPI_IOC_RD_MODE");
        return ERR_SPI_INIT;
    }
    
    return 0;
}

// Terminate SPI channel 
int EXT_SPI_terminate(const unsigned int channel) 
{
    DEV_entry_t *dev;
    
    // Get device handle
    dev = DEV_get(DEV_SPI_0 + channel);
    if (dev->fd > 0) {
        SPI_close(dev->fd);
        dev->fd = -1;
    }
    
    return 0;
}


/* [EOF] */