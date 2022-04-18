#ifndef _MW_RASPI_INIT_H_
#define _MW_RASPI_INIT_H_
#ifdef __cplusplus
extern "C"
{
#endif
   
#include <signal.h>
    
void mwRaspiInit(void);
int mwRaspiTerminate(void);
void reportOverrun(int taskId);
#ifdef __cplusplus
}
#endif
#endif