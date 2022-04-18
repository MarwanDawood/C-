#if !( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <unistd.h>
    #include "devices.h"
    #define NUM_MAX_DEVICES (64)
    #define MAX_DEV_NAME    (64)


    /* Private data */
    DEV_entry_t devTable[NUM_MAX_DEVICES] = {
        //fd, *name, refCount
        {-1, "led0", 0},        
        {-1, "gpio0", 0},  
        {-1, "gpio1", 0}, 
        {-1, "gpio2", 0}, 
        {-1, "gpio3", 0}, 
        {-1, "gpio4", 0}, 
        {-1, "gpio5", 0}, 
        {-1, "gpio6", 0}, 
        {-1, "gpio7", 0}, 
        {-1, "gpio8", 0}, 
        {-1, "gpio9", 0}, 
        {-1, "gpio10", 0}, 
        {-1, "gpio11", 0}, 
        {-1, "gpio12", 0}, 
        {-1, "gpio13", 0}, 
        {-1, "gpio14", 0}, 
        {-1, "gpio15", 0}, 
        {-1, "gpio16", 0}, 
        {-1, "gpio17", 0}, 
        {-1, "gpio18", 0}, 
        {-1, "gpio19", 0}, 
        {-1, "gpio20", 0}, 
        {-1, "gpio21", 0}, 
        {-1, "gpio22", 0}, 
        {-1, "gpio23", 0}, 
        {-1, "gpio24", 0}, 
        {-1, "gpio25", 0}, 
        {-1, "gpio26", 0}, 
        {-1, "gpio27", 0}, 
        {-1, "gpio28", 0}, 
        {-1, "gpio29", 0}, 
        {-1, "gpio30", 0}, 
        {-1, "gpio31", 0}, 
        {-1, "i2c-0", 0}, 
        {-1, "i2c-1", 0},
        {-1, "spi-0.0", 0},
        {-1, "spi-0.1", 0},
        {-1, NULL, 0},       // 37 - 45: Serial devices
    };

    /* Use custom strndup function to avoid _POSIX_C_SOURCE 200809L issue
     * and to build stub server in windows
     */
    char *strndup_devName(const char *s, size_t n)
    {
        const size_t len = strlen(s);
        const size_t size_to_copy = n < len? n:len;

        char *const copy = malloc(size_to_copy + 1);
        if (copy != NULL) {
            memcpy(copy, s, size_to_copy);
            copy[size_to_copy] = '\0';
        }

        return copy;
    }
    

    // Return device ID given device name 
    int DEV_getByName(const char *name)
    {
        int i;

        for (i = NUM_MAX_DEVICES - 1; i > -1; i--) {
            if ((name != NULL) && (devTable[i].name != NULL) &&
                    (strncmp(name, devTable[i].name, MAX_DEV_NAME) == 0)) {
                break;
            }
        }

        return i;
    }

    // Allocate device
    int DEV_alloc(const char *name)
    {
        int i;

        for (i = DEV_SERIAL_0; i < NUM_MAX_DEVICES; i++) {
            if (devTable[i].name == NULL) {
                break;
            }
        }
        if (i >= NUM_MAX_DEVICES) {
            fprintf(stderr, "Cannot allocate a new device for %s: [%d]\n", 
                    name, i);
            return -1;
        }
        devTable[i].name = strndup_devName(name, MAX_DEV_NAME);

        return i;
    }

    // Free device
    void DEV_free(const int devNo)
    {
        if (devNo >= NUM_MAX_DEVICES) {
            fprintf(stderr, "Device number out of range: [%d]\n", devNo);
        }
        else {
            if (devTable[devNo].name) {
                free(devTable[devNo].name);
                devTable[devNo].name = NULL;
            }
        }
    }

    // Lock a device for use
    void DEV_lock(DEV_entry_t *dev)
    {
        dev->refCount++;
    }

    // Unlock a device
    void DEV_unlock(DEV_entry_t *dev)
    {
        dev->refCount--;
    }

    // Get device table entry given device id
    DEV_entry_t *DEV_get(const int devNo) 
    {
        if (devNo >= NUM_MAX_DEVICES) {
            fprintf(stderr, "Device number out of range: [%d]\n", devNo);     
            return NULL;
        }

        return (&devTable[devNo]);
    }


    // Initialize device table
    void DEV_init(void) 
    {
        int i;

        for (i = DEV_SERIAL_0; i < NUM_MAX_DEVICES; i++) {
            devTable[i].fd       = -1;
            devTable[i].name     = NULL;
            devTable[i].refCount = 0;
        }
    }
#endif
/* EOF*/