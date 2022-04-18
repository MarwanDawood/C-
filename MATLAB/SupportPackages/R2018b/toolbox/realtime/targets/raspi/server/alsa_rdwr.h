/* Copyright 2018 The MathWorks, Inc. */
#ifndef ALSA_RD_WR_H
#define  ALSA_RD_WR_H
#ifdef __WIN32__
#else
#include <alsa/asoundlib.h>
#endif

typedef unsigned char uint8_t;

#define ALSA_PCM_NEW_HW_PARAMS_API
#define ALSA_PCM_NEW_SW_PARAMS_API
#define PLAYBACK      1
#define CAPTURE       0

struct audioHandleData{
    snd_pcm_t *cHandleG;
    snd_pcm_uframes_t bufferSize;
    snd_pcm_uframes_t  periodSize;
    snd_pcm_uframes_t  cPeriodSizeG;
    uint8_t  *cFramesG;
    unsigned int periodTime;
    unsigned int bufferTime;
    snd_pcm_uframes_t  cBufferSize;
};        

extern void * audiorecordthread( void *arg );
extern int32_t pcminit(unsigned int,unsigned short, char *,short, struct audioHandleData *);
extern int32_t pcmwritebuf(snd_pcm_t *handle, int8_t *ptr, int32_t cptr);
extern long pcmreadbuf(snd_pcm_t *handle, uint8_t *buf, long len);
extern int checkDevice( char *);
extern void  pcmexit( struct audioHandleData *);

#endif                          /* ALSA_RD_WR_H  */
