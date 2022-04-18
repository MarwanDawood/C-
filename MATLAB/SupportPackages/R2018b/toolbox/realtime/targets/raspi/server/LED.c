// Copyright 2013-2016 The MathWorks, Inc.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include "common.h"
#include "LED.h"
#include "devices.h"


/* Local defines */
#define SYSFS_LED_DIR      "/sys/class/leds/"
#define MAX_LED_FNAME     (32)


/* Open LED device file */
static int LED_open(const unsigned int id)
{
    char buf[MAX_LED_FNAME] = SYSFS_LED_DIR;
    DEV_entry_t *dev = DEV_get(id);
    
    strcat(buf, dev->name);
    strcat(buf, "/brightness");
    dev->fd = open(buf, O_WRONLY | O_NONBLOCK);
    if (dev->fd < 0) {
        perror("LED_open:1");
        return ERR_LED_OPEN;
    }
    
    return 0;
}

/* Return resources used for LED */
static int LED_close(const unsigned int id)
{
    DEV_entry_t *dev = DEV_get(id);
    
    if (dev->fd != -1) {
        close(dev->fd);
    }
    return 0;
}

/* Configure LED trigger source */
int EXT_LED_setTrigger(const unsigned int id, const char *trigger) 
{
    char buf[MAX_LED_FNAME] = SYSFS_LED_DIR;
    ssize_t ret;
    DEV_entry_t *dev = DEV_get(id);
    int fd;
    
    /* Change trigger to "none" */
    strcat(buf, dev->name);
    strcat(buf, "/trigger");
    fd = open(buf, O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        perror("LED_configure:1");
        return ERR_LED_SET_TRIGGER_OPEN;
    }
    ret = write(fd, trigger, strlen(trigger) + 1);
    close(fd);
    if (ret < 0) {
        perror("LED_configure:2");   
        return ERR_LED_SET_TRIGGER_WRITE;
    }
    
    return 0;
}

/* Configure LED trigger source */
int EXT_LED_getTrigger(const unsigned int id, char *trigger, unsigned int readSize) 
{
    char buf[MAX_LED_FNAME] = SYSFS_LED_DIR;
    ssize_t ret;
    DEV_entry_t *dev = DEV_get(id);
    int fd;
    
    /* Change trigger to "none" */
    strcat(buf, dev->name);
    strcat(buf, "/trigger");
    fd = open(buf, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        perror("LED_getTrigger:1");
        return ERR_LED_GET_TRIGGER_OPEN;
    }
    ret = read(fd, (void *)trigger, readSize);
    close(fd);
    if (ret < 0) {
        perror("LED_getTrigger:2");   
        return ERR_LED_GET_TRIGGER_READ;
    }
    trigger[ret] = 0; 
    
    return 0;
}


/* Write value to given LED */
int EXT_LED_write(const unsigned int id, const boolean_T value)
{
    DEV_entry_t *dev;
    ssize_t ret;
    
    /* Get LED information pointer */
    if (LED_open(id) < 0) {
        perror("LED_write:1");
        return ERR_LED_WRITE_OPEN;
    }
    
    /* Now claim the LED handle and write to device file */
    dev = DEV_get(id);
    lseek(dev->fd, 0, SEEK_SET);
    if (value) {
        ret = write(dev->fd, "1", 1);
    }
    else {
        ret = write(dev->fd, "0", 1);
    }
    if (ret < 0) {
        perror("LED_write:2");
        return ERR_LED_WRITE_WRITE;
    }
    LED_close(id);
    
    return 0;
}

/* [EOF] */
