// Copyright 2013 The MathWorks, Inc.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/unistd.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <math.h>
#include "common.h"
#include "devices.h"
#include "serial.h"

// Local defines
#define MAX_BUF_SIZE            (128)
#define SECONDS_TO_NSEC         (1000000000)
    
// Open SERIAL channel
static int SERIAL_open(const char *port)
{
    int fd;
    
    // O_NDELAY: disregard DCD signal line state
    // O_NOCTTY: we don't want to be the controlling terminal
    fd = open(port, O_RDWR | O_NOCTTY | O_NDELAY);
    if (fd == -1) {
        perror("SERIAL_open/open");
    }
    
    return fd;
}

// Close SERIAL channel
static void SERIAL_close(int fd)
{
    int ret;
    
    ret = close(fd);
    if (ret < 0) {
        // EBADF, EINTR, EIO: In all cases, descriptor is torn down
        perror("SERIAL_close/close");
    }
}


// Read from serial device with a given timeout
int EXT_SERIAL_read(const uint32_T deviceNumber, void *data, uint32_T *count, const int32_T timeoutInMs)
{
    DEV_entry_t *dev;
    int ret,dataAvailable = 0;
    struct timeval timeNow;
    double blockingTimeout,startTime,currentTime,diffTime;
    
    /*Get start time*/
    gettimeofday(&timeNow,NULL);
    startTime = timeNow.tv_sec+(timeNow.tv_usec/1000000.0);
    blockingTimeout = timeoutInMs/1000.0;

    // Get device handle
    dev = DEV_get(deviceNumber);
    
    /* do..while to check requested data is available 
     * ioctl FIONREAD will fetch the bytes available to read.
     * Simple poll to the fd will return true even if 1 byte is available.
     */
    do{
        ioctl(dev->fd, FIONREAD, &dataAvailable);
        if(dataAvailable >= *count)
            break;
        usleep(1000);/*to avoid a busy loop */
        gettimeofday(&timeNow,NULL);
        currentTime = timeNow.tv_sec+(timeNow.tv_usec/1000000.0);
        diffTime = currentTime - startTime;
    }while(diffTime < blockingTimeout);
    
    if(dataAvailable >= *count){
        ret = read(dev->fd, data, *count);
        if (ret < 0) {
            perror("EXT_SERIAL_read/read");
            return ERR_SERIAL_READ_READ;
        }
        *count = ret;
    }else{
        /* Data not available, put count value as 0 */
        *count = 0;
    }
    return 0;
}

// Write to serial device
int EXT_SERIAL_write(const uint32_T deviceNumber, void *data, const uint32_T count)
{
    DEV_entry_t *dev;
    int ret;

    // Get device handle
    dev = DEV_get(deviceNumber);
    ret = write(dev->fd, data, count);
    if (ret < 0) {
        perror("EXT_SERIAL_write/write");
        return ERR_SERIAL_WRITE_WRITE;
    }
    
    return 0;
}

// Initialize serial port
// uint32(obj.BaudRate), uint32(obj.DataBits), ...
// uint32(obj.Parity), uint32(obj.StopBits), uint8(obj.Port)
int EXT_SERIAL_init(const char *port, const uint32_T baudRate,
        const uint32_T dataBits, const uint32_T parity,
        const uint32_T stopBits, uint32_T *devNo)
{
    DEV_entry_t *dev;
    struct termios options;
    speed_t optBaud;
    

    // Get device handle
    *devNo = DEV_getByName(port);
    LOG_PRINT(stdout, "INIT: devNo = %d\n", *devNo);
    if (*devNo == -1) {
        *devNo = DEV_alloc(port);
        LOG_PRINT(stdout, "ALLOC: devNo = %d\n", *devNo);
        if (*devNo == -1) {
            perror("EXT_SERIAL_init/Alloc");
            return ERR_SERIAL_INIT;
        }
    }
 
    dev = DEV_get(*devNo);
    LOG_PRINT(stdout, "INIT: dev->name = %s\n", dev->name);
    if (dev->fd < 0) {
        dev->fd = SERIAL_open(port);
        if (dev->fd < 0) {
            perror("SERIAL_init/SERIAL_open");
            return ERR_SERIAL_INIT;
        }
    }

    // Set parameters of the serial connection
    switch (baudRate)
    {
        case     50: optBaud =      B50; break;
        case     75: optBaud =     B75; break;
        case    110: optBaud =    B110; break;
        case    134: optBaud =    B134; break;
        case    150: optBaud =    B150; break;
        case    200: optBaud =    B200; break;
        case    300: optBaud =    B300; break;
        case    600: optBaud =    B600; break;
        case   1200: optBaud =   B1200; break;
        case   1800: optBaud =   B1800; break;
        case   2400: optBaud =   B2400; break;
        case   4800: optBaud =   B4800; break;
        case   9600: optBaud =   B9600; break;
        case  19200: optBaud =  B19200; break;
        case  38400: optBaud =  B38400; break;
        case  57600: optBaud =  B57600; break;
        case 115200: optBaud = B115200; break;
        case 230400: optBaud = B230400; break;
        default:
            return ERR_SERIAL_INIT;
    }
    tcgetattr(dev->fd, &options);
    // Enable the receiver and set local mode
    options.c_cflag |= (CLOCAL | CREAD);
 
    // Set baud rate
    cfsetispeed(&options, optBaud);
    cfsetospeed(&options, optBaud);
    
    // Set data bits
    options.c_cflag &= ~CSIZE;
    switch (dataBits) {
        case 5:
            options.c_cflag |= CS5;
            break;
        case 6:
            options.c_cflag |= CS6;
            break;
        case 7:
            options.c_cflag |= CS7;
            break;
        case 8:
            options.c_cflag |= CS8;
            break;
        default:
            return ERR_SERIAL_INIT;
    }
    
    /*Set input flags for raw data
     * All special processing of terminal input and output
     * characters is disabled.
     * IGNBRK,BRKINT : Ignore the effect of BREAK condition on input.
     * ICRNL,INLCR,IGNCR : Carriage return <--> New line conversion
     */
    options.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ICRNL | ISTRIP | INLCR | IGNCR | IXON);
    
    // Set parity
    switch (parity) {
        case SERIAL_PARITY_NONE:
            options.c_cflag &= ~PARENB;
            break;
        case SERIAL_PARITY_EVEN:
            options.c_cflag |= PARENB;
            options.c_cflag &= ~PARODD;
            options.c_iflag |= (INPCK | ISTRIP); // Check and strip parity bit
            break;
        case SERIAL_PARITY_ODD:
            options.c_cflag |= PARENB;
            options.c_cflag |= PARODD;
            options.c_iflag |= (INPCK | ISTRIP); // Check and strip parity bit
            break;
        default:
            return ERR_SERIAL_INIT;
    }
    
    // Set stop bits (1 or 2)
    switch (stopBits) {
        case 1:
            options.c_cflag &= ~CSTOPB;
            break;
        case 2:
            options.c_cflag |= CSTOPB;
            break;
        default:
            return ERR_SERIAL_INIT;
    }
    
    
    // Local options. Configure for RAW input
    options.c_lflag &= ~(ICANON | ISIG | ECHO | ECHONL | ECHOE | IEXTEN);
    
    // Output options: RAW output
    options.c_oflag &= ~OPOST;
    
    // Set character read options
    options.c_cc[VMIN]  = 0;
    options.c_cc[VTIME] = 100;  //10 seconds

    // Set attributes
    tcsetattr(dev->fd, TCSANOW, &options);
  
    return 0;
}

// Terminate serial port
int EXT_SERIAL_terminate(const uint32_T devNo) 
{
    DEV_entry_t *dev;
    
    // Get device handle
    dev = DEV_get(devNo);
    if (dev == NULL) {
        return ERR_SERIAL_TERMINATE;
    }
    if (dev->fd > 0) {
        SERIAL_close(dev->fd);
        dev->fd = -1;
    }
    DEV_free(devNo);
        
    return 0;
}


/* [EOF] */