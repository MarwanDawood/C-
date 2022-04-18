/* Copyright 2012-2016 The MathWorks, Inc.*/
#include "MW_gpio.h"
#if !( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <unistd.h>
    #include <errno.h>
    #include <fcntl.h>
    #include <poll.h>

    // Local defines
    #define SYSFS_GPIO_DIR          "/sys/class/gpio"
    #define POLL_TIMEOUT            (-1) // Forever
    #define GPIO_MAX_BUF            (64)

    typedef struct {
        uint32_T pin;               // Pin number
        int fd;                     // File descriptor for the GPIO pin  
        boolean_T direction;        // Input or output
    } GPIO_info;

    int numGpio = 0;                // Number of GPIO modules used
    GPIO_info *gpioInfo = NULL;     // Structure array holding GPIO info

    // Export specified GPIO pin
    static int gpioExport(uint32_T pin)
    {
        int fd, len;
        char buf[GPIO_MAX_BUF];
        ssize_t bytesWritten;

        fd = open(SYSFS_GPIO_DIR "/export", O_WRONLY);
        if (fd < 0) {
    #ifdef _DEBUG
            perror("gpio/export");
    #endif
            return fd;
        }
        len = snprintf(buf, sizeof(buf), "%d", pin);
        bytesWritten = write(fd, buf, len);
        close(fd);

        return 0;
    }

    // Remove specified GPIO pin from export list
    static int gpioUnexport(const uint32_T pin)
    {
        int fd, len;
        char buf[GPIO_MAX_BUF];
        ssize_t bytesWritten;

        fd = open(SYSFS_GPIO_DIR "/unexport", O_WRONLY);
        if (fd < 0) {
    #ifdef _DEBUG
            perror("gpio/export");
    #endif
            return fd;
        }
        len = snprintf(buf, sizeof(buf), "%d", pin);
        bytesWritten = write(fd, buf, len);
        close(fd);

        return 0;
    }

    // Set direction of the GPIO pin
    static int gpioSetDirection(const uint32_T pin, const uint32_T direction)
    {
        int fd;
        char buf[GPIO_MAX_BUF];
        ssize_t bytesWritten;

        snprintf(buf, sizeof(buf), SYSFS_GPIO_DIR  "/gpio%d/direction", pin);

        // Open device file
        fd = open(buf, O_WRONLY);
        if (fd < 0) {
    #ifdef _DEBUG
            perror("gpio/direction");
    #endif
            return fd;
        }

        // Set direction
        if (direction == GPIO_DIRECTION_INPUT) {
            bytesWritten = write(fd, "in", 3);
        }
        else {
            bytesWritten = write(fd, "out", 4);
        }
        close(fd);

        return 0;
    }

    // Set interrupt edge
    static int gpioSetInterruptEdge(const uint32_T pin, const char *edge)
    {
        int fd;
        char buf[GPIO_MAX_BUF];
        ssize_t bytesWritten;

        snprintf(buf, sizeof(buf), SYSFS_GPIO_DIR "/gpio%d/edge", pin);

        fd = open(buf, O_WRONLY);
        if (fd < 0) {
    #ifdef _DEBUG
            perror("gpio/set-edge");
    #endif
            return fd;
        }
        bytesWritten = write(fd, edge, strlen(edge) + 1); 
        close(fd);

        return 0;
    }

    // Open GPIO device
    static int gpioOpen(const uint32_T pin, const uint32_T direction)
    {
        int fd;
        char buf[GPIO_MAX_BUF];
        ssize_t bytesWritten;

        snprintf(buf, sizeof(buf), SYSFS_GPIO_DIR "/gpio%d/value", pin);
        if (direction == GPIO_DIRECTION_INPUT) {
            fd = open(buf, O_RDONLY | O_NONBLOCK);
        }
        else {
            fd = open(buf, O_WRONLY | O_NONBLOCK);
        }
        if (fd < 0) {
    #ifdef _DEBUG
            perror("gpio/fd_open");
    #endif
        }
        return fd;
    }

    // Close GPIO device
    int gpioClose(int fd)
    {
        return close(fd);
    }

    // Return resources used for GPIO
    static void gpioExit(void)
    {
        if (gpioInfo != NULL) {
            free(gpioInfo);
        }
        exit(EXIT_FAILURE);
    }

    // Return a pointer to GPIO info structure for a given GPIO
    GPIO_info *MW_getGpioInfo(const uint32_T pin)
    {
        int i;
        GPIO_info *ptr = NULL;

        for (i = 0; i < numGpio; i++) {
            if (gpioInfo[i].pin == pin) {
                ptr = &gpioInfo[i];
                break;
            }
        }

        return ptr;
    }

    // Dump GPIO information to command line
    void MW_dumpGpioInfo(const uint8_T *text)
    {
        int i;

        printf("%s:\n", text);
        if (gpioInfo == NULL) {
            printf("Nothing to dump. gpioInfo == NULL\n");
        }
        for (i = 0; i < numGpio; i++) {
            printf("GPIO = %d, dir = %d, res = %d, fd = %d\n", 
                    gpioInfo[i].pin, gpioInfo[i].direction, gpioInfo[i].fd);
        }
    }

    // Initialize GPIO module
    void MW_gpioInit(const uint32_T pin, const boolean_T direction)
    {
        GPIO_info *gpioInfoPtr;

        gpioInfo = realloc(gpioInfo, (numGpio + 1) * sizeof(GPIO_info));
        if (gpioInfo == NULL) {
            fprintf(stderr, "Error allocating memory for GPIO pin %d.\n", pin);
            gpioExit();
        }
        gpioInfoPtr = gpioInfo + numGpio;

        //Fill in GPIO info structure for the GPIO module
    #ifdef _DEBUG
        printf("gpio = %d, direction = %d\n", pin, direction);
    #endif
        gpioInfoPtr->pin       = pin;
        gpioInfoPtr->direction = direction;
        gpioInfoPtr->fd        = -1;
        numGpio++;

        // System calls to initialize GPIO pin
        if (gpioExport(pin) < 0) {
            fprintf(stderr, "Error exporting GPIO pin.\n");
            gpioExit();
        }
        if (gpioSetDirection(pin, direction) < 0) { 
            fprintf(stderr, "Error setting GPIO pin direction.\n");
            gpioExit();
        }
        gpioInfoPtr->fd = gpioOpen(pin, direction);
        if (gpioInfoPtr->fd < 0) {
            fprintf(stderr, "Error opening GPIO.\n");
            gpioExit();
        }
    #ifdef _DEBUG
        MW_dumpGpioInfo("INIT");
    #endif
    }

    // Close GPIO module
    void MW_gpioTerminate(uint32_T pin)
    {
        GPIO_info *gpioInfoPtr = NULL;
        static int32_T numClosedGpio = 0;

        // Get GPIO information pointer and close the GPIO file descriptor
        gpioInfoPtr = MW_getGpioInfo(pin);
        if (gpioInfoPtr == NULL) {
            return;
        }
        if (gpioClose(gpioInfoPtr->fd) < 0) {
            fprintf(stderr, "Error closing GPIO module.\n");
        }
        if (gpioUnexport(pin) < 0) {
            fprintf(stderr, "Error closing GPIO module.\n");
        }
        numClosedGpio++;
        if ((numClosedGpio == numGpio) && !gpioInfo) {
            free(gpioInfo);
        }
    }

    // Read value from given GPIO pin
    boolean_T MW_gpioRead(uint32_T pin)
    {
        GPIO_info *gpioInfoPtr = NULL;
        char value;

        // Get GPIO information pointer
        gpioInfoPtr = MW_getGpioInfo(pin);
        lseek(gpioInfoPtr->fd, 0, SEEK_SET);
        if (read(gpioInfoPtr->fd, &value, 1) < 0) {
            return(0);
        }
    #ifdef _DEBUG
        printf("GPIO%d=%d\n",pin,(value - '0'));
    #endif

        // The sysfs returns the value as a char. Convert the value to bool.
        return((boolean_T)(value - '0'));
    }

    // Write value to given GPIO pin
    void MW_gpioWrite(uint32_T pin, boolean_T value)
    {
        GPIO_info *gpioInfoPtr = NULL;
        ssize_t bytesWritten;

        // Get GPIO information pointer
        gpioInfoPtr = MW_getGpioInfo(pin);
        lseek(gpioInfoPtr->fd, 0, SEEK_SET);
        if (value) {
            bytesWritten = write(gpioInfoPtr->fd, "1", 2);
        }
        else {
            bytesWritten = write(gpioInfoPtr->fd, "0", 2);
        }
    }

    #ifdef _MW_GPIO_TEST_
    #define NUM_GPIO_OPS    (100000)
    // Main function
    int main(int argc, char *argv[])
    {
        uint32_T pin = 121; 
        int i;

        // Open GPIO device
        printf("Opening GPIO %d for input. Reading for %d times.\n", pin, NUM_GPIO_OPS);
        MW_gpioInit(pin, GPIO_DIRECTION_INPUT);
        i = 0;
        while (i < NUM_GPIO_OPS) {
            MW_gpioRead(pin);
    #ifdef _DEBUG
            printf("[%d]. GPIO value = %d\n", i, MW_gpioRead(pin));
            sleep(1);
    #endif
            i++;
        }
        MW_gpioTerminate(pin);

        printf("Opening GPIO %d for output. Writing for %d times.\n", pin, NUM_GPIO_OPS);
        MW_gpioInit(pin, GPIO_OUTPUT);
        i = 0;
        while (i < NUM_GPIO_OPS) {
            MW_gpioWrite(pin, i & 0x1);
    #ifdef _DEBUG
            printf("[%d]. GPIO value = %d\n", i, MW_gpioRead(pin));
            sleep(1);
    #endif
            i++;
        }
        MW_gpioTerminate(pin);

        exit(EXIT_SUCCESS);
    }
    #endif
#endif
