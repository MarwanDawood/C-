#if (defined(_MATLABIO_) || defined(_RUNONTARGETHARDWARE_BUILD_) || defined(ARM_PROJECT))
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <unistd.h>
    #include <errno.h>
    #include <sys/wait.h>
    #include "common.h"
    #include "system.h"


    /* Execute given system command */
    int EXT_SYSTEM_system(const char *cmd) 
    {
        int ret;

        ret = system(cmd);
        if (ret < 0) {
            return ERR_SYSTEM_SYSTEM;
        }

        return 0;
    }

    int EXT_SYSTEM_popen(const char *cmd, char *buf, size_t bufSize) 
    {
        FILE *p;
        size_t ret;

        p = popen(cmd, "r");
        if (!p) {
            return errno;
        }

        /* Return command output to host */
        ret = fread(buf, 1, (size_t) (bufSize - 1), p);
        buf[ret] = 0;

        /* Get and return exit status */
        return WEXITSTATUS(pclose(p));
    }

#endif /* EOF */