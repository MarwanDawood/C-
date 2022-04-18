/* Copyrights 2013-2014, MathWorks Inc */
#include <unistd.h>
#include <rtwtypes.h>
#include <time.h>
extern uint32_T profileReadTimer(void);
#ifdef MW_STANDALONE_EXECUTION_PROFILER_ON
extern unsigned int _tmwrunningCoreID;
#endif

#if (!defined(_POSIX_TIMERS) || (_POSIX_TIMERS == 0))
#error "POSIX timers used for execution profiling are not supported on your system."
#endif

#ifdef _VX_TOOL_FAMILY
#include <vxWorks.h>
#include <taskLib.h>
#include <vxCpuLib.h>
#include <cpuset.h>
static int getVxWorksCoreID()
{
    int ret = -1;
    cpuset_t affi;
    if (taskCpuAffinityGet(0, &affi) == OK) {
        if (CPUSET_ISZERO(affi)) {
            ret = 0;
        }
        else {
            ret = CPUSET_FIRST_SET(affi);
        }
    }
    return ret;
}
#endif

uint32_T profileReadTimer(void)
{
    struct timespec tp;
    uint32_T ret;
    int status;
    static int last = 0;
    
    status = clock_gettime(CLOCK_REALTIME, &tp);
    if (status == 0) {
        ret = (uint32_T) (tp.tv_sec * 1000000000 + tp.tv_nsec);  /* Return time in nanoseconds */
    }
    else {
        ret = 0;
    }
    
#ifdef MW_STANDALONE_EXECUTION_PROFILER_ON
#ifdef _VX_TOOL_FAMILY
    _tmwrunningCoreID = getVxWorksCoreID();
#else
    _tmwrunningCoreID = sched_getcpu();
#endif
#endif
    
    return(ret);
}

/* EOF */