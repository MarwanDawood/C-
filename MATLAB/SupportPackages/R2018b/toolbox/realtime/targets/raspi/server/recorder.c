#include <stdio.h>
#include <pthread.h>
#include "handler.h"

int checkResourceEnable(struct peripheralData *pData)
{
    int ret;
    if(pData->enableFlag == DISABLE){
        printf("expire time 0 \n");
        pData->totalTimeExpired = 0;
        ret=DISABLE;
    }else    {
        /* Calculating total time to expire for capture */
        pData->totalTimeExpired = (unsigned long long )(pData->totTime)*1000000;
        ret=ENABLE;
    }
    return ret;
}
void waitForStartRecordEvent(void)
{
    int err;
    /* Upon successful completion, a value of zero shall be returned; otherwise, an error number shall be returned to indicate the error */
    err = pthread_cond_wait(&countCond, &countLock);
    if(err == 0){
#if DEBUG
        printf("Peripheral wait condition unblocked\n");
#endif
    }else{
        perror(" Peripheral wait  Condition lock error:");
    }

    /* If successful, the pthread_mutex_lock() and pthread_mutex_unlock() 
       functions shall return zero; otherwise, an error number shall be returned to indicate the error. */
    err = pthread_mutex_unlock( &countLock );
    if(err == 0){
#if DEBUG
        printf(" Peripheral mutex unlocked\n");
#endif
    }else{
        perror(" Peripheral mutex unlock error:");
    }

}
