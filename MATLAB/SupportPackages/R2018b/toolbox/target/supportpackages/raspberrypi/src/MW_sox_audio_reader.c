/* Copyright 2017 The MathWorks, Inc. */
#include "MW_sox_audio_reader.h"

static int32_T soxInitialized = 0;

static void printInfo(sox_format_t *in)
{
    printf("----------------\n");
    printf("File name = %s\n",in->filename);
    printf("Fp = %d\n",in->fp);
    printf("Length = %lu\n",in->olength);
    printf("seekable = %d\n",in->seekable);
    printf("Rate = %gHz\n",in->signal.rate);
    printf("Channels = %u, %u-bit\n",in->signal.channels,in->signal.precision);
    printf("Number of samples = %f\n",(double)(in->signal.length));
    printf("----------------\n");
}

sox_format_t * MW_sox_init(const uint8_T *fileName)
{
    sox_format_t *in = NULL;
    
    /* Initialize sox library */
    if (soxInitialized == 0) {
        if (sox_init() != SOX_SUCCESS) {
            perror("sox_init failed.");
            return NULL;
        }
        soxInitialized++;
    }
    
    /* Open input file */
    in = sox_open_read(fileName, NULL, NULL, NULL);
    if (in == NULL) {
        perror("sox_open_read failed.");
        return NULL;
    }
    printInfo(in);
    //*numSamples = (double)(in->signal.length / in->signal.channels);
    
    return in;
}

int32_T MW_sox_read(sox_format_t **in, int32_T *data, size_t count)
{
    size_t numRead;
    int32_T eof, k;
    static int sampleCount = 0;
	
	
    if (*in == NULL) {
        printf("MW_sox_read : invalid handle\n");
        return 1;
    }
    
    numRead = sox_read(*in, data, count);
    if (numRead != count) {
        // This probably means EOF
        eof = 1;
        {
            char *fileName = strdup((*in)->filename);
            
            sox_close(*in);
            *in = sox_open_read(fileName, NULL, NULL, NULL);
            free(fileName);
            if (*in == NULL) {
               perror("sox_open_read failed.");
               return -1;
            }
        }       
    } 
    else {
        eof = 0;
    }
    if (numRead != count) {
        memset((void *)(data + numRead),0x0,count - numRead);
    }
    
    return eof;
}    

int32_T MW_sox_terminate(sox_format_t *in)
{
    if (in != NULL) { 
        sox_close(in);
        printf("sox_close()\n");
    }
    
    if ((--soxInitialized) == 0) {
        sox_quit();
 printf("sox_quit()\n");
    }
    
    return 0;
}
//[EOF]