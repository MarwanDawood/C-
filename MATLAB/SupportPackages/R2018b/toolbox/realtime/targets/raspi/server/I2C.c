/* Copyright 2015-2016 The MathWorks, Inc.*/
#if !( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <unistd.h>
    #include <errno.h>
    #include <fcntl.h>
    #include <linux/i2c-dev.h>
    #include <sys/ioctl.h>
    #include <sys/types.h>
    #include <sys/stat.h>
    #include "common.h"
    #include "devices.h"
    #include "I2C.h"

    // Local defines
    #define MAX_BUF_SIZE            (32)
    #define I2C_BUS_AVAILABLE       (1)
    #define I2C_BUS_UNAVAILABLE     (0)
    #define NUM_MAX_BUSSES          (2)
    #define I2C_DEV_FILE            "/dev/i2c-"

    // Open I2C bus
    static int I2C_open(const unsigned int bus)
    {
        int fd;
        char buf[MAX_BUF_SIZE];
        unsigned long i2c_funcs = 0;

        snprintf(buf, sizeof(buf), I2C_DEV_FILE "%d", bus);
        fd = open(buf, O_RDWR);
        if (fd < 0) {
            perror("I2C_open/open");
        }

        // https://www.kernel.org/doc/Documentation/i2c/functionality
        // Check if I2C driver supports combined read/write operations
        // ioctl(file, I2C_RDWR, struct i2c_rdwr_ioctl_data *msgset)
        // Do combined read/write transaction without stop in between.
        // Only valid if the adapter has I2C_FUNC_I2C. 
        //if (ioctl(fd, I2C_FUNCS, &i2c_funcs) < 0) {
        //    fclose(fd);
        //    fd = -1;
        //    perror("I2C_open/ioctl(I2C_FUNCS)");
        //}

        return fd;
    }

    // Close I2C bus
    static void I2C_close(int fd)
    {
        int ret;

        ret = close(fd);
        if (ret < 0) {
            // EBADF, EINTR, EIO: In all cases, descriptor is torn down
            perror("I2C_close/close");
        }
    }

    // Write to I2C device
    int EXT_I2C_readRegister(
            const unsigned int bus, 
            const uint8_T address, 
            const uint8_T reg, 
            void *data, 
            const int count)
    {
        DEV_entry_t *dev;
        int ret;
        struct i2c_rdwr_ioctl_data i2c_data;
        struct i2c_msg msg[2];

        // Fill-in I2C message for the register to read
        // https://www.kernel.org/doc/Documentation/i2c/i2c-protocol
        msg[0].addr  = address;
        msg[0].flags = 0;        // Write
        msg[0].len   = 1;
        msg[0].buf   = &reg;
        msg[1].addr  = address;
        msg[1].flags = I2C_M_RD | I2C_M_NOSTART; // Read 
        msg[1].len   = count;
        msg[1].buf   = data;  
        i2c_data.msgs = msg;
        i2c_data.nmsgs = 2;

        // Get device handle
        dev = DEV_get(DEV_I2C_0 + bus);
        ret = ioctl(dev->fd, I2C_RDWR, &i2c_data);
        if (ret == -1) {
            perror("EXT_I2C_read/read");
            return ERR_I2C_READ_READ;
        }

        return 0;
    }

    int EXT_I2C_writeRegister(
            const unsigned int bus, 
            const uint8_T address, 
            const uint8_T reg, 
            const void *data, 
            const int count)
    {
        DEV_entry_t *dev;
        int ret;
        struct i2c_rdwr_ioctl_data i2c_data;
        struct i2c_msg msg[2];


        // Fill-in I2C message for the register to read
        // https://www.kernel.org/doc/Documentation/i2c/i2c-protocol
        // Splitting transaction into two generates a STOP after the first 
        // transfer even though the doc above indicates otherwise
        msg[0].addr  = address;
        msg[0].flags = 0;            // Write
        msg[0].len   = 1;
        msg[0].buf   = &reg;
        msg[1].addr  = address;
        msg[1].flags = I2C_M_NOSTART; // Write
        msg[1].len   = count;
        msg[1].buf   = data;  
        i2c_data.msgs = msg;
        i2c_data.nmsgs = 2;

        // Get device handle
        dev = DEV_get(DEV_I2C_0 + bus);
        ret = ioctl(dev->fd, I2C_RDWR, &i2c_data);
        if (ret == -1) {
            perror("EXT_I2C_read/read");
            return ERR_I2C_WRITE_REGISTER_WRITE;
        }

        return 0;
    }

    int EXT_I2C_write(
            const unsigned int bus, 
            const uint8_T address, 
            const void *data, 
            const int count)
    {
        DEV_entry_t *dev;
        int ret;
        struct i2c_rdwr_ioctl_data i2c_data;
        struct i2c_msg msg;

        // Fill-in I2C message for the register to read
        msg.addr  = address;
        msg.flags = 0; 
        msg.len   = count;
        msg.buf   = data; 
        i2c_data.msgs = &msg;
        i2c_data.nmsgs = 1;

        // Get device handle
        dev = DEV_get(DEV_I2C_0 + bus);
        ret = ioctl(dev->fd, I2C_RDWR, &i2c_data);
        if (ret == -1) {
            perror("EXT_I2C_read/read");
            return ERR_I2C_WRITE_REGISTER_WRITE;
        }

        return 0;
    }

    int EXT_I2C_read(
            const unsigned int bus, 
            const uint8_T address, 
            void *data, 
            const int count)
    {
        DEV_entry_t *dev;
        int ret;
        struct i2c_rdwr_ioctl_data i2c_data;
        struct i2c_msg msg;

        // Fill-in I2C message for the register to read
        msg.addr  = address;
        msg.flags = I2C_M_RD;  
        msg.len   = count;
        msg.buf   = data; 
        i2c_data.msgs = &msg;
        i2c_data.nmsgs = 1;

        // Get device handle
        dev = DEV_get(DEV_I2C_0 + bus);
        ret = ioctl(dev->fd, I2C_RDWR, &i2c_data);
        if (ret == -1) {
            perror("EXT_I2C_read/read");
            return ERR_I2C_READ_READ;
        }

        return 0;
    }

    // Return available status of an I2C bus
    int EXT_I2C_isBusAvailable(const unsigned int bus, boolean_T *available)
    {
        char buf[MAX_BUF_SIZE];
        struct stat statBuf;

        snprintf(buf, sizeof(buf), "/dev/i2c-%d", bus);
        if (stat(buf, &statBuf) == -1) {
            *available = I2C_BUS_UNAVAILABLE;
        }
        else {
            *available = I2C_BUS_AVAILABLE;
        }

        return 0;
    }

    // Initialize I2C device
    int EXT_I2C_init(const unsigned int bus)
    {
        DEV_entry_t *dev;

        // Get device handle
        dev = DEV_get(DEV_I2C_0 + bus);
        if (dev->fd < 0) {
            dev->fd = I2C_open(bus);
            if (dev->fd < 0) {
                perror("I2C_init/I2C_open");
                return ERR_I2C_INIT;
            }
        }
        DEV_lock(dev);

        return 0;
    }

    // Close I2C device 
    int EXT_I2C_terminate(const unsigned int bus) 
    {
        DEV_entry_t *dev;

        // Get device handle
        dev = DEV_get(DEV_I2C_0 + bus);
        DEV_unlock(dev);
        if (dev->refCount == 0) {
            if (dev->fd > 0) {
                I2C_close(dev->fd);
                dev->fd = -1;
            }
        }

        return 0;
    }

#endif
/* [EOF] */