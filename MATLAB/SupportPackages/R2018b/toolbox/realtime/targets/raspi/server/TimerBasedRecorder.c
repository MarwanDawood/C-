/* Copyright 2018 The MathWorks, Inc. */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <pthread.h>
#include <errno.h>
#ifdef NANOMSG_TRANSPORT
#include <nanomsg/nn.h>
#include <nanomsg/pubsub.h>
#endif
#include "dataCapture.h"
#include "common.h"    
#include "handler.h"
#include "TimerBasedRecorder.h"
#include "GPIO.h"
#include "recorder.h"
#define GPIO_VALUE_BYTES      1
#define GPIO_SUB_TOKEN_SIZE   6
struct timespec startTime;

/* Creation of periodic timer */
int makePeriodic(struct peripheralData *pData)
{
    unsigned int ns;
    unsigned int sec;

    /* Create the timer */
    pData->timerFd = timerfd_create(CLOCK_MONOTONIC, 0);
    pData->wakeupsMissed = 0;


    if (pData->timerFd == -1)
        return pData->timerFd;

    /* Make the timer periodic */
    sec = pData->timerPeriod / 1000000;
    ns = (pData->timerPeriod - (sec * 1000000)) * 1000;

    /* timer interval */
    pData-> itVal.it_interval.tv_sec = sec;
    pData-> itVal.it_interval.tv_nsec = ns;

    /* initial expiration */

    pData->itVal.it_value.tv_sec = sec;
    pData->itVal.it_value.tv_nsec = ns;
#if DEBUG
    printf("timer created %d\n",pData->timerFd);
#endif
    return 0;
}

/* Reading the timer fd to for timer expiration signal */
void waitPeriod(struct peripheralData *pData)
{
    unsigned long long missed;
    int ret;

    /* Wait for the next timer event. If we have missed any the
       number is written to "missed"*/
    ret = read(pData->timerFd, &missed, sizeof(missed));
    if (ret == -1) {
        perror("read timer:");
        return;
    }
    /* Increase the missed counter value */
    pData->wakeupsMissed += missed;
}

/* Reading the GPIO State at the recieving of start command */
short readGpio(boolean_T *mem, int pin)
{
#if DEBUG
    LOG_PRINT(stdout, "REQUEST_GPIO_READ: GPIO(%d)\n", pin);
#endif

    /* Read the gpio state */
    EXT_GPIO_read(pin, mem);
    return 0;
}

/* Release fucntion */
void releaseData(void *arg, void * null)
{

    struct peripheralData *pData=NULL, *pBaseData = (struct peripheralData *)arg;
    pData = pBaseData;
    while(pData != NULL)
    {
        pData->startCaptureFlag = STOP;    /* Making start capture flag 0 */
        /* Reinitilaize all the counters and free the allocated memory */    
        pData->totalTimeExpired = 0;
        pData->timerCnt = 0;
        if(pData->fprd !=NULL)
        {
            //pData->startCaptureFlag = STOP;    /* Making start capture flag 0 */
            fclose(pData->fprd);
            pData->fprd = NULL;
        }
        pData = pData->next; 
    }
}

/* Initialize Function */
int  initializeData(void *arg, void *null)
{

    struct peripheralData *pData = (struct peripheralData *)arg;
    int err;
    /* Create the timer with given timer interval */
    err = makePeriodic( pData );
    if(err < 0)
    {
        perror("GPIO Timer creation error:");
    }
    else
    {
#if DEBUG
        printf(" GPIO Timer creation Successfull");
#endif
    }
    /* initialization of timer expiration counter to calculate the total remaining time */
    pData->timerCnt = 0;
    return 0;
}
int  initializeCallbacks(void *arg)
{
    struct peripheralData *pData = (struct peripheralData *)arg;
    /* Initialization of read gpio callback function nad release function */
    pData->capture = readGpio;
    pData->release = releaseData;
    return 0;
}
unsigned char *allocateDataMemory(struct peripheralData *pData)
{
    struct peripheralData *tmpPdata=NULL;
    tmpPdata = pData;
    while(tmpPdata != NULL)
    {
        /* if logType is Memory Based */
        if(pData->logType == MEMORY_LOG)
        {
            /* Allocating memory for gpio state and relative Time Multiply by 9 because : 8 Bytes Relative time 1 Byte gpio State */ 
            tmpPdata->FileMemBuff = malloc((TIME_STAMP_BYTES + GPIO_VALUE_BYTES)*((pData->totTime*1000000)/tmpPdata->timerPeriod));
            tmpPdata->memBuff = tmpPdata->FileMemBuff ;        
            if(tmpPdata->memBuff == NULL)
            {
                perror(" Memory allocation Error:-");
                exit(EXIT_FAILURE);
            }
            else
            {
#if DEBUG
                printf("allocated bytes %lu\n", 9*((pData->totTime*1000000)/tmpPdata->timerPeriod));
#endif
            } 
            /* Assignment of memory pointer to local buffer for data writting */      
        }
        /* if logType is Direct file write */
        else if (pData->logType == DIRECT_LOG)
        {
            tmpPdata->FileMemBuff = malloc((TIME_STAMP_BYTES + GPIO_VALUE_BYTES));
            tmpPdata->memBuff = tmpPdata->FileMemBuff ;
            if(tmpPdata->memBuff == NULL)
            {
                printf("memory allocation for gpio %d is failed \n ",tmpPdata->perId);
                exit(EXIT_FAILURE);
            }
            else
            {
#if DEBUG
                printf("allocated bytes \n");
#endif
            }

        }
#ifdef NANOMSG_TRANSPORT            
        else if(pData->logType == STREAM)
        {
            /* Allocate 16 bytes for intial token, Relative Time and gpio State Value */
            tmpPdata->FileMemBuff = (unsigned char *)malloc((TIME_STAMP_BYTES + GPIO_VALUE_BYTES + GPIO_SUB_TOKEN_SIZE));
            tmpPdata->memBuff = tmpPdata->FileMemBuff ;
            if(tmpPdata->memBuff == NULL)
            {
                printf("memory allocation for gpio %d is failed \n ",tmpPdata->perId);
                exit(EXIT_FAILURE);
            }

            else
            {
#if DEBUG
                printf("allocated bytes \n");
#endif
            }
            sprintf(( char *)tmpPdata->memBuff, "gpio%d|", pData->perId);
            tmpPdata->memBuff = tmpPdata->memBuff + GPIO_SUB_TOKEN_SIZE; 
        }
#endif
        else
        {

#if DEBUG
            perror("  wrong log type \n");
            exit(EXIT_FAILURE);
#endif
        }
        tmpPdata =tmpPdata->next ;
    }
    return 0 ;
}
void writeGpioHeaderInfo(struct peripheralData *pData)
{
    int err;
    char buff[30];
    unsigned long long diff;
    struct peripheralData *tmpPdata=NULL;    
    tmpPdata =pData;
    while(tmpPdata != NULL)
    {
        /* Writting file version number to header information */
        sprintf(tmpPdata->hInfo.version, "VER.%d.%d", 1, 1);
        tmpPdata->hInfo.recordDuration = (short)(pData->totTime);

        /* Binary filename corrosponding to peripheral Id */
        sprintf(buff, "/tmp/gpio%d_log_message.bin", tmpPdata->perId );

        /* Creation of binary file for data writting */
        tmpPdata->fprd = fopen( buff, "wb");

        /* Write header information  in to the file */
        err = fwrite(&(tmpPdata->hInfo), 1, sizeof(struct headerInfo), tmpPdata->fprd);
        if(err > 0)
        {
#if DEBUG
            printf(" GPIO  file writting %d bytes\n",err);
#endif
        }
        else
        {
            perror(" GPIO file write error:");
        }
        /* Reading start Capture time */
        if( clock_gettime( CLOCK_REALTIME, &startTime) == -1 ) {
            perror( "clock gettime" );
            exit( EXIT_FAILURE );
        }
#if DEBUG

        printf("start time is %u secs %ld nsecs\n",startTime.tv_sec, startTime.tv_nsec);
#endif 
        /* Conversion of absolute time in to relative time with nanosecond resolution */
        diff = startTime.tv_sec*BILLION + startTime.tv_nsec;

        /* Write Start time in to the file */
        err = fwrite(&diff, 1, sizeof(unsigned long long), tmpPdata->fprd);
        if(err > 0)
        {
#if DEBUG
            printf(" GPIO  file writting %d bytes\n",err);
#endif
        }
        else
        {
            perror(" GPIO file write error:");
        }
        tmpPdata = tmpPdata->next ;
    }
}
void startEventTimer( struct peripheralData *pData)
{
    int err;
    err = timerfd_settime(pData->timerFd, TFD_TIMER_ABSTIME , &(pData-> itVal), NULL);
    if(err == 0)
    {
#if DEBUG
        printf(" GPIO  timer started\n");
#endif
    }
    else
    {
        perror(" GPIO timer start error :");
    } 
}

void dumpDatatoMemory(struct peripheralData *pData)
{
    struct peripheralData *tmpPdata= pData;
    int err;
    while(tmpPdata != NULL)
    {
        /* File write the complete memory in to the file */    
        err = fwrite(tmpPdata->FileMemBuff, 1, (TIME_STAMP_BYTES + GPIO_VALUE_BYTES)*(tmpPdata->timerCnt), tmpPdata->fprd);
        if(err > 0)
        {
#if DEBUG
            printf(" GPIO: buffer data writting  for %d bytes\n", err);
#endif            
        }
        else
        {
            perror(" GPIO file write error:");
        }
        sleep(1);
        /* Free the dynamically allocated memory */
        free(tmpPdata->FileMemBuff);
        tmpPdata = tmpPdata->next ;
    }
}
void *gpioRead(void *Data)
{
    struct peripheralData *pData = (struct peripheralData *)Data; 
    int err;
    struct peripheralData *tmpPdata =NULL; 
    //setpriority(PRIO_PROCESS, syscall(SYS_gettid), -15);
    err = pthread_detach( pthread_self());
    if(err == 0)
    {
#if DEBUG
        printf(" GPIO  pthread_detach successfulll\n");
#endif
    }
    else
    {
        perror(" GPIO pthread_detach error:");
    }
    /* Declaration of local buffer for to store binary file name*/
    while(pData->startSessionFlag == START){

#if DEBUG
        printf(" *********** Waiting for start command from client ****** %d\n ",pData->perId);
#endif
        waitForStartRecordEvent();
        if (checkResourceEnable(pData)!= ENABLE )
        {
            pData->startCaptureFlag = STOP;    /* Making start capture flag 0 */
            continue;
        }
        if (pData->startSessionFlag == STOP)
            break;
        /* Initialixzation callback function */
        pData->initialize = initializeData;
        pData->initialize(pData,(void*)NULL);
        tmpPdata = pData;
        while(tmpPdata != NULL)
        {
            initializeCallbacks(tmpPdata);
            tmpPdata =tmpPdata->next ;
        }
        allocateDataMemory(pData);
        writeGpioHeaderInfo(pData);
        startEventTimer(pData);
        /* Data capture loop until total time is not expired or stop command is not issued from client */
        while ((pData->totalTimeExpired > 0) && (pData->startCaptureFlag == START))
        {
            /* Wait for timer to expire */
            waitPeriod(pData);
            tmpPdata = pData;
            while(tmpPdata != NULL)
            {        
                /* Increase the timer expiration counter */
                (tmpPdata->timerCnt)++;
#if DEBUG
                printf("tottime:%d ,timerCnt:%d ,timerperiod:%ld \n", pData->totTime, tmpPdata->timerCnt, tmpPdata->timerPeriod);
#endif
                /* Calculate the total remaining time to expire */
                tmpPdata->totalTimeExpired = (( pData->totTime )*( 1000 )- (long)(( tmpPdata->timerCnt )*( tmpPdata->timerPeriod )/1000 ));
#if DEBUG
                printf(" total time expired is %llu\n", tmpPdata->totalTimeExpired );
#endif
                /* read the Current time before reading the gpio state */
                if( clock_gettime( CLOCK_REALTIME, &tmpPdata->currTstamp) == -1 ) {
                    perror( "clock gettime" );
                    exit( EXIT_FAILURE );
                }
                if(pData->logType == MEMORY_LOG)
                {
                    /** Calculate the realtive time by  doing difference between start time and current time 
                     * StartTime is pointer to struct timespec  structure 
                     **/ 
                    *((unsigned long long *)tmpPdata->memBuff) = timeDiff(&startTime, &tmpPdata->currTstamp);
                    /* Increase the memory offset by 8 after writting 8 bytes relative time */     
                    tmpPdata->memBuff = tmpPdata->memBuff + 8 ;  
                    /* Call the gpio capture function to read the gpio status */
                    pData->capture(tmpPdata->memBuff, tmpPdata->perId);
                    tmpPdata->count++;
                    /* Increase the memory pointer after reading 1 byte gpio state */
                    tmpPdata->memBuff++;
                }
                else if(pData->logType == DIRECT_LOG)
                {
                    *((unsigned long long *)tmpPdata->memBuff) = timeDiff(&startTime, &tmpPdata->currTstamp);

                    /* Increase the memory offset by 8 after writting 8 bytes relative time */ 
                    tmpPdata->memBuff = tmpPdata->memBuff + TIME_STAMP_BYTES ;    //pData->capture( pData->perId, buffPtr );
                    pData->capture( tmpPdata->memBuff, tmpPdata->perId );
                    tmpPdata->memBuff = tmpPdata->memBuff - TIME_STAMP_BYTES;

                    /* File write the complete memory in to the file */    
                    err = fwrite(tmpPdata->FileMemBuff, 1, (TIME_STAMP_BYTES + GPIO_VALUE_BYTES), tmpPdata->fprd);
                    if(err > 0)
                    {
#if DEBUG
                        printf(" GPIO  file writting %d bytes\n",err);
#endif
                    }
                    else
                    {
                        perror(" GPIO file write error:");
                    }


                }
#ifdef NANOMSG_TRANSPORT
                else if(pData->logType == STREAM)
                {
                    *((unsigned long long *)tmpPdata->memBuff) = timeDiff(&startTime, &tmpPdata->currTstamp);
                    /* Increase the memory offset by 8 after writting 8 bytes relative time */
                    tmpPdata->memBuff = tmpPdata->memBuff + TIME_STAMP_BYTES ;
                    pData->capture(tmpPdata->memBuff , tmpPdata->perId  );
                    tmpPdata->memBuff = tmpPdata->memBuff - (TIME_STAMP_BYTES + GPIO_SUB_TOKEN_SIZE);    
                    int bytes = nn_send(pubSockFd, tmpPdata->FileMemBuff , (TIME_STAMP_BYTES + GPIO_VALUE_BYTES + GPIO_SUB_TOKEN_SIZE) , 0);
#if DEBUG
                    printf("Stream %d bytes \n",bytes);
#endif
                    tmpPdata->memBuff = tmpPdata->memBuff + GPIO_SUB_TOKEN_SIZE;
                }
#endif
                tmpPdata =tmpPdata->next ;
            }
        }
        if(pData->logType == MEMORY_LOG)
        {
            dumpDatatoMemory(pData);
        }
        pData->release(pData, (void*)(NULL));
    }
    return NULL;
}


