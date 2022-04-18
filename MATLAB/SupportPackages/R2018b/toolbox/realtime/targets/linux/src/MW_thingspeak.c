/* Copyright 2012-2016 The MathWorks, Inc.*/
#include "MW_thingspeak.h"
    #if !( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
    #include <sys/types.h>
    #include <sys/socket.h>
    #include <netinet/in.h>
    #include <arpa/inet.h>
    #include <unistd.h>
    #include <sys/wait.h>
    #include <netdb.h>
    #include <assert.h>
    #include <pthread.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <errno.h>
    #include <string.h>
    #include <signal.h>
    #include <ctype.h>
    #include <math.h>
    #include "rtwtypes.h"


    /* Local defines */
    #define URL_SIZE            (65)
    #define WRITE_API_KEY_SIZE  (33)
    #define HTTP_HEADER_SIZE    (175)
    #define FIELD_SIZE          (25+1)
    #define LOCATION_SIZE       (49)
    #define STATUS_SIZE         (32+1)
    #define NUM_FIELDS          (8)
    #define DATA_SIZE           (NUM_FIELDS*(FIELD_SIZE+1)+(LOCATION_SIZE+1)+(STATUS_SIZE+1))


    // One-time initialization
    void MW_initThingSpeak(
            const char *url, 
            const char *writeApiKey, 
            const uint32_T updateInterval,
            const boolean_T printDiagnosticMessages
            )
    {
        // Nothing to do here
    }

    // Return current time
    uint32_T MW_getCurrentTimeInMillis(void)
    {
        struct timespec ts;
        uint32_T ms;

        clock_gettime(CLOCK_MONOTONIC , &ts);
        ms = ts.tv_sec * 1000.0 + round(ts.tv_nsec / 1.0e6); 

        return (ms);
    }
    
    /* Time wiat function */
    void threadWait(TSReadData_t* TSReadDataPtr){
        
        struct timespec timeToWait;
        struct timeval now;
		double intPart, fractPart;
		
		fractPart = modf(TSReadDataPtr->sampleTime,&intPart);
        
        gettimeofday(&now,NULL);
        
        timeToWait.tv_sec = now.tv_sec+intPart;
        timeToWait.tv_nsec = (now.tv_usec)*1000UL + (fractPart*1000000000UL);
        
        pthread_mutex_lock(&TSReadDataPtr->readData_mutex);
        pthread_cond_timedwait(&TSReadDataPtr->readData_cond_mutex, &TSReadDataPtr->readData_mutex, &timeToWait);
        pthread_mutex_unlock(&TSReadDataPtr->readData_mutex);
        
    }
    
    /* 
     * Thread function to get thingSpeak data 
     */
    void* thingSpeakReadThread(void* threadArg){
        
        TSReadData_t *TSReadDataPtr =  (TSReadData_t*)threadArg;
        CURLcode resp;
        
#ifdef PRINT_DEBUG_MESSAGES
        char buff[100];
        time_t now;
#endif
		
        while(1){
            if(TSReadDataPtr->curl_handle){
                /*Perform the request*/
                resp = curl_easy_perform(TSReadDataPtr->curl_handle);
                curl_easy_getinfo(TSReadDataPtr->curl_handle,CURLINFO_RESPONSE_CODE,&TSReadDataPtr->httpResponse);
                
#ifdef PRINT_DEBUG_MESSAGES
                now = time(0);
                strftime(buff,sizeof(buff),"%Y-%m-%d %H:%M:%S.000",localtime(&now));
                fprintf(stdout,"%s :: %s\n",buff,curl_easy_strerror(resp));
                fflush(stdout);           
#endif
                
                if(resp != CURLE_OK){
                    perror("curl_easy_perform failed");
                }
            }
            else{
                TSReadDataPtr->httpResponse = -1;
                perror("curl_easy_perform failed invalid curl handle");
            }
            
            threadWait(TSReadDataPtr);
        }
        
    }
    
    /* Callback function to write data to a memory space 
     * from the curl result 
     */
    size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp)
    {
        TSReadData_t *TSReadDataPtr = (TSReadData_t *)userp;
        TSReadChunk_t *mem = (TSReadChunk_t *)&TSReadDataPtr->dataRead;
        
        size_t realsize = size * nmemb;
        
        if(mem->dataReceived != NULL){
            free(mem->dataReceived); 
        }
        
        mem->dataReceived = (char *)malloc(realsize + 1);
        if(mem->dataReceived == NULL) {
             printf("not enough memory (realloc returned NULL)\n");
             return 0;
        }
        
        memcpy(mem->dataReceived, contents, realsize);
        //mem->dataReceived[mem->size] = 0;
        mem->size = realsize;
        
        return realsize;
    }
    
    void MW_int2string(int channelNum, char *channelNumStr){
        sprintf(channelNumStr,"%d",channelNum);
    }
    
    /* 
     * Initialize TS read obj
     */
    TSReadData_t *MW_TSRead_init(
            const char *TSReadUrl,
			const double sampleTime){
        
        pthread_t tid;
        pthread_attr_t attr;
        
        TSReadData_t *TSReadDataPtr;
        TSReadDataPtr = (TSReadData_t *)malloc(sizeof(TSReadData_t));
        if(TSReadDataPtr == NULL){
            perror("Cannot allocate memory for ThingSpeak Read block.");
            return NULL;
        }
        
        if(pthread_mutex_init(&TSReadDataPtr->readData_mutex, NULL) != 0){
            perror("Error in initializing mutex");
            return NULL;
        }
        
        if(pthread_cond_init(&TSReadDataPtr->readData_cond_mutex, NULL) != 0){
            perror("Error in initializing mutex");
            return NULL;
        }
        
        TSReadDataPtr->dataRead.size = 0;
        TSReadDataPtr->dataRead.dataReceived = NULL;
		
		/* Use thread wait as half of sample time*/
		TSReadDataPtr->sampleTime = sampleTime/2;
        
        curl_global_init(CURL_GLOBAL_ALL);
        TSReadDataPtr->curl_handle = curl_easy_init();
        curl_easy_setopt(TSReadDataPtr->curl_handle, CURLOPT_URL, TSReadUrl);
        curl_easy_setopt(TSReadDataPtr->curl_handle, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
        curl_easy_setopt(TSReadDataPtr->curl_handle, CURLOPT_WRITEDATA, (void *)TSReadDataPtr);
        curl_easy_setopt(TSReadDataPtr->curl_handle, CURLOPT_USERAGENT, "libcurl-agent/1.0");
        
        /* Create thread to collect TS data */
        pthread_attr_init(&attr);
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        pthread_create(&tid,&attr,&thingSpeakReadThread,TSReadDataPtr);
        pthread_attr_destroy(&attr);
        
        return TSReadDataPtr;
    }

    void MW_TSRead_step(TSReadData_t *TSReadDataPtr,float *data, int16_t *status){
        /* Read data from TSReadDataPtr */
        
        float readData;
        
        if(TSReadDataPtr->dataRead.dataReceived != NULL){
            readData = atof(TSReadDataPtr->dataRead.dataReceived);
        }
        else{
            readData = 0;
        }
        
        *status = (int16_t)TSReadDataPtr->httpResponse;
        *data = readData;
    }
    
    void MW_TS_terminate(TSReadData_t *TSReadDataPtr){
        
        if (TSReadDataPtr->dataRead.dataReceived != NULL){
            free(TSReadDataPtr->dataRead.dataReceived);
            TSReadDataPtr->dataRead.dataReceived = NULL;
        }
        
        if (TSReadDataPtr->curl_handle != NULL){
            curl_easy_cleanup(TSReadDataPtr->curl_handle);
        }
        
        curl_global_cleanup();
        
        if(TSReadDataPtr != NULL){
            free(TSReadDataPtr);
            TSReadDataPtr = NULL;
        }
            
    }
    
    // Initializes HTTP post string
    TSData_t *MW_startThingSpeak(
            const char *url,
            const char *writeAPIKey,
            const boolean_T printDiagnosticMessages)
    {
        TSData_t *ptr;

        // Memory allocated here is freed in httpPostThread
        ptr = (TSData_t *) malloc(sizeof(TSData_t));
        if (ptr == NULL) {
            perror("Cannot allocate memory for ThingSpeak Write block.");
            return NULL;
        }
        ptr->dataStr = (char *) malloc(DATA_SIZE);
        if (ptr->dataStr == NULL) {
            printf("Cannot allocate memory for ThingSpeak Write block.");
            free(ptr);
            return NULL;
        }
        ptr->headerSize = DATA_SIZE + 256 + strlen(writeAPIKey) + strlen(url);
        ptr->header = (char *) malloc(ptr->headerSize);
        if (ptr->header == NULL) {
            free(ptr->dataStr);
            free(ptr);
            printf("Cannot allocate memory for ThingSpeak Write block.");
            return NULL;
        }
        ptr->dataStr[0] = '\0';
        ptr->header[0]  = '\0';
        ptr->url = NULL;
        ptr->printDiagnosticMessages = printDiagnosticMessages;

        return ptr;
    }

    // Adds a data field to the HTTP post string
    void MW_addField(TSData_t *ptr, const real_T data, const uint8_T fieldNo)
    {
        if (ptr != NULL) {
            // 7 (field1=) + 10 (digits) + 1 (decimal point) + 6 (digits) + 1 (&)
            // 25 chars
            char buf[FIELD_SIZE+1] = {'\0'};

            snprintf(buf, sizeof(buf), "field%d=%0.6f&", fieldNo, data);
            strncat(ptr->dataStr, buf, ptr->headerSize);
        }
    }

    // Adds location information to the HTTP post string
    void MW_addLocation(TSData_t *ptr, const real_T *location)
    {
        if (ptr != NULL) {
            //4 (lat=) + 1+2+1+6 (digits) + 5 (long=) + 1+3+1+6 (digits) + 10 (elevation=) + 5+1+2 (meters) + terminator
            // 49 chars
            char buf[LOCATION_SIZE+1] = {'\0'};

            snprintf(buf, sizeof(buf), "lat=%0.6f&long=%0.6f&elevation=%0.2f&",
                    location[0], location[1], location[2]);
            strncat(ptr->dataStr, buf, ptr->headerSize);
        }
    }

    // Adds a status message to the HTTP post string
    void MW_addStatus(TSData_t *ptr, const char *statusMessage)
    {
        if (ptr != NULL) {
            // status message is 32 chars max
            char buf[STATUS_SIZE+1] = {'\0'};

            snprintf(buf, sizeof(buf), "status=%s", statusMessage);
            strncat(ptr->dataStr, buf, ptr->headerSize);
        }
    }


    #ifdef _CURL_AVAILABLE_

    static void *httpPostThread(void *args)
    {
        TSData_t *ptr;
        int ret;

        // Detach thread from parent
        pthread_detach(pthread_self());

        // Get post string
        ptr = (TSData_t *)args;
        ret = system(ptr->header);
        if (ptr->printDiagnosticMessages && (ret < 0)) {
            printf("Error executing system command. "
                    "Call to curl for HTTP post has failed.");
        }
        if (ptr->header) {
            free(ptr->header);
        }
        if (ptr->dataStr) {
            free(ptr->dataStr);
        }
        free(ptr);
    }


    // Send data to ThingSpeak using curl
    void MW_postThingSpeak(
            TSData_t *ptr,
            const char *url,
            const char *writeAPIKey,
            const boolean_T printDiagnosticMessages)
    {
        char *cmd;
        int strSize;
        pthread_t thread;

        // Check if there is any pending error
        if (ptr == NULL) {
            return;
        }

        // Construct curl command
        if (ptr->printDiagnosticMessages) {
            snprintf(ptr->header, ptr->headerSize,
                    "echo \"ThingSpeak response: `curl --silent --request POST "
                    "--header \"X-THINGSPEAKAPIKEY: %s\" "
                    "--data \"%s\" "
                    "\"%s\"`\"",
                    writeAPIKey,
                    ptr->dataStr,
                    url);
        }
        else {
            snprintf(ptr->header, ptr->headerSize,
                    "curl --silent --request POST "
                    "--header \"X-THINGSPEAKAPIKEY: %s\" "
                    "--data \"%s\" "
                    "\"%s\" &> /dev/null",
                    writeAPIKey,
                    ptr->dataStr,
                    url);
        }

        // Create a thread to handle HTTP post. We do not wait until
        // system command is executed.
        if (pthread_create(&thread, NULL, httpPostThread, (void *)ptr) != 0) {
            perror("Cannot create HTTP post thread.");
        }
    }

    #else

    static void *httpPostThread(void *args)
    {
        TSData_t *ptr;
        ssize_t n = 0;
        int sock;

        // Detach thread from parent
        pthread_detach(pthread_self());

        // HTTP post
        ptr = (TSData_t *)args;
        sock = clientConnect(ptr->url);
        if (sock > 0) {
            write(sock, ptr->header, strlen(ptr->header));
            while ((n = read(sock, ptr->header, sizeof(ptr->headerSize))) > 0) {
                if (ptr->printDiagnosticMessages) {
                    ptr->dataStr[n] = '\0';
                    printf("%s", ptr->dataStr);
                }
            }
            close(sock);
        }
        else {
            if (ptr->printDiagnosticMessages) {
                printf("Cannot connect to the ThingSpeak server.\n");
            }
        }

        // Free memory allocated at the call site
        if (ptr->header) {
            free(ptr->header);
        }
        if (ptr->dataStr) {
            free(ptr->dataStr);
        }
        if (ptr->url) {
            free(ptr->url);
        }
        free(ptr);
    }

    // Connect to a TCP-client
    static int clientConnect(const char *url)
    {
        int sock;
        struct sockaddr_in servAddr;

        /* Open a TCP socket to connect to the online service */
        sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (sock < 0) {
            return -1;
        }
        memset(&servAddr, 0, sizeof(servAddr));
        servAddr.sin_addr.s_addr = inet_addr(url);
        servAddr.sin_family      = AF_INET;
        servAddr.sin_port        = htons(80);
        /* Connect to the server */
        if (connect(sock, (struct sockaddr *) &servAddr, sizeof(servAddr)) < 0) {
            return -1;
        }

        return sock;
    }

    // Send data to ThingSpeak
    void MW_postThingSpeak(
            TSData_t *ptr, 
            const char *url,
            const char *writeAPIKey,
            const boolean_T printDiagnosticMessages)
    {
        TSData_t *ptr;
        int strSize;
        pthread_t thread;

        // Memory allocated here is freed in httpPostThread
        ptr->url = (char *) malloc(strlen(url)+1);
        if (ptr->url == NULL) {
            perror("Cannot allocate memory for ThingSpeak Write block.");
            return;
        }
        ptr->printDiagnosticMessages = printDiagnosticMessages;

        // Create HTTP post message. Message length is about 175 chars
        snprintf(ptr->header, ptr->headerSize,
                "POST /update HTTP/1.1\r\n"
                "Host: api.thingspeak.com\r\n"
                "Connection: close\r\n"
                "X-THINGSPEAKAPIKEY: %s\r\n"
                "Content-type: application/x-www-form-urlencoded\r\n"
                "Content-length: %d\r\n\r\n"
                "%s", writeApiKey, 
                strlen(ptr->dataStr), 
                ptr->dataStr);

        // Create a thread to handle HTTP post
        if (pthread_create(&thread, NULL, httpPostThread, (void *)ptr) != 0) {
            perror("Cannot create HTTP post thread.");
        }
    }
    #endif // _CURL_AVAILABLE_

#endif

/* [EOF] */