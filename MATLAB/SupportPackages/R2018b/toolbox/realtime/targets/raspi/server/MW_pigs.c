#include "MW_pigs.h"

#if (defined(_MATLABIO_) || defined(_RUNONTARGETHARDWARE_BUILD_) || defined(ARM_PROJECT))
    #include <stdio.h>
    #include "system.h"

    #define CMD_SIZE  32
    #define BUF_SIZE  256

    static int32_T checkAndStartPigpiod(void)
    {
        int32_T ret;
        char cmd[CMD_SIZE], buf[BUF_SIZE];

        // Check if pigpiod daemon is running
        snprintf(cmd,CMD_SIZE,"pgrep pigpiod\n");
        ret = EXT_SYSTEM_popen(cmd, buf, sizeof(buf));
        if (ret != 0) {
            snprintf(cmd,CMD_SIZE,"sudo pigpiod && sleep 0.1\n");
            ret = EXT_SYSTEM_popen(cmd, buf, sizeof(buf));
            if (ret != 0) {
                fprintf(stderr,"Error: Unable to start pigpiod daemon required for PWM output. "
                        "Try manually starting the daemon by executing "
                        "\"sudo pigpiod\" command on a Linux shell.");
                return ERR_PWM_PIGPIOINIT;
            }
        }

        return 0;
    }

    // Initialize a pin to output PWM waveform
    int32_T EXT_PWM_setFrequency(uint32_T pin, uint32_T frequency)
    {
        int32_T ret;
        char cmd[CMD_SIZE], buf[BUF_SIZE];

        // pigs pfs <pin> <frequency>\n
        snprintf(cmd,CMD_SIZE,"pigs pfs %d %d\n",pin,frequency);
        ret = EXT_SYSTEM_popen(cmd, buf, sizeof(buf));
        if (ret != 0) {
            return ERR_PWM_SETFREQUENCY;
        }

        return ret;
    }

    // Change duty cycle
    int32_T EXT_PWM_setDutyCycle(uint32_T pin, double dutyCycle)
    {
        int32_T ret = 0;
        char cmd[CMD_SIZE], buf[BUF_SIZE];

        // pigs p <pin> <dutyCyle>\n
        snprintf(cmd,CMD_SIZE,"pigs p %d %d\n",pin,(unsigned int) (dutyCycle * 10000));
        ret = EXT_SYSTEM_popen(cmd, buf, sizeof(buf));
        if (ret != 0) {
            return ERR_PWM_SETDUTYCYLE;
        }

        return ret;
    }

    // Change frequency
    int32_T EXT_PWM_init(uint32_T pin, uint32_T frequency, double initialDutyCycle)
    {
        int32_T ret;
        char cmd[CMD_SIZE], buf[BUF_SIZE];

        ret = checkAndStartPigpiod();
        if (ret != 0) {
            return ERR_PWM_PIGPIOINIT;
        }

        // Set PWM frequency
        ret = EXT_PWM_setFrequency(pin, frequency);
        if (ret != 0) {
            return ERR_PWM_SETFREQUENCY;
        }

        // Set PWM range
        snprintf(cmd,CMD_SIZE,"pigs prs %d 10000\n",pin);
        ret = EXT_SYSTEM_popen(cmd, buf, sizeof(buf));
        if (ret != 0) {
            return ERR_PWM_SETRANGE;
        }

        // Set initial duty cycle
        if (ret == 0) {
            ret = EXT_PWM_setDutyCycle(pin, initialDutyCycle);
        }

        return ret;
    }

    // Initialize a pin to send servo pulses
    int32_T EXT_SERVO_init(uint32_T pin)
    {
        int32_T ret;
        char cmd[CMD_SIZE], buf[BUF_SIZE];

        ret = checkAndStartPigpiod();
        if (ret != 0) {
            return ERR_PWM_PIGPIOINIT;
        }

        // pigs s <pin> <frequency>\n
        snprintf(cmd,CMD_SIZE,"pigs s %d 0\n",pin);
        ret = EXT_SYSTEM_popen(cmd, buf, sizeof(buf));
        if (ret != 0) {
            return ERR_SERVO_INIT;
        }

        return ret;
    }

    // Set the position of the servo shaft
    // 0 < shaftAngle < 180 represents shaft angle
    int32_T EXT_SERVO_write(uint32_T pin, double shaftAngle, double minPulseWidth, double maxPulseWidth)
    {
        uint32_T pw;
        char cmd[CMD_SIZE], buf[BUF_SIZE];
        int32_T ret;

        // pigs pfs <pin> <frequency>\n
        pw = minPulseWidth  + (shaftAngle/180) * (maxPulseWidth - minPulseWidth);
        snprintf(cmd,CMD_SIZE,"pigs s %d %d\n",pin,(unsigned int)pw);
        ret = EXT_SYSTEM_popen(cmd, buf, sizeof(buf));
        if (ret != 0) {
            return ERR_SERVO_SETPW;
        }

        return ret;
    }

    // Terminate pigpio library
    int32_T EXT_SERVO_terminate(uint32_T pin)
    {
        char cmd[CMD_SIZE], buf[BUF_SIZE];

        // Turn off servo pulses
        snprintf(cmd,CMD_SIZE,"pigs s %d 0\n",pin);
        EXT_SYSTEM_popen(cmd, buf, sizeof(buf));

        return 0;
    }

    // Terminate pigpio library
    int32_T EXT_PWM_terminate(uint32_T pin)
    {
        // Turn off PWM pulses
        EXT_PWM_setDutyCycle(pin, 0);

        return 0;
    }
#endif
/* [EOF] */