#ifndef _MW_THINGSPEAK_H_
#define _MW_THINGSPEAK_H_

#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
/*no includes required */
#else
#include <curl/curl.h>
#endif

#include "rtwtypes.h"
#ifdef __cplusplus
extern "C" {
#endif
    
#define _CURL_AVAILABLE_

typedef struct {
    char *header;
    char *dataStr;
    char *url;
    uint32_T headerSize;
    boolean_T printDiagnosticMessages;
} TSData_t;

#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
#define TSReadData_t void
#else
typedef struct {
    char *dataReceived;
    size_t size;
} TSReadChunk_t;
        
typedef struct {
    CURL *curl_handle;
    int httpResponse;
	double sampleTime;
    TSReadChunk_t dataRead;
    pthread_mutex_t readData_mutex;
    pthread_cond_t readData_cond_mutex;
} TSReadData_t;
#endif

#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
 #define MW_initThingSpeak(url, writeAPIKey, updateInterval, printDiagnosticMessages) 
 #define MW_getCurrentTimeInMillis() (0)
 #define MW_startThingSpeak(url, writeAPIKey, printDiagnosticMessages) (NULL)
 #define MW_addField(ptr, data, fieldNo)
 #define MW_addLocation(ptr, location) 
 #define MW_addStatus(ptr, statusMessage)
 #define MW_postThingSpeak(ptr, url, writeAPIKey, printDiagnosticMessages)
 #define MW_TSRead_init(handle,readTime) 0
 #define MW_TS_terminate(handle)
 #define MW_TSRead_step(handle,data,status)
 #define MW_int2string(channelNum,channelNumStr)
#else
void MW_initThingSpeak(
        const char *url,
        const char *writeAPIKey,
        const uint32_T updateInterval,
        const boolean_T printDiagnosticMessages);
uint32_T MW_getCurrentTimeInMillis(void);
TSData_t *MW_startThingSpeak(
        const char *url,
        const char *writeAPIKey,
        const boolean_T printDiagnosticMessages);
void MW_addField(TSData_t *ptr, const real_T data, const uint8_T fieldNo);
void MW_addLocation(TSData_t *ptr, const real_T *location);
void MW_addStatus(TSData_t *ptr, const char *statusMessage);
void MW_postThingSpeak(
        TSData_t *ptr,
        const char *url,
        const char *writeAPIKey,
        const boolean_T printDiagnosticMessages);
TSReadData_t *MW_TSRead_init(
        const char *url,
        const double sampleTime);
void MW_TSRead_step(TSReadData_t *TSReadDataPtr,
        float *data, 
        int16_t *status);
void MW_TS_terminate(TSReadData_t *TSReadDataPtr);
void MW_int2string(int channelNum, char *channelNumStr);
        
#endif

#ifdef __cplusplus
}
#endif
#endif

