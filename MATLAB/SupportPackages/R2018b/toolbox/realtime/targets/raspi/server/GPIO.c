// Copyright 2013- 2018 The MathWorks, Inc.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <sys/stat.h>
#include "common.h"
#include "devices.h"
#include "GPIO.h"

// Local defines
#define SYSFS_GPIO_DIR          "/sys/class/gpio"
#define MAX_BUF_SIZE            (128)
#define GPIO_DIRECTION_INPUT    (0)  
#define GPIO_DIRECTION_OUTPUT   (1)
#define GPIO_DIRECTION_NA       (255)


int GPIO_isExported(const unsigned int gpio)
{
    char buf[MAX_BUF_SIZE];
    struct stat statBuf;
    
    snprintf(buf, sizeof(buf), SYSFS_GPIO_DIR  "/gpio%d", gpio);
    if (stat(buf, &statBuf) == -1) {
        return 0;
    }
    else {
        return 1;
    }
}

// Export specified GPIO pin
static int GPIO_export(const unsigned int gpio)
{
    int fd, len;
    char buf[MAX_BUF_SIZE];
    ssize_t ret;
    
    // If the pin is exported, return        
    if (GPIO_isExported(gpio)) {
        return 0;
    }
    
    // Write GPIO pin number to /sys/class/gpio/export file
    fd = open(SYSFS_GPIO_DIR "/export", O_WRONLY);
    if (fd < 0) {
        perror("GPIO_export/open");
        return -1;
    }
    len = snprintf(buf, sizeof(buf), "%d", gpio);
    ret = write(fd, buf, len);
    close(fd);
    if (ret < 0) {
        perror("GPIO_export/write");
        return -2;
    }
    
    return 0;
}

// Remove specified GPIO pin from export list
static int GPIO_unexport(const unsigned int gpio)
{
	int fd, len;
	char buf[MAX_BUF_SIZE];
    ssize_t ret;
 
	fd = open(SYSFS_GPIO_DIR "/unexport", O_WRONLY);
    if (fd < 0) {
        perror("GPIO_unexport/open");
        return -1;
    }
	len = snprintf(buf, sizeof(buf), "%d", gpio);
	ret = write(fd, buf, len);
	close(fd);
    if (ret < 0) {
        perror("GPIO_unexport/write");
        return -2;
    }
    
	return 0;
}

// Set direction of the GPIO pin
static int GPIO_setDirection(const unsigned int gpio, const unsigned int direction)
{
	int fd;
	char buf[MAX_BUF_SIZE];
    ssize_t ret;
 
	snprintf(buf, sizeof(buf), SYSFS_GPIO_DIR  "/gpio%d/direction", gpio);
 
    // Open device file
	fd = open(buf, O_WRONLY);
	if (fd < 0) {
        perror("GPIO_setDirection/open");
		return -1;
	}
 
    // Set direction
	if (direction == GPIO_DIRECTION_INPUT) {
		ret = write(fd, "in", 3);
    }
	else {
        ret = write(fd, "out", 4);
    }
	close(fd);
    
    if (ret < 0) {
        perror("GPIO_setDirection/write");
        return -2;
    }
    
	return 0;
}

// Get direction of the GPIO pin
uint8_T GPIO_readDirection(const unsigned int gpio)
{
    int fd;
    char buf[MAX_BUF_SIZE];
    ssize_t ret;

    // Open device file
    snprintf(buf, sizeof(buf), SYSFS_GPIO_DIR  "/gpio%d/direction", gpio);
    fd = open(buf, O_RDONLY);
    if (fd < 0) {
        perror("gpio/direction/open");
        return GPIO_DIRECTION_NA;
    }
    
    // Read direction
    ret = read(fd, buf, 16);
    close(fd);
    if (ret < 0) {
        perror("GPIO_readDirection/read");
        return GPIO_DIRECTION_NA;
    }
    buf[ret] = 0;
    printf("direction = %s\n", buf);
    if (strncmp(buf, "in", 2) == 0) {
        return GPIO_DIRECTION_INPUT;
    }
    else {
        return GPIO_DIRECTION_OUTPUT;
    }
}

/* Return the direction of the given digital pin */
int EXT_GPIO_getStatus(unsigned int gpio, uint8_T *pinStatus)
{
    char buf[MAX_BUF_SIZE];
    struct stat statBuf;
    
    snprintf(buf, sizeof(buf), SYSFS_GPIO_DIR  "/gpio%d/direction", gpio);
    if (stat(buf, &statBuf) == -1) {
        LOG_PRINT(stdout, "Cannot stat gpio%d\n", gpio);
        if (GPIO_export(gpio) != 0) {
            LOG_PRINT(stdout, "Cannot export gpio%d\n", gpio);
            *pinStatus = GPIO_DIRECTION_NA;
        }
        else {
            *pinStatus = GPIO_readDirection(gpio);
            GPIO_unexport(gpio);
        }
    }
    else {
        *pinStatus = GPIO_readDirection(gpio);
    }
    
    return 0;
}


// Open GPIO device
static int GPIO_open(const unsigned int gpio, const int direction)
{
	int fd;
	char buf[MAX_BUF_SIZE];

	snprintf(buf, sizeof(buf), SYSFS_GPIO_DIR "/gpio%d/value", gpio);
    if (direction == GPIO_DIRECTION_INPUT) {
        fd = open(buf, O_RDONLY | O_NONBLOCK);
    }
    else {
        fd = open(buf, O_WRONLY | O_NONBLOCK);
    }
    if (fd < 0) {
        perror("GPIO_open/open");
    }
	return fd;
}

// Close GPIO device
static void GPIO_close(int fd)
{
    int ret;
    
    ret = close(fd);
    if (ret < 0) {
        // EBADF, EINTR, EIO: In all cases, descriptor is torn down
        perror("GPIO_close:close");
    }
}

// External functions ****************************************************

// Initialize GPIO module
int EXT_GPIO_init(const unsigned int gpio, const uint8_T direction)
{
    DEV_entry_t *dev;

    // Fill in GPIO info structure for the GPIO module
    dev = DEV_get(DEV_GPIO_0 + gpio);
    if (dev->fd != -1) {
        int ret;
        GPIO_close(dev->fd);
        dev->fd = -1;
        ret = GPIO_unexport(gpio);
        if (ret != 0) {
            return ERR_GPIO_INIT_UNEXPORT;
        }
    }
    if (GPIO_export(gpio) != 0) {
        return ERR_GPIO_INIT_EXPORT;
    }
	if (GPIO_setDirection(gpio, direction) != 0) { 
        return ERR_GPIO_INIT_DIRECTION;
    }
    dev->fd = GPIO_open(gpio, direction);
    if (dev->fd < 0) {
        return ERR_GPIO_INIT_OPEN;
    }
    
    // Success
    return 0;
}

// Close GPIO module
int EXT_GPIO_terminate(const unsigned int gpio)
{
    DEV_entry_t *dev;
    
    // Get GPIO information pointer and close the GPIO file descriptor
    dev = DEV_get(DEV_GPIO_0 + gpio);
	/* close and unexport only those GPIO which are initilaized */
    if(dev->fd != -1)
    {
    GPIO_close(dev->fd);
    dev->fd = -1;
    if (GPIO_unexport(gpio) != 0) {
        return ERR_GPIO_TERMINATE_UNEXPORT;
    }
    }
    
    // Success
    return 0;
}

// Read value from given GPIO pin
int EXT_GPIO_read(const unsigned int gpio, boolean_T *value)
{
    DEV_entry_t *dev;
    char strVal;
    
    // Get device
    dev = DEV_get(DEV_GPIO_0 + gpio);
    lseek(dev->fd, 0, SEEK_SET);
    if (read(dev->fd, &strVal, 1) < 0) {
        return ERR_GPIO_READ_READ;
    }
    
    // The sysfs returns the value as a char. Convert the value to bool.
    *value = (boolean_T)(strVal - '0');
    
    // Success
    return 0;
}

// Write value to given GPIO pin
int EXT_GPIO_write(const unsigned int gpio, const boolean_T value)
{
    DEV_entry_t *dev;
    ssize_t ret;
    
    // Get device
    dev = DEV_get(DEV_GPIO_0 + gpio);
    lseek(dev->fd, 0, SEEK_SET);
    if (value) {
        ret = write(dev->fd, "1", 2);
    }
    else {
        ret = write(dev->fd, "0", 2);
    }
    if (ret < 0) {
        return ERR_GPIO_WRITE_WRITE;
    }
    
    // Success
    return 0;
}

/* [EOF] */