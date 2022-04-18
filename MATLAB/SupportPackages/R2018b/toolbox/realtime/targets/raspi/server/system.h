#if (defined(_MATLABIO_) || defined(_RUNONTARGETHARDWARE_BUILD_) || defined(ARM_PROJECT))
    #ifndef _MW_SYSTEM_H_
    #define _MW_SYSTEM_H_
    #include "common.h"

    #define ERR_SYSTEM_BASE      (10000)
    #define ERR_SYSTEM_SYSTEM    (ERR_SYSTEM_BASE)
    #define ERR_SYSTEM_POPEN     (ERR_SYSTEM_BASE+1)

    extern int EXT_SYSTEM_system(const char *cmd);
    extern int EXT_SYSTEM_popen(const char *cmd, char *buf, size_t bufSize);
    #endif

#else
    
    #define EXT_SYSTEM_system(a) 0
    #define EXT_SYSTEM_popen(a, b, c) 0
    
#endif /* _MW_SYSTEM_H_ */