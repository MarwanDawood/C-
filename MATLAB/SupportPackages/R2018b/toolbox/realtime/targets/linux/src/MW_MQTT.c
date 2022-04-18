/* MW_MQTT.c
 * Copyright 2018 The MathWorks, Inc.
 */

#include "MW_MQTT.h"

#ifdef __MW_TARGET_USE_HARDWARE_RESOURCES_H__
#include "MW_target_hardware_resources.h"
#endif

#define ARRAY_SIZE  10
#define MAX_MATCHES 1
#define CLIENTIDLEN 128
#define INITIALMALLOC 128
#define REALLOCVAL  128

/*Global variables*/
static uint8_t connThreadLaunched = 0;
static pthread_mutex_t connect_mutex;
static pthread_cond_t connect_cv;
static MQTTAsync client;
static SubscribeInfo subscribeInfoInfoArray[ARRAY_SIZE];
static int subscribeID = -1;


/*Functions*/
/*
 * createMsgQ
 * Register the new subscriber block and create subscribeID.
 * Create a new message queue for the subscriber and save the queue id
 * to the subscribeInfoInfoArray.
 * Return the subscribeID
 */
static int createMsgQ(void){
    int qid = 0;
    subscribeID++;
    if (subscribeID < ARRAY_SIZE){
        
        LOG(LOG_INFO,"Create message queue for the subscriber %d \n",subscribeID);
        qid = msgget(IPC_PRIVATE, MSGPERM|IPC_CREAT|IPC_EXCL);
        
        if (qid < 0){
            LOG(LOG_INFO,"Error in creating msg queue. errno = %d \n",errno);
            return -1;
        }
        
        subscribeInfoInfoArray[subscribeID].msgqid = qid;
        LOG(LOG_INFO,"Created message queue for subscriber %d ,q = %d\n",subscribeID,qid);
        return subscribeID;
    }
    LOG(LOG_INFO,"Cannot create msg q. array size exceeded. subscribeId = %d\n",subscribeID);
    return -1;
}

/*
 * MW_MQTT_msgarrvd
 * Callback function that will get triggered when message arrives
 * Search the receive topic through subscribeInfoInfoArray and identify 
 * the message queue. Pass the message to the queue so that it can be read 
 * during each step call of the subscriber.
 * Return the 0 on success 
 */
int MW_MQTT_msgarrvd(void *context, char *topicName, int topicLen, MQTTAsync_message *message){
    LOG(LOG_INFO,"Received msg. \n");
    LOG(LOG_INFO,"Received msg.context: %s TopicLen: %d, Topic :%s Msg Len :%d \n",(char*)context,topicLen,topicName,message->payloadlen);
    
    char* dataPayload;
    
    /* Send message to the queue */
    int rc = 0,msgqid,numSubscribers,i;
    msg_t msg;
    regmatch_t matches[MAX_MATCHES];
    
    /*subscribeID indicates total number of subscribe blocks*/
    numSubscribers = subscribeID;
    
    /*Search with regular expressoions and find which queue */
    for(i=0; i <= numSubscribers; i++){
        if(regexec(&subscribeInfoInfoArray[i].topicRegExp, topicName, MAX_MATCHES, matches, 0) == 0) {
            /*Topic matched*/
            LOG(LOG_INFO,"Subscriber : %d, Topic : %s MATCHED sending msg to the queue\n", i, subscribeInfoInfoArray[i].topicStr);
            dataPayload = (char*)calloc(message->payloadlen,sizeof(char*));
            
            /* Copy to a local buffer to remove extra chars*/
            memcpy(dataPayload,(char*)message->payload,message->payloadlen);
            
            /* Send message to the queue in the format [TOPIC DATA] */
            msg.mtype = 1;
            sprintf(msg.mtext, "%s %s",topicName,dataPayload);
            
            rc = msgsnd(subscribeInfoInfoArray[i].msgqid, &msg, sizeof(msg.mtext), 0);
            if (rc < 0){
                LOG(LOG_INFO,"Error in sending msg to the queue. errno = %d \n",errno);
            }
            else{
                LOG(LOG_INFO,"sent message to the queue\n");
            } 
            free(dataPayload);
        }
        else{
            /*No match */
            LOG(LOG_INFO,"Subscriber : %d, Topic : %s NO MATCH\n",i,subscribeInfoInfoArray[i].topicStr);
        }
    }

    MQTTAsync_freeMessage(&message);
    MQTTAsync_free(topicName);
    return 1;
}

/*
 * MW_MQTT_connLost
 * Callback function that will get triggered when connection is lost.
 * Send signal to wakeup brokerConnectionHandler thread which will 
 * reestablish connection to the broker.
 */
void MW_MQTT_connLost(void *context, char *cause){
    LOG(LOG_INFO,"Connection lost. Cause : %s \n",cause);
    pthread_mutex_lock(&connect_mutex);
    LOG(LOG_INFO,"Connection lost. Send signal to connection thread\n");
    pthread_cond_signal(&connect_cv);
    pthread_mutex_unlock(&connect_mutex);
    LOG(LOG_INFO,"Connection lost. End of MW_MQTT_connLost callback.\n");
}

/*
 * MW_MQTT_onConnect
 * Callback function that will get triggered connection got established.
 * Subscribe to all the topics as per the registered subscribe blocks.
 */
void MW_MQTT_onConnect(void* context, MQTTAsync_successData* response){
    LOG(LOG_INFO,"Client connection successfull. context : %s \n",context);
    int rc = -1,i;
    int subscriberConfigured = subscribeID;
    MQTTAsync_responseOptions ropts = MQTTAsync_responseOptions_initializer;
    
    /*Subscribe for all configured one */
    LOG(LOG_INFO,"Number of subscribers : %d\n",subscriberConfigured);
    for(i=0;i <= subscriberConfigured; i++){
        rc = MQTTAsync_subscribe(client, subscribeInfoInfoArray[i].topicStr, 0, &ropts);
        if (rc < 0){
            LOG(LOG_INFO,"Failed to subscribe rc = %d \n",rc);
        }
        else{
            LOG(LOG_INFO,"Subscribe SUCCESS rc = %d \n",rc);
        }
    }
}

/*
 * brokerConn_handler
 * Background thread which will try to establish connection to the borker.
 */
void *brokerConn_handler(void *input){
    LOG(LOG_INFO,"brokerConn_handler : start \n");
    
    MQTTAsync_connectOptions conn_opts = MQTTAsync_connectOptions_initializer;
    char clientID[CLIENTIDLEN], hostName[CLIENTIDLEN];
    
    /* Make the MQTT client ready for connection to the broker */
    memset(hostName,0,CLIENTIDLEN*sizeof(char*));
    
    /* Use Broker address, Username, Password and ClientID configured in 
     * Simulink hardware config set
     */
    if (strlen(MW_TOSTRING(MW_MQTT_CLIENTID)) > 0){
        sprintf(clientID,"%s",MW_TOSTRING(MW_MQTT_CLIENTID));
    }
    else{
        LOG(LOG_INFO,"Client ID not set. Use hostname of Raspberry Pi \n");
        gethostname(hostName, CLIENTIDLEN);
        srand(time(0));
        sprintf(clientID,"%s_%d",hostName,rand());
        LOG(LOG_INFO,"Client ID : %s\n",clientID);
    }
    
    if (strlen(MW_TOSTRING(MW_MQTT_BROKERADDRESS)) > 0){
        MQTTAsync_create(&client, MW_TOSTRING(MW_MQTT_BROKERADDRESS), clientID, MQTTCLIENT_PERSISTENCE_NONE, NULL);
    }
    else{
        perror("Cannot get broker address \n");
    }
    
    /* Configure connection options and register callback functions */
    conn_opts.cleansession = 1;
    conn_opts.onSuccess = MW_MQTT_onConnect;
    conn_opts.context = client;
    
    /* Leave Username and password empty if not configured in config set */
    /*If password is set and username is empty, use a template value.
     * This is required for ThingSpeak mqtt connection
     */
    if (strlen(MW_TOSTRING(MW_MQTT_PASSWORD)) > 0) {
        conn_opts.password = MW_TOSTRING(MW_MQTT_PASSWORD);
        
        if (strlen(MW_TOSTRING(MW_MQTT_USERNAME)) > 0){
            conn_opts.username = MW_TOSTRING(MW_MQTT_USERNAME);
        }
        else{
            conn_opts.username = "username";
        }
    }
    
    /* Set callback functions */
    MQTTAsync_setCallbacks(client,NULL,MW_MQTT_connLost,MW_MQTT_msgarrvd, NULL);
    
    /*Connection loop*/
    while(1){
        LOG(LOG_INFO,"brokerConn_handler: while loop running \n");
        if (MQTTAsync_connect(client, &conn_opts) == MQTTASYNC_SUCCESS){
            LOG(LOG_INFO,"MQTTClient_connect : MQTTASYNC_SUCCESS \n");
            /* Use pthread wait to pause the execution of this thread */
            pthread_mutex_lock(&connect_mutex);
            LOG(LOG_INFO,"MQTTClient_connect : pthread cond wait \n");
            pthread_cond_wait(&connect_cv,&connect_mutex);
            LOG(LOG_INFO,"MQTTClient_connect : pthread wake from sleep \n");
            pthread_mutex_unlock(&connect_mutex);
        }
        else{
            LOG(LOG_INFO,"MQTTClient_connect : Failed to connect. Retry after 1 sec.\n");
            sleep(1);
        }
    }
}

void MW_MQTT_onSubscribe(void* context, MQTTAsync_successData* response){
    /*Callback function for Subscribe success */
    LOG(LOG_INFO,"MW_MQTT_onSubscribe callback, context : %s \n",context);
    /* TO DO: Use filtered subscribing methods */
}

void MW_MQTT_onSubscribeFailure(void* context, MQTTAsync_failureData* response){
    /*Callback function for Subscribe success */
    LOG(LOG_INFO,"MW_MQTT_onSubscribeFailure callback, context : %s \n",context);
    /* TO DO: Use filtered subscribing methods */
}

/*
 * MW_MQTT_subscribeTopic
 * Subscribe to the topic corresponding to the id passed.
 * Returns 0 on success
 */
int MW_MQTT_subscribeTopic(int id){
    int rc = 0;
    MQTTAsync_responseOptions ropts = MQTTAsync_responseOptions_initializer;
    char* topicStr = subscribeInfoInfoArray[id].topicStr;
    
    /*TO DO: Check if this callbacks are required */
    ropts.onSuccess = MW_MQTT_onSubscribe;
    ropts.onFailure = MW_MQTT_onSubscribeFailure;
    ropts.context = topicStr;
    
    rc = MQTTAsync_subscribe(client, topicStr, 0, &ropts);
    
    if(rc < 0 ){
        LOG(LOG_INFO,"MQTTAsync_subscribe ID = %d: FAILED : \n",id);
        return -1;
    }
    else{
        LOG(LOG_INFO,"MQTTAsync_subscribe ID = %d: SUCCESS\n",id);
    }
    return 0;
}


/*
 * MW_MQTT_setup
 * Common setup function for publish and subscribe blocks.
 * Launch the connection thread - brokerConnectionHandler if required.
 * Returns 0 on success.
 */
int MW_MQTT_setup(){
    pthread_t tid;
    
    /* TO DO: Move the log set to a different location */
    setlogmask (LOG_UPTO(LOG_INFO));
    
    LOG(LOG_INFO,"MW_MQTT_setup : Check if connection thread is launched\n");
    if(connThreadLaunched){
        /* No need to proceed */
        LOG(LOG_INFO,"MW_MQTT_setup : Thread already launched. No need to proceed\n");
        return 0;
    }
    else{
        /* Launch connection thread and connect to MQTT broker */
        LOG(LOG_INFO,"MW_MQTT_setup : Launch connection thread and connect to MQTT broker\n");
        pthread_mutex_init(&connect_mutex,NULL);
        pthread_cond_init(&connect_cv,NULL);
        pthread_create(&tid,NULL,brokerConn_handler,NULL);
        connThreadLaunched = 1;
    }
    return 0;
}

/*
 * MW_MQTT_publish_setup
 * Setup function for the publish block.
 * No checks required. Directly call the common function MW_MQTT_setup()
 */
int MW_MQTT_publish_setup(){
    /* Launch connection thread */
    return MW_MQTT_setup();
}

/*
 * MW_MQTT_subscribe_setup
 * Setup function for the subscribe block.
 * No checks required. Directly call the common function MW_MQTT_setup()
 */
int MW_MQTT_subscribe_setup(char* topicStr, char* topicRegExp, uint16_t* subID){
    /* Create queue */
    LOG(LOG_INFO,"Subscribe setup start\n");
    int id = 0,rc = 0;;
    id = createMsgQ();
    *subID = (uint16_t)id;
    
    /*Save the topic to global array */
    sprintf(subscribeInfoInfoArray[id].topicStr,"%s",topicStr);
    LOG(LOG_INFO,"Saved topicstr to global array : %s \n",subscribeInfoInfoArray[id].topicStr);
    
    /*Save compiled topic regular expression to match in MW_MQTT_msgarrvd */
    rc = regcomp(&subscribeInfoInfoArray[id].topicRegExp,topicRegExp,REG_EXTENDED);
    if (rc != 0){
        LOG(LOG_INFO,"ERROR in creating compilled regular exp for topic str : %s \n",topicRegExp);
        /*Cannot proceed. Exit the process */
        exit(0);
    }
    else{
        LOG(LOG_INFO,"Saved compiled topic regular expression to global array : %s \n",topicRegExp);
    }
    
    /* Create connection handler thread */
    MW_MQTT_setup();
    
    /* Subscribe to the topic if connection is already established*/
    if (MQTTAsync_isConnected(client)){
        LOG(LOG_INFO,"client already connected. Subscribe to topic\n");
        MW_MQTT_subscribeTopic(id);
    }
    else{
        LOG(LOG_INFO,"client NOT connected. Skip subscribe for now\n");
    }
    
    LOG(LOG_INFO,"Subscribe setup END\n");
}


/*
 * MW_MQTT_subscribe_step
 * Step function for the subscribe block.
 * Read message from the queue. SubscribeID created during setup will be 
 * used to access the global array. Get the message queue id from the global 
 * array and use it to read messages from the queue. 'isNew' flag will be set to
 * TRUE if new message is available in the queue. 
 */
int MW_MQTT_subscribe_step(uint16_t id, uint16_t msgLen, uint8_t* isNew, double* msg, char* topicStr){
    LOG(LOG_INFO,"subscribe function start, id = %d\n",id);
    int rc = 0,i = 0;
    msg_t msgS;
    char* dataStr = NULL;
    char* token = NULL;
    char* dataStrOrig;
    
    dataStr = (char*)calloc(MSGTXTLEN,sizeof(char*));
    if(!dataStr){
        LOG(LOG_INFO,"Calloc failed\n");
        exit(0);
    }
    /*Save the orig to call free */
    dataStrOrig = dataStrOrig;
    
    rc = msgrcv(subscribeInfoInfoArray[id].msgqid, &msgS, sizeof(msgS.mtext), 0, IPC_NOWAIT);
    if (rc < 0){
        LOG(LOG_INFO,"msgrcv failed. rc = %d\n",rc);
        *isNew = 0;
        LOG(LOG_INFO,"returning MW_MQTT_subscribe_step. isNew = %d \n",*isNew);
        return -1;
    }
    
    *isNew = 1;
    LOG(LOG_INFO,"msgrcv SUCCESS. msg = %s \n",msgS.mtext);
    /*Extract topic and data */
    /*Clear topic and message fields */
    memset(topicStr,0,MAXTOPICLEN);
    memset(msg,0,msgLen*sizeof(double));
    
    rc = sscanf(msgS.mtext,"%s %[^\n]s",topicStr,dataStr);
    LOG(LOG_INFO,"Extracted data. rc = %d topicStr = %s, dataStr = %s\n",rc,topicStr,dataStr);
    
    /* Extract data array elements form the data string */
    while ((token = strtok_r(dataStr," ",&dataStr))){
        *(msg + i) = (double)atof(token);
        i++;
        LOG(LOG_INFO,"Extracted number = %0.5f \n",(double)atof(token));
        if (i == msgLen)
            break;
    }
    
    free(dataStrOrig);
    LOG(LOG_INFO,"MW_MQTT_subscribe_step End\n");
    return 0;
}

/*
 * MW_MQTT_publish_step
 * Step function for the publish block.
 * Set the message payload as the string generated and set the QoS value.
 * Value for status output port will be the return of MQTTAsync_sendMessage()
 */
int MW_MQTT_publish_step(int retainFlag, int QoSVal, uint32_t msgLen, char** msgPayload, char* topic, int8_t* status){
    LOG(LOG_INFO,"MW_MQTT_step : start\n");
    /* MQTTAsync_message type is provided by the MQTT library and is 
     * defined in MQTTAsync.h
     */
    MQTTAsync_message mqttMsg = MQTTAsync_message_initializer;
    
    LOG(LOG_INFO,"Message to publish: %s, len = %d, topic = %s, qos = %d, retainFalg =%d\n",*msgPayload, msgLen, topic, QoSVal,retainFlag);
    mqttMsg.payload = (void*)*msgPayload;
    mqttMsg.payloadlen = msgLen;
    mqttMsg.qos = QoSVal;
    mqttMsg.retained = retainFlag;
    
    /*Publish message */
    int publishReturn = 0;
    publishReturn = MQTTAsync_sendMessage(client, topic, &mqttMsg, NULL);
    LOG(LOG_INFO,"MQTTAsync_sendMessage : return = %d \n",publishReturn);
    if (publishReturn < 0){
        LOG(LOG_INFO,"MQTTAsync_sendMessage : failed to publish\n");
    }
    else{
        LOG(LOG_INFO,"MQTTAsync_sendMessage : MQTTCLIENT_SUCCESS\n");
    }
    *status = publishReturn;
    
    /*Free the memorry allocated for message string */
    free(*msgPayload);
    return 0;
}

/*
 * MW_sprintf_mqtt
 * To create payload string based on input data type
 * Input array elements will be converted to string array
 */
void MW_sprintf_mqtt(MW_MQTT_Data_Type inDataType, uint32_t dataLen, void* dataIn,char** payLoadStr, uint32_t* datStrLen){
    uint32_t arraySize = 0,index = 0,i;
    
    LOG(LOG_INFO," call calloc and initialize\n");
    /*Initial memory allocation */
    *payLoadStr = (char *)calloc(INITIALMALLOC,sizeof(char*));
    arraySize = INITIALMALLOC;
    //memset(payLoadStr,0,INITIALMALLOC*sizeof(payLoadStr));
    
    LOG(LOG_INFO,"Use input array elements to generate payload string, inDataType = %d\n",inDataType);
    /*Use input array elements to generate payload string*/
    for(i=0;i<dataLen;i++){
        switch (inDataType){
            case MW_MQTT_I8:
                LOG(LOG_INFO,"in loop,MW_MQTT_I8 dataIn = %d\n",*((int8_t*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%d ",*((int8_t*)dataIn + i));
                break;
            case MW_MQTT_UI8:
                LOG(LOG_INFO,"in loop,MW_MQTT_UI8 dataIn = %d\n",*((uint8_t*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%d ",*((uint8_t*)dataIn + i));
                break;
            case MW_MQTT_I16:
                LOG(LOG_INFO,"in loop,MW_MQTT_I16 dataIn = %d\n",*((int16_t*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%d ",*((int16_t*)dataIn + i));
                break;
            case MW_MQTT_UI16:
                LOG(LOG_INFO,"in loop,MW_MQTT_UI16 dataIn = %d\n",*((uint16_t*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%d ",*((uint16_t*)dataIn + i));
                break;
            case MW_MQTT_I32:
                LOG(LOG_INFO,"in loop,MW_MQTT_I32 dataIn = %d\n",*((int32_t*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%d ",*((int32_t*)dataIn + i));
                break;
            case MW_MQTT_UI32:
                LOG(LOG_INFO,"in loop,MW_MQTT_UI32 dataIn = %d\n",*((uint32_t*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%d ",*((uint32_t*)dataIn + i));
                break;
            case MW_MQTT_I64:
                LOG(LOG_INFO,"in loop,MW_MQTT_I64 dataIn = %d\n",*((int64_t*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%d ",*((int64_t*)dataIn + i));
                break;
            case MW_MQTT_UI64:
                LOG(LOG_INFO,"in loop,MW_MQTT_UI64 dataIn = %d\n",*((uint64_t*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%d ",*((uint64_t*)dataIn + i));
                break;
            case MW_MQTT_FLOAT:
                LOG(LOG_INFO,"in loop,MW_MQTT_FLOAT dataIn = %f\n",*((float*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%0.5f ",*((float*)dataIn + i));
                break;
            case MW_MQTT_DOUBLE:
                LOG(LOG_INFO,"in loop i = %d,MW_MQTT_DOUBLE dataIn = %f\n", i, *((double*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%0.5f ",*((double*)dataIn + i));
                break;
            default:
                LOG(LOG_INFO,"in loop,default dataIn = %d\n",*((int8_t*)dataIn + i));
                index += snprintf((*payLoadStr+index), arraySize-index, "%d ",*((int8_t*)dataIn + i));
                break;
        }
        
        LOG(LOG_INFO,"percentage complete = %f\n",ceil(100*index/arraySize));
        /*Realloc if index is more than 85% of array size*/
        if ((100*index/arraySize) > 85){
            LOG(LOG_INFO," 85% exceeded. Reallocate\n");
            *payLoadStr = (char *)realloc(*payLoadStr,(arraySize+REALLOCVAL)*sizeof(char*));
            arraySize += REALLOCVAL;
        }
    }
    LOG(LOG_INFO," generated string = %s\n",*payLoadStr);
    *datStrLen = index;
}



