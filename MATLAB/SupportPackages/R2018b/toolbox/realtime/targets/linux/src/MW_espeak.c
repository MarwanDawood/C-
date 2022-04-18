/* Copyright 2012-2016 The MathWorks, Inc.*/
#include "MW_espeak.h"
#if !( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
    #include <unistd.h>
    #include <stdlib.h>
    #include <stdio.h>
    #include <ctype.h>
    #include <string.h>
    #include <fcntl.h>
    #include <sys/types.h>
    #include <sys/stat.h>
    #include <errno.h>
    #include <sys/wait.h>
    #include <linux/limits.h>
    #include <spawn.h>
    #include <time.h>

    // "environ" is defined in <unistd.h>
    extern char **environ;
    static int EXT_SYSTEM_spawn(const char *cmd)
    {
        pid_t pid;
        const char *argv[] = {"bash", "-c", cmd, NULL};
        int s, ret = 0;
        posix_spawnattr_t attr;
        posix_spawnattr_t *attrp = NULL;
        struct sched_param sp;

        // Set scheduling parameters. We want to create a process with normal
        // scheduling attributes.
        s = posix_spawnattr_init(&attr);
        if (s != 0) {
            perror("posix_spawnattr_init");
            return -1;
        }
        attrp = &attr;
        s = posix_spawnattr_setflags(attrp,POSIX_SPAWN_SETSCHEDULER | POSIX_SPAWN_SETSCHEDPARAM);
        s |= posix_spawnattr_setschedpolicy(attrp,SCHED_OTHER);
        memset(&sp,0,sizeof(sp));
        sp.sched_priority = 0; // Must be defined as 0 when SCHED_OTHER policy is used
        s |= posix_spawnattr_setschedparam(attrp,&sp);
        if (s != 0) {
            perror("posix_spawnattr_setflags");
            ret = -1;
            goto EXT_SYSTEM_spawn_CLEANUP;
        }

        // Spawn given process
        s = posix_spawn(&pid, "/bin/bash", NULL, attrp, argv, environ);
        if (s == 0) {
            if (waitpid(pid, &s, 0) < 0) {
                perror("waitpid");
                ret -1;
            }
        }
        else {
            perror("posix_spawn");
            ret = -1;
        }

    EXT_SYSTEM_spawn_CLEANUP:
        if (attrp != NULL) {
            posix_spawnattr_destroy(attrp);
        }
        return ret;
    }

    // Init audio reader
    int32_T MW_ESPEAK_output(const uint8_T *cmd)
    { 
    #ifdef _DEBUG
        printf("cmd='%s'\n",cmd);
    #endif      
        if (EXT_SYSTEM_spawn(cmd) != 0) {
            return -1;
        }

        return 0;
    }
#endif
/*[EOF]*/