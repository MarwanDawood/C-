/* Copyright 2018 The MathWorks, Inc. */
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <errno.h>
#ifdef NANOMSG_TRANSPORT
#include <nanomsg/nn.h>
#include <nanomsg/reqrep.h>
#include <nanomsg/pubsub.h>
#include <sys/wait.h>
#endif
#include <alsa/asoundlib.h>
#include "common.h"
#include "alsa_rdwr.h"
#include "handler.h"
#include "AudioRecorder.h"
#include "recorder.h"
#define AUDIO_SUB_TOKEN_SIZE    11


struct timespec audioStartTimel;
/* Audio Read process  call back function */
short  audioRead(void *args, int offt)
{
    struct audioHandleData *audioData = (struct audioHandleData *)args;
    pcmreadbuf(audioData->cHandleG, &audioData->cFramesG[offt], audioData->cPeriodSizeG); 
    return 0;
}

/* Audio release function  */
void releaseAudio(void *args, void *audarg)
{

    struct peripheralData *pData = (struct peripheralData *)args;
    struct audioHandleData *audioData = (struct audioHandleData *)audarg;
    pData->startCaptureFlag = STOP;
    /* Deallocate memory allocated for capture frame */
    if(audioData->cFramesG != NULL)
    {
        pcmexit(audioData);
        free(audioData->cFramesG);
        audioData->cFramesG = NULL;
        free(audioData);
    }
    /* close file pointer used for audio log file */
    if(pData->fprd != NULL)
    {
        /* Restet the capture flag and session flag */
        //pData->startCaptureFlag = STOP;
        fclose(pData->fprd);
        pData->fprd = NULL;
    }
    pData->totalTimeExpired = 0;
}

/* Audio initialization cal back function  */
int initializeAudio(void *args, void *audioarg)
{
    struct audioHandleData *audioData = (struct audioHandleData *)audioarg;
    struct peripheralData *pData = (struct peripheralData *)args;
    /* Call pcmi nit for audi device initialization */
    int ret = pcminit(pData->hInfo.frameLen , pData->hInfo.sampleRate , pData->audioCard , pData->logType , audioData );
    /* if non zero value is returned by pcminit reset the total remaining time and device available flag and  come out of capture loop */
    if(ret != 0)    {
        //pData->totalTimeExpired = (pData->totTime)*1000000;
        pData->totalTimeExpired = (pData->totTime)*MILLION;
        deviceAvailableflag = AUDIO_DEVICE_NOT_AVAILABLE;
        perror("Error PCMINIT:-");    
    }else {   /* if zero  is returned by pcminit then set the avilable device flag and set the total remaing time */
#if DEBUG
        printf(" Audio PCMinit done");
#endif
        pData->totalTimeExpired = (pData->totTime)*MILLION;
        deviceAvailableflag = AUDIO_DEVICE_AVAILABLE;
    }
    /* Initalize call back function for audio read and audio release */
    pData->capture = audioRead;
    pData->release = releaseAudio;
    return ret;
}

void writeAudioHeaderInfo(struct peripheralData *pData)
{
    int err;
    char buff[30];
    unsigned long long tmpTime;
    /* Writting file version number in to header information */
    sprintf(pData->hInfo.version,"VER.%d.%d", 1, 1);
    pData->hInfo.recordDuration = (short)(pData->totTime);

    sprintf(buff, "/tmp/audio%d_log_message.bin", pData->perId);
    pData->fprd  = fopen(buff, "wb");
    if(pData->fprd == NULL)
        perror("audio fd creation failed \n");
    err = fwrite(&(pData->hInfo), sizeof(struct headerInfo), 1, pData->fprd);
    if(err > 0)
    {
#if DEBUG
        printf("Audio file writting %d bytes\n",err);
#endif
    }else    {
        perror(" Audio file write error:");
    }
    if(clock_gettime( CLOCK_REALTIME , &audioStartTimel ) == -1 ) {
        perror( "clock gettime" );
        exit( EXIT_FAILURE );
    }
    tmpTime = (long long )audioStartTimel.tv_sec*BILLION + ( long long )audioStartTimel.tv_nsec;
    err = fwrite(&tmpTime, sizeof(unsigned long long), 1, pData->fprd);
    if(err > 0)
    {
#if DEBUG
        printf("Audio file writting %d bytes\n",err);
#endif
    }else    {
        perror("Audio file write error:");
    }
}
void allocateAudioMemory(struct peripheralData *pData, struct audioHandleData *audioData)
{
    if(pData->logType == MEMORY_LOG)
    {
        audioData->cFramesG = malloc((snd_pcm_frames_to_bytes(audioData->cHandleG, audioData->cPeriodSizeG)+(TIME_STAMP_BYTES))*(pData->totTime*(1000)/((pData->hInfo.frameLen*1000)/pData->hInfo.sampleRate)));    
        if (audioData->cFramesG == NULL)
            //cFramesG = malloc(snd_pcm_frames_to_bytes(cHandleG, cPeriodSizeG)*(pData->totTime*(1000000)/100000)*8);
            if (audioData->cFramesG == NULL)
            {
                perror(" capture Allocating memory failed");
            }
    }
    else if(pData->logType == DIRECT_LOG)
    {
        audioData->cFramesG = malloc(snd_pcm_frames_to_bytes(audioData->cHandleG, audioData->cPeriodSizeG));
        if (audioData->cFramesG == NULL)
        {
            perror("Allocating memory failed\n");
        }
    }
    else if(pData->logType == STREAM) 
    {
        audioData->cFramesG = malloc(snd_pcm_frames_to_bytes(audioData->cHandleG, audioData->cPeriodSizeG)+(11 + TIME_STAMP_BYTES));
        if (audioData->cFramesG == NULL)
        {
            perror("Allocating memory failed\n");
        }
    }
}

/* Audio Recording thread */
void *audioRecordThread(void *Data )
{
	
    struct peripheralData *pData = (struct peripheralData *)Data;
    int32_t err, len;
    unsigned long long diff ;
    struct timespec currTstampl ;
    int memOffset;
    float pTime = ((float)pData->hInfo.frameLen/(float)pData->hInfo.sampleRate);
    struct audioHandleData *audioData = NULL;
    //    struct peripheralData *pData = (struct peripheralData *)arg;
    err = pthread_detach( pthread_self());
    if(err == 0)
    {
#if DEBUG
        printf("Audio pthread_detach successfull\n");
#endif
    }
    else
    {
        perror("UDP pthread error:");
    }
    while(pData->startSessionFlag == START){
        waitForStartRecordEvent();
        if (checkResourceEnable(pData)!= ENABLE )
        {
            pData->startCaptureFlag = STOP;    /* Making start capture flag 0 */
            continue;
        }
        if(pData->startSessionFlag == STOP)
            break;
        writeAudioHeaderInfo(pData);
        audioData = malloc(sizeof(struct audioHandleData));
        audioData->periodTime = (unsigned int)(pTime*MILLION);
        pData->initialize = initializeAudio;
        /* initialize function  will return zero on success and nonzero value on failure */
        pData->initialize(pData, audioData);
        allocateAudioMemory(pData, audioData);
        if(pData->logType == MEMORY_LOG)
        {
            memOffset = 0; 

        }
#if NANOMSG_TRANSPORT
        else if(pData->logType == STREAM)
        {
            /* Allocate 16 bytes for intial token, Relative Time and gpio State Value */
            sprintf((char *)audioData->cFramesG,"Audio%d|", pData->hInfo.sampleRate);
            audioData->cFramesG = audioData->cFramesG + AUDIO_SUB_TOKEN_SIZE; 
        }
#endif
#if DEBUG
        printf("period time:%d,  starting remaining time:%llu , start capture flag:%d \n " , audioData->periodTime  , pData->totalTimeExpired , pData->startCaptureFlag );
#endif
        /* Continue the loop until total capture time expiration or until stop command recieved from client */
        while((pData->totalTimeExpired > 0 ) && ( pData->startCaptureFlag == START))
        {
            /* Convert frames in bytes for a PCM. */
            len =  snd_pcm_frames_to_bytes(audioData->cHandleG, audioData->cPeriodSizeG);
#if DEBUG
            printf("***returned by snd pcm frms to bytes %d\n ", len);    
#endif
            if(clock_gettime( CLOCK_REALTIME , &currTstampl) == -1 ) 
            {
                perror("clock gettime \n");
                exit(EXIT_FAILURE);
            }
            if(pData->logType == MEMORY_LOG)
            {
                audioData->cFramesG[memOffset] = timeDiff(&audioStartTimel, &currTstampl);
                memOffset = memOffset + TIME_STAMP_BYTES;
                pData->capture((void *)audioData, memOffset);
                memOffset = memOffset + len;
            }else if(pData->logType == DIRECT_LOG)        {
                diff = timeDiff(&audioStartTimel, &currTstampl);
                pData->capture((void *)audioData, 0);
                fwrite(&diff  , sizeof(unsigned long long), 1, pData->fprd);
                fwrite(audioData->cFramesG, 1, len, pData->fprd );
                fflush(pData->fprd);
            }
#ifdef NANOMSG_TRANSPORT
            else if(pData->logType == STREAM )
            {
                *((unsigned long long *)audioData->cFramesG) = timeDiff(&audioStartTimel, &currTstampl);
                audioData->cFramesG = audioData->cFramesG + TIME_STAMP_BYTES;
                pData->capture((void *)audioData,0);
                audioData->cFramesG = audioData->cFramesG - ( TIME_STAMP_BYTES + AUDIO_SUB_TOKEN_SIZE) ;
                int bytes = nn_send(pubSockFd, audioData->cFramesG , snd_pcm_frames_to_bytes(audioData->cHandleG, audioData->cPeriodSizeG)+(AUDIO_SUB_TOKEN_SIZE + TIME_STAMP_BYTES) , 0);
                if(bytes < 0 )
                    perror("Error while publishing data \n");    
                audioData->cFramesG = audioData->cFramesG + AUDIO_SUB_TOKEN_SIZE;

            }
#endif
            else{
                perror(" Unsupported Log type \n");
            }

            err = snd_pcm_wait(audioData->cHandleG, ((audioData->periodTime/1000)*2));  /* wait for the samples from codec */
            if(err > 0)
            {
#if DEBUG
                printf(" pcm_wait succ \n");
#endif
            }else    {
                perror(" snd_pcm_wait error:");
            }
            pData->totalTimeExpired = pData->totalTimeExpired -audioData->periodTime;
        }
        pData->startCaptureFlag = STOP;    /* Making start capture flag 0 */
        int memWriteData = memOffset;
        memOffset = 0;

        if(pData->logType == MEMORY_LOG)
        {
            fwrite(&audioData->cFramesG[memOffset], memWriteData, 1, pData->fprd);
            fflush(pData->fprd);
        }
#ifdef NANOMSG_TRANSPORT
        else if(pData->logType == STREAM )
        {
            audioData->cFramesG = audioData->cFramesG-AUDIO_SUB_TOKEN_SIZE;
        }
#endif
        pData->release(pData,audioData);
    }
    return NULL;
}

