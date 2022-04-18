/* Copyright 2018 The MathWorks, Inc. */
#ifndef _MW_MQTT_H_
#define _MW_MQTT_H_

/* TO DO : check rtwtypes.h*/
#include "rtwtypes.h"
#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    MW_MQTT_I8 = 0,
    MW_MQTT_UI8,
    MW_MQTT_I16,
    MW_MQTT_UI16,
    MW_MQTT_I32,
    MW_MQTT_UI32,
    MW_MQTT_I64,
    MW_MQTT_UI64,       
    MW_MQTT_FLOAT,
    MW_MQTT_DOUBLE,
} MW_MQTT_Data_Type;

#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
/* Used in rapid accelerator mode */
#define MW_MQTT_setup() (0)
#define MW_MQTT_publish_setup() (0)
#define MW_MQTT_subscribe_setup(topicStr, topicRegExp, subID) (0)
#define MW_MQTT_subscribe_step(id, msgLen, isNew, msg, topicStr)  (0)
#define MW_MQTT_publish_step(retainFlag, QoSVal, msgLen, msgPayload, topic, status)    (0)
#define MW_sprintf_mqtt(inDataType, dataLen, dataIn, payLoadStr, datStrLen)  (0)

#else 
    
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include <pthread.h>
#include <syslog.h>
#include <math.h>
#include <sys/msg.h>
#include <sys/errno.h>
#include <sys/types.h>
#include <regex.h>
#include <time.h>
#include <MQTTAsync.h>
    
/*#define DEBUG_SYSLOG (1)*/
    
#ifdef DEBUG_SYSLOG
#define LOG(LOG_LEVEL,message,args...) syslog(LOG_LEVEL,"%s(): "message,__func__,##args)
#else
#ifdef DEBUG_PRINTF
#define LOG(LOG_LEVEL,message,args...) printf(message,##args)
#else
#define LOG(LOG_LEVEL,message,args...)
#endif
#endif
    
extern int errno;       // error NO.
#define MSGPERM 0600    // msg queue permission
#define MAXARRAYSIZE 64 // max vector size supported
#define MAXELEMSIZE 17 // (significant+decimalPoint+mantiss+whiteSpace = 10+1+5+1)
#define MAXTOPICLEN 128 // max topic length
#define MSGTXTLEN ((MAXARRAYSIZE*MAXELEMSIZE) + MAXTOPICLEN + 1)   // msg text length

#define MW_STRINGIFY(x) #x
#define MW_TOSTRING(x) MW_STRINGIFY(x)

/* Data encapsulating subscribe details  */
typedef struct SubscribeInfo_tag {
    int msgqid;
    char topicStr[MAXTOPICLEN];
    regex_t topicRegExp;
} SubscribeInfo;

typedef struct msg_buf {
   long mtype;
   char mtext[MSGTXTLEN];
} msg_t;


/* function declarations */
static int createMsgQ(void);
int MW_MQTT_msgarrvd(void *context, char *topicName, int topicLen, MQTTAsync_message *message);
void MW_MQTT_connLost(void *context, char *cause);
void MW_MQTT_onConnect(void* context, MQTTAsync_successData* response);
void *brokerConn_handler(void *input);
void MW_MQTT_onSubscribe(void* context, MQTTAsync_successData* response);
void MW_MQTT_onSubscribeFailure(void* context, MQTTAsync_failureData* response);
int MW_MQTT_subscribeTopic(int id);
int MW_MQTT_setup();
int MW_MQTT_publish_setup();
int MW_MQTT_subscribe_setup(char* topicStr, char* topicRegExp, uint16_t* subID);
int MW_MQTT_subscribe_step(uint16_t id, uint16_t msgLen, uint8_t* isNew, double* msg, char* topicStr);
int MW_MQTT_publish_step(int retainFlag, int QoSVal, uint32_t msgLen, char** msgPayload, char* topic, int8_t* status);
void MW_sprintf_mqtt(MW_MQTT_Data_Type inDataType, uint32_t dataLen, void* dataIn,char** payLoadStr, uint32_t* datStrLen);

		
#endif

#ifdef __cplusplus
}
#endif
#endif


