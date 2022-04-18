/* Copyright 2016-2017 The MathWorks, Inc. */
#include "MW_I2C.h"

#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
    /* Initialize a I2C */
    MW_Handle_Type MW_I2C_Open(uint32_T I2CModule, MW_I2C_Mode_Type i2c_mode)
    {
        return MW_UNDEFINED_VALUE;
    }

    /* Set the I2C bus speed in Master Mode */
    MW_I2C_Status_Type MW_I2C_SetBusSpeed(MW_Handle_Type I2CModuleHandle, uint32_T BusSpeed)
    {
        return MW_I2C_SUCCESS;
    }

    /* Set the slave address (used only by slave) */
    MW_I2C_Status_Type MW_I2C_SetSlaveAddress(MW_Handle_Type I2CModuleHandle, uint32_T SlaveAddress)
    {
        return MW_I2C_SUCCESS;
    }

    /* Initiate I2C communication, send a start signal on I2C bus. */
    MW_I2C_Status_Type MW_I2C_Start(MW_Handle_Type I2CModuleHandle)
    {
        return MW_I2C_SUCCESS;
    }

    /* Receive the data on Master device from a specified slave */
    MW_I2C_Status_Type MW_I2C_MasterRead(MW_Handle_Type I2CModuleHandle, uint16_T SlaveAddress, uint8_T * data, uint32_T DataLength, uint8_T RepeatedStart, uint8_T SendNoAck)
    {
        return MW_I2C_SUCCESS;
    }

    /* Send the data from master to a specified slave */
    MW_I2C_Status_Type MW_I2C_MasterWrite(MW_Handle_Type I2CModuleHandle, uint16_T SlaveAddress, uint8_T * data, uint32_T DataLength, uint8_T RepeatedStart, uint8_T SendNoAck)
    {
        return MW_I2C_SUCCESS;
    }

    /* Read data on the slave device from a Master */
    MW_I2C_Status_Type MW_I2C_SlaveRead(MW_Handle_Type I2CModuleHandle, uint8_T * data, uint32_T DataLength, uint8_T SendNoAck)
    {
        return MW_I2C_SUCCESS;
    }

    /* Send the data to a master from the slave */
    MW_I2C_Status_Type MW_I2C_SlaveWrite(MW_Handle_Type I2CModuleHandle, uint8_T * data, uint32_T DataLength, uint8_T SendNoAck)
    {
        return MW_I2C_SUCCESS;
    }

    /* Get the status of I2C device */
    MW_I2C_Status_Type MW_I2C_GetStatus(MW_Handle_Type I2CModuleHandle)
    {
        return MW_I2C_SUCCESS;
    }

    /* Terminate the I2C communication */
    MW_I2C_Status_Type MW_I2C_Stop(MW_Handle_Type I2CModuleHandle)
    {
        return MW_I2C_SUCCESS;
    }

    /* Release I2C module */
    void MW_I2C_Close(MW_Handle_Type I2CModuleHandle)
    {
    }

#else
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

    /* Write with I2C bus */
    int EXT_I2C_writeH(
            DEV_entry_t * dev, 
            const uint8_T address, 
            const void *data, 
            const int count)
    {
        int ret;
        struct i2c_rdwr_ioctl_data i2c_data;
        struct i2c_msg msg;

        if (dev != (DEV_entry_t *)NULL)
        {
            // Fill-in I2C message for the register to read
            msg.addr  = address;
            msg.flags = 0; 
            msg.len   = count;
            msg.buf   = data; 
            i2c_data.msgs = &msg;
            i2c_data.nmsgs = 1;
    
            /* Write data */
            ret = ioctl(dev->fd, I2C_RDWR, &i2c_data);
            if (ret == -1) {
                perror("EXT_I2C_write/write");
                return ERR_I2C_WRITE_REGISTER_WRITE;
            }
        }
        else
        {
            perror("EXT_I2C_write/write");
            return ERR_I2C_WRITE_REGISTER_WRITE;
        }

        return 0;
    }

    /* Read with I2C bus */
    int EXT_I2C_readH(
            DEV_entry_t *dev, 
            const uint8_T address, 
            void *data, 
            const int count)
    {
        int ret;
        struct i2c_rdwr_ioctl_data i2c_data;
        struct i2c_msg msg;

        if (dev != (DEV_entry_t *)NULL)
        {
            // Fill-in I2C message for the register to read
            msg.addr  = address;
            msg.flags = I2C_M_RD;  
            msg.len   = count;
            msg.buf   = data; 
            i2c_data.msgs = &msg;
            i2c_data.nmsgs = 1;
    
            /* Get data from I2C bus */
            ret = ioctl(dev->fd, I2C_RDWR, &i2c_data);
            if (ret == -1) {
                perror("EXT_I2C_read/read");
                return ERR_I2C_READ_READ;
            }
        }
        else
        {
            perror("EXT_I2C_read/read");
            return ERR_I2C_READ_READ;
        }

        return 0;
    }

    // Initialize I2C device
    DEV_entry_t * EXT_I2C_initH(const unsigned int bus)
    {
        DEV_entry_t *dev = NULL;

        // Get device handle
        dev = DEV_get(DEV_I2C_0 + bus);
        if (dev->fd < 0) {
            dev->fd = I2C_open(bus);
            if (dev->fd < 0) {
                perror("I2C_init/I2C_open");
                /*return ERR_I2C_INIT;*/
                return (DEV_entry_t *)NULL;
            }
        }
        DEV_lock(dev);

        return dev;
    }

    // Close I2C device 
    int EXT_I2C_terminateH(DEV_entry_t * dev) 
    {
        if (dev != (DEV_entry_t *)NULL)
        {
            DEV_unlock(dev);
            if (dev->refCount == 0) {
                if (dev->fd > 0) {
                    I2C_close(dev->fd);
                    dev->fd = -1;
                }
            }
        }

        return 0;
    }


    /* Initialize a I2C */
    MW_Handle_Type MW_I2C_Open(uint32_T I2CModule, MW_I2C_Mode_Type i2c_mode)
    {
        MW_Handle_Type h;
        h = (MW_Handle_Type)EXT_I2C_initH(I2CModule);

        return h;
    }

    /* Set the I2C bus speed in Master Mode */
    MW_I2C_Status_Type MW_I2C_SetBusSpeed(MW_Handle_Type I2CModuleHandle, uint32_T BusSpeed)
    {
        return MW_I2C_SUCCESS;
    }

    /* Set the slave address (used only by slave) */
    MW_I2C_Status_Type MW_I2C_SetSlaveAddress(MW_Handle_Type I2CModuleHandle, uint32_T SlaveAddress)
    {
        return MW_I2C_SUCCESS;
    }

    /* Receive the data on Master device from a specified slave */
    MW_I2C_Status_Type MW_I2C_MasterRead(MW_Handle_Type I2CModuleHandle, uint16_T SlaveAddress, uint8_T * data, uint32_T DataLength, uint8_T RepeatedStart, uint8_T SendNoAck)
    {
        int32_T status;
        status = EXT_I2C_readH((DEV_entry_t *)I2CModuleHandle, SlaveAddress, data, DataLength);
        if (0 == status)
            return MW_I2C_SUCCESS;
        else /* if (0 != status) */
            return MW_I2C_BUS_ERROR;
    }

    /* Send the data from master to a specified slave */
    MW_I2C_Status_Type MW_I2C_MasterWrite(MW_Handle_Type I2CModuleHandle, uint16_T SlaveAddress, uint8_T * data, uint32_T DataLength, uint8_T RepeatedStart, uint8_T SendNoAck)
    {
        int32_T status;

        status = EXT_I2C_writeH((DEV_entry_t *)I2CModuleHandle, SlaveAddress, data, DataLength);
        
        if (0 == status)
            return MW_I2C_SUCCESS;
        else /* if (0 != status) */
            return MW_I2C_BUS_ERROR;
    }

    /* Read data on the slave device from a Master */
    MW_I2C_Status_Type MW_I2C_SlaveRead(MW_Handle_Type I2CModuleHandle, uint8_T * data, uint32_T DataLength, uint8_T SendNoAck)
    {
        return MW_I2C_SUCCESS;
    }

    /* Send the data to a master from the slave */
    MW_I2C_Status_Type MW_I2C_SlaveWrite(MW_Handle_Type I2CModuleHandle, uint8_T * data, uint32_T DataLength, uint8_T SendNoAck)
    {
        return MW_I2C_SUCCESS;
    }

    /* Get the status of I2C device */
    MW_I2C_Status_Type MW_I2C_GetStatus(MW_Handle_Type I2CModuleHandle)
    {
        return MW_I2C_SUCCESS;
    }

    /* Release I2C module */
    void MW_I2C_Close(MW_Handle_Type I2CModuleHandle)
    {
        EXT_I2C_terminateH((DEV_entry_t *)I2CModuleHandle);
    }
#endif
#ifdef __cplusplus
}
#endif