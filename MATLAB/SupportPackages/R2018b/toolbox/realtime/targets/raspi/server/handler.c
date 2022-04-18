// Copyright 2013-2018 The MathWorks, Inc.
#include <stdio.h>
#ifdef __WIN32__
#include <winsock2.h>
#define MSG_MORE 0
#else
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/syscall.h>
#include <sys/resource.h>
#endif
#ifdef NANOMSG_TRANSPORT
#include <nanomsg/nn.h>
#include <nanomsg/reqrep.h>
#include <nanomsg/pubsub.h>
#include <assert.h>
#endif
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include "common.h"
#include "handler.h"
#include "LED.h"
#include "GPIO.h"
#include "I2C.h"
#include "SPI.h"
#include "serial.h"
#include "picam.h"
#include "system.h"
#include "auth.h"
#include "v4l2_cam.h"
#include "joystick.h"
#include "devices.h"
#include "frameBuffer.h"
#include "MW_pigs.h"
#include "TimerBasedRecorder.h"
#include "UdpRecorder.h"
#include "AudioRecorder.h"

#ifndef __WIN32__  
#include "alsa_rdwr.h"
#endif
/* Defines */
#define REQ_MAX_PAYLOAD_SIZE  (16 * 1024)
#define RESP_MAX_PAYLOAD_SIZE (16 * 1024)
#define MAX_USERNAME_LEN      (32)
#ifdef NANOMSG_TRANSPORT
#define AUTHORIZATION_TIMEOUT (300)
#else
#define AUTHORIZATION_TIMEOUT (10)
#endif
#define NO_OF_AUDIO_PLAY      (30)

#define RASPIBOARD      1

#define TIMERBASEDCAPTURE      1
#define EVENTBASEDCAPTURE      2
#define AUDIOCAPTURE           3
/* Receive timeout time in milliseconds */
#define RCVTIMEOUT           10000 

/* Type definitions */
typedef struct {
	uint32_T id;
	uint32_T sequence;
	uint32_T payloadSize;
} REQUEST_Header_t;

typedef struct {
	REQUEST_Header_t request;
	char data[REQ_MAX_PAYLOAD_SIZE];
} REQUEST_t;


typedef struct {
	uint32_T status;
	uint32_T sequence;
	uint32_T payloadSize;
} RESPONSE_Header_t;

typedef struct {
	RESPONSE_Header_t response;
	char *data;
	unsigned int dataSize;
	unsigned int dataReallocCount;
} RESPONSE_t;

struct threadData  *head =NULL ;

pthread_cond_t countCond;
pthread_mutex_t countLock;

/* Check for audio device avialability */
int deviceAvailableflag;
int pubSockFd = -1 ;
short int status,nofile=0;

/* Last processed sequence ID */
int lastSeq = -1;

// A timeout of 0 makes socket blocking again
#ifndef NANOMSG_TRANSPORT 
static int setSockRecvTimeout(int sock, long int timeoutInSec)
{
	int ret;
	struct timeval tv;
	tv.tv_sec  = timeoutInSec; 
	tv.tv_usec = 0;  
	ret = setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, 
			(const void *)&tv, sizeof(struct timeval));

	return ret;
}
#endif

/* Receive requested number of bytes 
 * Return -3 if connection is closed by the client
 * Return -1 on recieve timeout
 * Return -2 on new client request
 * Return +ve value on valid or invalid command request */
static int sockRecv(int sock, char *req, int size) 
{

#ifdef NANOMSG_TRANSPORT
	int32_T recvd = 0 , totalBytesRead=0 ;
	while (recvd < size)
	{
		totalBytesRead = nn_recv(sock, (char *)req, sizeof(REQUEST_t) , 0); 
		if (totalBytesRead < 0) {
			perror("Recv()");
			return -1;
		}
		else if (strcmp(req, "cl closed")==0) { /* Socket closed by peer */
			return -3;
		}
		else if (strncmp(req, "Hello pi", totalBytesRead) == 0) { /* New Client Request */
			return -2;
		}
		recvd += totalBytesRead;
	}

#else
	int32_T ret, recvd;
	char *buff = req;    
	recvd = 0;
	while (recvd < size) {
		ret = recv(sock, buff + recvd, size, 0);
		if (ret < 0) {
			perror("Recv()");
			return -1;
		}
		else if (ret == 0) { /* Socket closed by peer */
			break;
		}
		recvd += ret;
	}
#endif
	return(recvd);
}

/* Send requested amount of data */
#ifndef NANOMSG_TRANSPORT 
static int sockSend(int sock, char *buff, int size, int flags) 
{
	int sent;

	while (size > 0) {
		sent = send(sock, buff, size, flags);
		if (sent == -1) {
			perror("Send(): ");
			return -1;
		}
		buff += sent;
		size -= sent;
	}

	return 0;
}
#endif

static inline int sendResponse(int sock, RESPONSE_t *resp)
{
#ifdef NANOMSG_TRANSPORT
	int sent, ret ;
	// Sending  header and no payload 
	if (resp->response.payloadSize == 0) {
		sent = nn_send(sock, (char *)resp , sizeof(RESPONSE_Header_t) , 0 );
		if (sent == -1) {
			perror("Sending failed ():\n ");
			return -1;
		}
	}else {
		/* sending response header and payload */
		struct nn_msghdr hdr;
		struct nn_iovec iov [2];
		iov [0].iov_base = (unsigned char *)resp ;
		iov [0].iov_len = sizeof(RESPONSE_Header_t);
		iov [1].iov_base = (unsigned char *)resp->data  ;
		iov [1].iov_len = resp->response.payloadSize ;
		memset (&hdr, 0, sizeof (hdr));
		hdr.msg_iov = iov;
		hdr.msg_iovlen = 2 ;
		ret = nn_sendmsg(sock, &hdr , 0);
		if(ret <=0 )
			perror("Error while sending response to client:");
	}

#else
	int ret;

	// Send header
	if (resp->response.payloadSize == 0) {
		ret = sockSend(sock, (char *)resp, sizeof(RESPONSE_Header_t), 0);
		if (ret < 0) {
			return -1;
		}
	}
	else {
		ret = sockSend(sock, (char *)resp, sizeof(RESPONSE_Header_t), MSG_MORE);
		if (ret < 0) {
			return -1;
		}

		// Send payload
		ret = sockSend(sock, resp->data, resp->response.payloadSize, 0);
		if (ret < 0) {
			return -1;
		}
	}
#endif
	return 0;
}

static inline int receiveRequest(int sock, REQUEST_t *req)
{
	int ret =0;
#ifdef NANOMSG_TRANSPORT
	ret = sockRecv(sock, (char*)req, sizeof(REQUEST_Header_t));
	LOG_PRINT(stdout, "REQ = [%d, %d, %d]\n", req->request.id, req->request.sequence, req->request.payloadSize);
	if (ret <= 0) {
		switch(ret)
		{
			/* If connection closed by the peer */
			case -3:
				nn_shutdown(sock, 0);
				return ret;
				break;
			default:
				return ret;
		}
	}
#else
	ret = sockRecv(sock, (char *)&(req->request), sizeof(REQUEST_Header_t));
	if (ret <= 0) {
		return -1;
	}
	LOG_PRINT(stdout, "REQ = [%d, %d, %d]\n", req->request.id,
			req->request.sequence, req->request.payloadSize);

	// Read the message header and check validity
	if (req->request.payloadSize > REQ_MAX_PAYLOAD_SIZE) {
		fprintf(stderr, "Bad message: msg = [%d, %d]\n",
				req->request.id, req->request.payloadSize);
		return -1;
	}

	// Read the data that goes with the message
	if (req->request.payloadSize != 0) {
		ret = sockRecv(sock, (char *)&(req->data), req->request.payloadSize);
		if (ret < 0) {
			perror("Recv()");
			return -1;
		}
#if DEBUG
		printf("data recieved from command is :%d      %d  \n",(*(req->data)),(*((req->data+4))));
#endif
	}
#endif
	return 0;
}

// Increase the size of data buffer if needed
static int reallocRespData(RESPONSE_t *resp, const unsigned int newDataSize)
{
	if (resp->dataSize < newDataSize) {
		char *ptr;
		ptr = (char *)realloc((void *)resp->data, newDataSize);
		if (ptr == NULL) { 
			return -1;
		}  
		resp->data = ptr;
		resp->dataSize = newDataSize;
	}
	resp->dataReallocCount += 1;

	return 0;
}

static void setStatusResponse(RESPONSE_t *resp, REQUEST_t *req, int32_T status)
{
	resp->response.sequence    = req->request.sequence;
	resp->response.status      = status;
	resp->response.payloadSize = 0;
}

static int deallocRespData(RESPONSE_t *resp)
{
    resp->dataReallocCount -= 1;
    // For the case when cameraboard was properly terminted before
    if (resp->dataReallocCount == -1){
        resp->dataReallocCount = 0;
        return 0;
    }
    if (resp->dataReallocCount == 0) {
        char *ptr;
        ptr = (char *)realloc((void *)resp->data, RESP_MAX_PAYLOAD_SIZE);
        if (ptr == NULL) {
            return -1;
        }
        resp->data = ptr;
        resp->dataSize = RESP_MAX_PAYLOAD_SIZE;
    }

	return 0;
}

/** Function to calculate the time differnece.
 * startTime is the pointer to startTime structure.
 * stopTime is the pointer to structure storing end time.
 **/
unsigned long long  timeDiff(struct timespec *startTime, struct timespec *stopTime)
{
	unsigned long long  diff;
	diff= (unsigned long long)(( stopTime->tv_sec - startTime->tv_sec )*1000000000ull + ( stopTime->tv_nsec - startTime->tv_nsec ));
	return diff;

}

struct threadData  *createCaptureNode(void)
{
	struct threadData *newNode= NULL,  *currentNode = NULL  ;
	newNode = (struct threadData*)malloc(sizeof(struct threadData));
	if(newNode == NULL)
	{
		perror("error in new node memory allocation\n");
	}
	newNode->next = NULL;
	memset(newNode, 0, sizeof(struct threadData));
	/* Memory allocation for the peripehral data structure of the new node */
	newNode->pData = malloc(sizeof(struct peripheralData));
	if(newNode->pData == NULL){
		perror("Error in new node->pData memory allocation\n");
	}else{

		memset(newNode->pData, 0, sizeof(struct peripheralData));
#if DEBUG
		printf("memeory allocated done for pdata\n");
#endif
	}
	if(head == NULL){
		head = newNode;
		currentNode = newNode;
	}else {
		currentNode = head;
		while(currentNode->next != NULL)
		{
			currentNode = currentNode->next;
		}
		currentNode->next = newNode;
	}
	return newNode ;
}


int updateSourceInfo(struct peripheralData *pData , char *payload  )
{
	unsigned char *capType = (unsigned char *) payload;
	unsigned char  *groupingFlag = (unsigned char *) (payload + sizeof(unsigned short) +  sizeof(unsigned int) + sizeof(unsigned int)); 
	pData->fprd = NULL;
	pData->enableFlag = DISABLE;
	pData->startSessionFlag = START;
	pData->startCaptureFlag = 0 ;
	pData->isGroupRequired= *groupingFlag ; 
	pData->next = NULL;
	switch(*capType)
	{
		case TIMERBASEDCAPTURE:
			{
				unsigned int *id = (unsigned int *) (payload + sizeof(unsigned short));
				unsigned int *sampleTime = (unsigned int *) (payload  + sizeof(unsigned short) + sizeof(unsigned int));
				pData->timerPeriod = (*sampleTime );
				pData->perId = ( *id );
				pData->hInfo.header =  RASPIBOARD;
				pData->hInfo.peritype = *capType;
				pData->hInfo.gpioNo =  (*id);
				pData->hInfo.sampleTime = ( *sampleTime )/1000;
				pData->startSessionFlag = START;
				pData->startCaptureFlag = STOP;

			} 
			break;
		case EVENTBASEDCAPTURE:
			{
				unsigned int *udpPort=(unsigned int *)(payload + sizeof(unsigned short));
				pData->hInfo.header =  RASPIBOARD;
				pData->hInfo.peritype = *capType;
				pData->udpPort = *udpPort;
				pData->perId = *udpPort;
				pData->fprd = NULL;
				pData->enableFlag = DISABLE;
				pData->startSessionFlag = START;
				pData->startCaptureFlag = STOP ;

			} 
			break;
		case AUDIOCAPTURE:
			{
				unsigned short *sampleRate = (unsigned short *) (payload + sizeof(unsigned short ));
				unsigned int *samplesPerFrame =(unsigned int *) (payload + sizeof(unsigned short ) + sizeof(unsigned int));
				unsigned short  *card = ((unsigned short *) payload);
				unsigned char cardType = (*card)>>8;
				pData->hInfo.header =  RASPIBOARD;
				pData->hInfo.peritype = *capType;
				pData->perId = cardType;
				pData->hInfo.gpioNo = cardType;
				pData->hInfo.sampleRate = *sampleRate ;
				pData->hInfo.frameLen = *samplesPerFrame;
				pData->fprd = NULL;
				pData->enableFlag = DISABLE;
				pData->startSessionFlag = START;
				pData->startCaptureFlag = STOP ;
				sprintf(pData->audioCard, "plughw:%d,0", cardType);
			} 
			break;
	}
	return 0;
}


void executeCommand(REQUEST_t *req, RESPONSE_t *resp)
{
	int ret;

	switch (req->request.id) {
		case REQUEST_ECHO:
			{
				char *incoming = req->data;
				char *outgoing = resp->data;

				/* Response */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = 0;
				resp->response.payloadSize = req->request.payloadSize;
				memcpy(outgoing, incoming, req->request.payloadSize);
			}
			break;
		case REQUEST_VERSION:
			{
				uint32_T *payload = (uint32_T *) resp->data;
				/* Response */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = 0;
				resp->response.payloadSize = 3 * sizeof(uint32_T);
				payload[0] = __MATLAB_SERVER_VERSION_YEAR;
				payload[1] = __MATLAB_SERVER_VERSION_REL;
				payload[2] = __MATLAB_SERVER_VERSION_BUILD;
			}
			break;
		case REQUEST_LED_GET_TRIGGER:
			{
				// extern int EXT_LED_getTrigger(const unsigned int id, char *trigger)
				unsigned int *id = (unsigned int *) req->data;
				unsigned int readSize = resp->dataSize;
				char *trigger = resp->data;
				ret = EXT_LED_getTrigger(*id, trigger, readSize);
				LOG_PRINT(stdout, "REQUEST_LED_GET_TRIGGER: LED(%d).trigger => '%s'\n", *id, trigger);
				/* Response */
				resp->response.sequence = req->request.sequence;
				resp->response.status   = ret;
				if (ret < 0) {
					resp->response.payloadSize = 0;
				}
				else {
					resp->response.payloadSize = strlen(trigger);
				}
			}
			break;

		case REQUEST_LED_SET_TRIGGER:
			{
				// extern int EXT_LED_setTrigger(const unsigned int id, const char *trigger)
				unsigned int *id = (unsigned int *) req->data;
				char *trigger = req->data + sizeof(unsigned int);

				// Add a C-string termination character just in case
				LOG_PRINT(stdout, "REQUEST_LED_SET_TRIGGER: LED(%d).trigger <= '%s'\n", *id, trigger);
				trigger[req->request.payloadSize - sizeof(unsigned int)] = 0;
				ret = EXT_LED_setTrigger(*id, trigger);

				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_LED_WRITE:
			{
				// extern int EXT_LED_write(const unsigned int id, const boolean_T value)
				unsigned int *id = (unsigned int *) req->data;
				boolean_T *value = (boolean_T *) (req->data + sizeof(unsigned int));

				LOG_PRINT(stdout, "REQUEST_LED_WRITE: LED(%d).value <= %d\n", *id, *value);
				ret = EXT_LED_write(*id, *value);

				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_GPIO_INIT:
			{
				// int EXT_GPIO_init(unsigned int gpio, boolean_T direction)
				unsigned int *gpio = (unsigned int *) req->data;
				uint8_T *direction = (uint8_T *) (req->data + sizeof(unsigned int));

				LOG_PRINT(stdout, "REQUEST_GPIO_INIT: GPIO(%d).direction <= %d\n", *gpio, *direction);
				ret = EXT_GPIO_init(*gpio, *direction);
				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_GPIO_TERMINATE:
			{
				// int EXT_GPIO_terminate(unsigned int gpio)
				unsigned int *gpio = (unsigned int *) req->data;
				LOG_PRINT(stdout, "REQUEST_GPIO_TERMINATE: GPIO(%d)\n", *gpio);
				ret = EXT_GPIO_terminate(*gpio);
				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_GPIO_READ:
			{
				// int EXT_GPIO_read(unsigned int gpio, boolean_T *value)
				unsigned int *gpio = (unsigned int *) req->data;
				boolean_T *value = (boolean_T *) (resp->data);
				LOG_PRINT(stdout, "REQUEST_GPIO_READ: GPIO(%d)\n", *gpio);
				ret = EXT_GPIO_read(*gpio, value);
				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				if (ret == 0) {
					resp->response.payloadSize = sizeof(boolean_T);
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_AVAILABLE_RESOURCES:
			{
				FILE *fp;
				char tempBuff[500];
				int  offst = 0;
				char *payload = (char *) resp->data;
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = 100;    
				/* Response value for available resource request */
				char *video = "AVAILABLE VIDEO DEVICES: \n";
				char *twi = "AVAILABLE I2C: ";
				char *spi = "AVAILABLE SPI: ";
				char *audiocap = "\nAVAILABLE AUDIO CAPTURE DEVICES: ";
				char *audioplay = "AVAILABLE AUDIO PLAYBACK DEVICES: ";
				char *serial = "AVAILABLE SERIAL PORTS: ";
				char *twiaddr = "AVAILABLE 12c slave addresses are: \n";

				/* Check available  I2C bus */
				memcpy(payload+offst, twi, strlen(twi)+1);
				offst = offst+strlen(twi);

				fp = popen("ls  -C /dev/i2c*", "r");
				if(fp == NULL)
				{
					perror("Failed to run i2c check command\n" );
				}
				fgets(tempBuff,40 ,fp);
				{
					memcpy(payload+offst, tempBuff , strlen(tempBuff)+1 );
					offst = offst + strlen(tempBuff);
				}
				pclose(fp);    

				/* Check available of Spi bus */
				memcpy(payload+offst, spi, strlen(spi)+1);
				offst=offst+strlen(spi);

				fp = popen("ls  -C /dev/spi*", "r");
				if(fp == NULL)
				{
					perror("Failed to run video check command\n" );
				}
				while(fgets(tempBuff,40 ,fp)!= NULL)
				{
					memcpy(payload+offst, tempBuff , strlen(tempBuff)+1 );
					offst = offst+strlen(tempBuff);
				}
				pclose(fp);

				/* Check available  video devices */
				int offt=0;
				memset(tempBuff, 0,strlen(tempBuff));    
				memcpy(payload+offst, video, strlen(video)+1);
				offst=offst+strlen(video);

				fp = popen("v4l2-ctl --list-devices", "r");
				if(fp == NULL)
				{
					perror("Failed to run video check command\n" );
				}
				offt=0;
				while(fgets(&tempBuff[offt],50 ,fp)!=NULL)
				{
					offt = strlen(tempBuff);

				}
				{
					memcpy(payload+offst, tempBuff , strlen(tempBuff)+1 );
					offst = offst+strlen(tempBuff);
				}
				pclose(fp);
				/* Check available audio capture  devices */
				memset(tempBuff, 0,strlen(tempBuff));    
				memcpy(payload+offst, audiocap, strlen(audiocap)+1);
				offst=offst+strlen(audiocap);

				fp = popen("arecord -l | grep card", "r");
				if(fp == NULL)
				{
					perror("Failed to run video check command\n" );
				}
				offt=0;
				while(fgets(&tempBuff[offt],75 ,fp)!=NULL)
				{
					offt = strlen(tempBuff);

				}
				memcpy(payload+offst, tempBuff , strlen(tempBuff)+1 );
				offst = offst+strlen(tempBuff);
				pclose(fp);

				/* Check available audio playback  devices */
				memset(tempBuff, 0,strlen(tempBuff));    
				memcpy(payload+offst, audioplay, strlen(audioplay)+1);
				offst=offst+strlen(audioplay);

				fp = popen("aplay -l | grep card", "r");
				if(fp == NULL)
				{
					perror("Failed to run video check command\n" );
				}
				offt=0;
				while(fgets(&tempBuff[offt],75 ,fp)!=NULL)
				{
					offt = strlen(tempBuff);

				}
				memcpy(payload+offst, tempBuff , strlen(tempBuff)+1 );
				offst = offst+strlen(tempBuff);
				pclose(fp);

				/* Check available serial port */
				memset(tempBuff, 0,strlen(tempBuff));    
				memcpy(payload+offst, serial, strlen(serial)+1);
				offst=offst+strlen(serial);

				fp = popen("ls /dev/ttyS*", "r");
				if(fp == NULL)
				{
					perror("Failed to run video check command\n" );
				}
				fgets(tempBuff,100 ,fp);
				{
					memcpy(payload+offst, tempBuff , strlen(tempBuff)+1 );
					offst = offst+strlen(tempBuff);
				}
				pclose(fp);
				/* Check available i2c devices  */
				memset(tempBuff, 0,strlen(tempBuff));    
				memcpy(payload+offst, twiaddr, strlen(twiaddr)+1);
				offst=offst+strlen(twiaddr);

				fp = popen("i2cdetect -y 1", "r");
				if(fp == NULL)
				{
					perror("Failed to run video check command\n" );
				}
				offt=0;
				while(fgets(&tempBuff[offt],50 ,fp)!=NULL)
				{
					offt = strlen(tempBuff);

				}
				{
					memcpy(payload+offst, tempBuff , strlen(tempBuff)+1 );
					offst = offst+strlen(tempBuff);
				}

				resp->response.payloadSize = (int32_T) strlen(payload)+1;
			}
			break;
		case REQUEST_SESSION_CREAT:
			{
				if(pthread_mutex_init( &countLock, NULL )!= 0)
					perror("MUTEX INIT: ");
				if(pthread_cond_init( &countCond, NULL ) != 0)
					perror("Condition  INIT");
				resp->response.sequence    = req->request.sequence;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_ADD_SOURCE:
			{
				struct threadData *current=NULL,*tmpNode=NULL ;
				unsigned char *captureType = (unsigned char *) req->data,   createNewThreadFlag=1  ;
				unsigned char  *groupingFlag = (unsigned char *) (req->data + sizeof(unsigned short) +  sizeof(unsigned int) + sizeof(unsigned int)); 

				if(*captureType == TIMERBASEDCAPTURE)
				{
					unsigned int *sampleTime = (unsigned int *) (req->data + sizeof(unsigned short) + sizeof(unsigned int));
					if(head != NULL)
					{
						tmpNode = head;
						while(tmpNode != NULL)
						{
							if((tmpNode->pData->timerPeriod  == *sampleTime) &&  (*groupingFlag ==1)  && ( tmpNode->pData->isGroupRequired == 1) ) 
							{
								struct peripheralData *tmp= tmpNode->pData;
								while(tmp->next !=NULL)
								{
									tmp = tmp->next;
								}    
								tmp->next = malloc(sizeof(struct peripheralData));
								if(tmp->next  == NULL)
									perror("Error in new pData memory allocation\n");
								updateSourceInfo(tmp->next ,  req->data );
								createNewThreadFlag = 0 ;
								resp->response.status   = STATUS_OK;
								break;
							}else {

								tmpNode = tmpNode->next ;
							}
						}
					}else{
						createNewThreadFlag = 1 ;
					}
					if(createNewThreadFlag){
						current =  createCaptureNode();
						updateSourceInfo(current->pData , req->data );
						if(head ==NULL)
							head = current;
						pthread_create(&current->tid, NULL, gpioRead, (void *)current->pData); /* Response: send status */
						resp->response.status   = STATUS_OK;
					}
				}else if(*captureType == EVENTBASEDCAPTURE)    {
					current = createCaptureNode();
					updateSourceInfo(current->pData , req->data );
					pthread_create(&current->tid , NULL,udpReadThread , (void *)current->pData); /* Response: send status */
					resp->response.status = STATUS_OK;
				}else if(*captureType == AUDIOCAPTURE)    {
					current = createCaptureNode();
					updateSourceInfo(current->pData , req->data );
#if DEBUG
					printf("************* %d \n", current->pData->perId );
					printf("************* Sample Time is %d   \n", current->pData->hInfo.sampleTime);
					printf("************* frameLen is %d   \n", current->pData->hInfo.frameLen);
#endif   
#ifndef __WIN32__         
					/* Check for Audio Device Availability */
					int ret = checkDevice(current->pData->audioCard);
					if(ret != 0){
						resp->response.status      = ERR_AUDIO_DEVICE_NOT_FOUND;
						deviceAvailableflag = AUDIO_DEVICE_NOT_AVAILABLE;
					}else {
						pthread_create(&current->tid, NULL, audioRecordThread , (void *)current->pData ); /* Response: send status */
						resp->response.status      = STATUS_OK;
						deviceAvailableflag = AUDIO_DEVICE_AVAILABLE;
					}
#endif    
				}else{
					perror("Wrong Capture Type\n");
				}

				resp->response.sequence    = req->request.sequence;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_DISABLE_SOURCE:
			{
				unsigned int *id = (unsigned int *) (req->data + sizeof(unsigned char));
				struct threadData *tmp;
				tmp = head;
				while(tmp != NULL)
				{
					if(tmp->pData->perId == *id)
					{
						if(tmp->pData->startCaptureFlag ==0)
						{
							tmp->pData->enableFlag = DISABLE;
							resp->response.status     = STATUS_OK;
							break;
						}
						else
						{
							resp->response.status     = ERR_CANT_DISABLE_SOURCE;
							break;
						}
					}
					else
					{
						tmp = tmp->next;
					}
				}
				resp->response.payloadSize = 0;
				resp->response.sequence    = req->request.sequence;
			}
			break;
		case REQUEST_ENABLE_SOURCE:
			{ 
				unsigned int *id = (unsigned int *) (req->data + sizeof(unsigned char));            
				struct threadData *tmp;
				tmp =head;
				while(tmp != NULL)
				{
					if(tmp->pData->perId == *id)
					{
						if(tmp->pData->startCaptureFlag == 0)    {
							tmp->pData->enableFlag = ENABLE;
							resp->response.status     = STATUS_OK;
							break;
						}else {
							resp->response.status     = ERR_CANT_ENABLE_SOURCE;
							break;
						}
					}else {
						tmp = tmp->next;
					}
				}
				resp->response.status     = STATUS_OK;
				resp->response.payloadSize = 0;
				resp->response.sequence    = req->request.sequence;
			}
			break;
		case REQUEST_ENABLE_ALL_SOURCE:
			{
				struct threadData *tmp;
				tmp =head;
				while(tmp != NULL)
				{

					if(tmp->pData->startCaptureFlag == 0)    {
						tmp->pData->enableFlag = ENABLE;
						resp->response.status     = STATUS_OK;
					}else{
						resp->response.status     = ERR_CANT_ENABLE_SOURCE;
						break;
					}
					tmp = tmp->next;    
				}
				resp->response.payloadSize = 0;
				resp->response.sequence    = req->request.sequence;
			}
			break;
		case REQUEST_DISABLE_ALL_SOURCE:
			{
				struct threadData *tmp;
				tmp = head;
				while(tmp != NULL){
					if(tmp->pData->startCaptureFlag == 0)    {
						tmp->pData->enableFlag = DISABLE;
						resp->response.status     = STATUS_OK;
						//break;
					}else {
						resp->response.status     = ERR_CANT_DISABLE_SOURCE;
						break;
					}
					tmp=tmp->next;
				}
				resp->response.payloadSize = 0;
				resp->response.sequence    = req->request.sequence;
			}
			break;
		case REQUEST_CAPTURE_START:
			{
				short *totalTime = (short *)(req->data);
				char logType = *((req->data) + (sizeof (short)));
				struct threadData *tmp = NULL;
				if(head != NULL)
				{
					tmp=head;
					while(tmp != NULL)
					{
						tmp->pData->startCaptureFlag = START;
						tmp->pData->totTime = *totalTime;
						tmp->pData->logType = logType;
						tmp->pData->startCaptureFlag = START;
						tmp=tmp->next;
					}
#ifdef NANOMSG_TRANSPORT
					if(pubSockFd <= 0)
					{
						if(head->pData->logType == 3)
						{
							pubSockFd = nn_socket(AF_SP, NN_PUB);
							assert (pubSockFd >= 0);
							assert (nn_bind (pubSockFd , SERVER_URL) >= 0);
						}
					}
#endif      
					pthread_cond_broadcast( &countCond );
					resp->response.status   = STATUS_OK;
				}
				else
				{
					resp->response.status = ERR_SETUP_SOURCE_NOT_DONE;
				}
				resp->response.sequence    = req->request.sequence;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_SESSION_STATUS:
			{

				uint32_T *payload = (uint32_T *) resp->data;
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = STATUS_OK;
				resp->response.payloadSize = sizeof(uint32_T);
				*payload         = (head->pData->totalTimeExpired);
			}
			break;
		case REQUEST_CAPTURE_STOP:
			{
				struct threadData *tmp = NULL;
				int CaptureNotStarted = 0 ;    
				/* Check if sesion is created or not */
				if(head!=NULL)
				{
					tmp = head;
					while(tmp!=NULL)
					{
						if(tmp->pData->enableFlag != ENABLE) 
							tmp=tmp->next;
						else{ 
							tmp->pData->startCaptureFlag = STOP ;
							tmp=tmp->next;
							CaptureNotStarted=1;
						}
					}
					if(CaptureNotStarted == 0 )    

						resp->response.status      = ERR_CAPTURE_IS_NOT_STARTED;
				}else
				{
					/* If sesion is not created then return return session not created response */
					resp->response.status      = ERR_SETUP_SOURCE_NOT_DONE;
				}
				resp->response.sequence    = req->request.sequence;
				resp->response.payloadSize = 0;    
			}
			break;
		case REQUEST_SESSION_RELEASE:
			{
				struct threadData *tmp;
				/* Handle for the case if session is not created and user destroy the capture class object */    
				if(head != NULL){
					tmp = head;
					while(tmp != NULL){
						tmp->pData->startSessionFlag = 0;
						tmp->pData->startCaptureFlag = 0;
						tmp = tmp->next;
					}
					pthread_cond_broadcast( &countCond );
#ifndef __WIN32__ 
					sleep(2);
#endif
				}else{
					resp->response.sequence    = req->request.sequence;
					resp->response.status      = STATUS_OK;
					resp->response.payloadSize = 0;
					break;
				}
				tmp =head;
				while(tmp != NULL){
					head = tmp->next;
					free(tmp->pData);
					free(tmp);
					tmp = head;

				}
				int ret = pthread_cond_destroy(&countCond);
				if(ret != 0){
					perror("Destroy condition variable fail");
				}
				ret = pthread_mutex_destroy(&countLock);
				if(ret != 0){
					perror("Destroy mutex variable fail");
				}
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = STATUS_OK;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_WEBCAM_INIT:
			{
				// EXT_webcamInit
				unsigned int *id = (unsigned int *) req->data;
				unsigned int *w = (unsigned int *) (req->data + sizeof(unsigned int));
				unsigned int *h = (unsigned int *) (req->data + 2*sizeof(unsigned int));
				unsigned int frameSize;

				// Increase memory allocated for payload to accomodate an image frame
				frameSize = 3 * (*w) * (*h);
				if (reallocRespData(resp, frameSize) < 0) {
					// Response: send availability
					resp->response.sequence    = req->request.sequence;
					resp->response.status      = ERR_HANDLER_OUT_OF_MEMORY;
					resp->response.payloadSize = 0;
					return;
				}

				LOG_PRINT(stdout, "REQUEST_WEBCAM_INIT: video(%d) %d x %d\n", *id, *w, *h);
				ret = EXT_webcamInit(0,*id, 0, 0, 0, 0, *w, *h, 2, 2, 1, 1/30);

				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_WEBCAM_TERMINATE:
			{
				// EXT_webcamTerminate
				unsigned int *id = (unsigned int *) req->data;
				LOG_PRINT(stdout, "REQUEST_WEBCAM_TERMINATE: video(%d)\n", *id);
				ret = EXT_webcamTerminate(0,*id);

				// Reduce memory
				if (deallocRespData(resp) < 0) {
					// Response: send availability
					resp->response.sequence    = req->request.sequence;
					resp->response.status      = ERR_HANDLER_OUT_OF_MEMORY;
					resp->response.payloadSize = 0;
					return;
				}

				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_WEBCAM_SNAPSHOT:
			{
				//EXT_webcamCapture
				unsigned int *id = (unsigned int *) req->data;
				unsigned int *w = (unsigned int *) (req->data + sizeof(unsigned int));
				unsigned int *h = (unsigned int *) (req->data + 2*sizeof(unsigned int));
				void *data = (void *) resp->data;
				int psize = (*w) * (*h);
				LOG_PRINT(stdout, "REQUEST_WEBCAM_SNAPSHOT: video(%d) %d x %d\n", *id, *w, *h);
				ret = EXT_webcamCapture(0,*id, data, data + psize, data + psize*2);

				/* Response: send status */
				resp->response.sequence = req->request.sequence;
				resp->response.status   = ret;
				if (ret == 0) {
					resp->response.payloadSize = psize*3;
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_GPIO_WRITE:
			{
				// int EXT_GPIO_write(unsigned int gpio, boolean_T value)
				unsigned int *gpio = (unsigned int *) req->data;
				boolean_T *value = (boolean_T *) (req->data + sizeof(unsigned int));

				LOG_PRINT(stdout, "REQUEST_GPIO_WRITE: GPIO(%d).value <= %d\n",
						*gpio, *value);
				ret = EXT_GPIO_write(*gpio, *value);
				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				resp->response.payloadSize = 0;
			}
			break;
		case REQUEST_GPIO_GET_STATUS:
			{
				// int EXT_GPIO_read(unsigned int gpio, boolean_T *value)
				unsigned int *gpio = (unsigned int *) req->data;
				uint8_T *pinStatus = (uint8_T *) (resp->data);

				ret = EXT_GPIO_getStatus(*gpio, pinStatus);
				LOG_PRINT(stdout, "REQUEST_GPIO_GET_STATUS: GPIO(%d).status => %d\n",
						*gpio, *pinStatus);
				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				if (ret == 0) {
					resp->response.payloadSize = sizeof(uint8_T);
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_PWM_INIT:
			{
				// int32_T EXT_PWM_init(uint32_T pin, uint32_T frequency, double initialDutyCycle)
				uint32_T *pin = (unsigned int *) req->data;
				uint32_T *frequency = (uint32_T *) (req->data + sizeof(uint32_T));
				double *dutyCycle = (double *) (req->data + 2*sizeof(uint32_T));

				ret = EXT_PWM_init(*pin, *frequency, *dutyCycle);
				LOG_PRINT(stdout, "REQUEST_PWM_INIT: PWM(%d).status => %d\n",
						*pin, ret);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_PWM_DUTYCYCLE:
			{
				// int32_T EXT_PWM_setDutyCycle(uint32_T pin, double dutyCycle)
				uint32_T *pin = (unsigned int *) req->data;
				double *dutyCycle = (double *) (req->data + sizeof(uint32_T));

				ret = EXT_PWM_setDutyCycle(*pin, *dutyCycle);
				LOG_PRINT(stdout, "REQUEST_PWM_DUTYCYCLE: PWM(%d).status => %d\n",
						*pin, ret);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_PWM_FREQUENCY:
			{
				// int32_T EXT_PWM_setFrequency(uint32_T pin, uint32_T frequency)
				uint32_T *pin = (unsigned int *) req->data;
				uint32_T *frequency = (uint32_T *) (req->data + sizeof(uint32_T));

				ret = EXT_PWM_setFrequency(*pin, *frequency);
				LOG_PRINT(stdout, "REQUEST_PWM_FREQUENCY: PWM(%d).status => %d\n",
						*pin, ret);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_PWM_TERMINATE:
			{
				// int32_T EXT_PWM_terminate(uint32_T pin)
				unsigned int *pin = (unsigned int *) req->data;

				ret = EXT_PWM_terminate(*pin);
				LOG_PRINT(stdout, "REQUEST_PWM_TERMINATE: PWM(%d).status => %d\n",
						*pin, ret);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_SERVO_INIT:
			{
				// int32_T EXT_SERVO_init(uint32_T pin)
				unsigned int *pin = (unsigned int *) req->data;

				ret = EXT_SERVO_init(*pin);
				LOG_PRINT(stdout, "REQUEST_SERVO_INIT: Servo(%d).status => %d\n",
						*pin, ret);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_SERVO_WRITE:
			{
				// int32_T EXT_SERVO_write(uint32_T pin, double shaftAngle,
				//    double minPulseWidth, double maxPulseWidth)
				unsigned int *pin = (unsigned int *) req->data;
				double *shaftAngle = (double *) (req->data + sizeof(unsigned int));
				double *minPulseWidth = (double *) (req->data + sizeof(unsigned int) + sizeof(double));
				double *maxPulseWidth = (double *) (req->data + sizeof(unsigned int) + 2*sizeof(double));

				ret = EXT_SERVO_write(*pin, *shaftAngle, *minPulseWidth, *maxPulseWidth);
				LOG_PRINT(stdout, "REQUEST_SERVO_WRITE: Servo(%d).status => %d\n",
						*pin, ret);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_SERVO_TERMINATE:
			{
				// int32_T EXT_SERVO_terminate(uint32_T pin)
				unsigned int *pin = (unsigned int *) req->data;

				ret = EXT_SERVO_terminate(*pin);
				LOG_PRINT(stdout, "EXT_SERVO_terminate: Servo(%d).status => %d\n",
						*pin, ret);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_I2C_BUS_AVAILABLE:
			{
				// extern int EXT_I2C_isBusAvailable(const unsigned int bus, boolean_T *available)
				unsigned int *bus = (unsigned int *) req->data;
				boolean_T *available = (boolean_T *) (resp->data);

				ret = EXT_I2C_isBusAvailable(*bus, available);
				LOG_PRINT(stdout, "REQUEST_I2C_BUS_AVAILABLE: I2C(%d).available => %d\n",
						*bus, *available);
				/* Response: send availability */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				if (ret == 0) {
					resp->response.payloadSize = sizeof(boolean_T);
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_I2C_INIT:
			{
				// extern int EXT_I2C_init(const unsigned int bus)
				unsigned int *bus = (unsigned int *) req->data;

				LOG_PRINT(stdout, "REQUEST_I2C_INIT: I2C(%d)\n", *bus);
				ret = EXT_I2C_init(*bus);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_I2C_READ:
			{
				// extern int EXT_I2C_read(const unsigned int bus, const uint8_T address, void *data, const int count)
				unsigned int *bus = (unsigned int *) req->data;
				uint8_T *address = (uint8_T *) (req->data + sizeof(unsigned int));
				int *count = (int *) (req->data + sizeof(unsigned int) + sizeof(uint8_T));
				void *data = (void *) resp->data;

				LOG_PRINT(stdout, "REQUEST_I2C_READ: I2C(%d).address(0x%x).count <= %d\n",
						*bus, *address , *count);
				ret = EXT_I2C_read(*bus, *address, data, *count);
				/* Response: send availability */
				resp->response.sequence = req->request.sequence;
				resp->response.status   = ret;
				if (ret == 0) {
					resp->response.payloadSize = *count;
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_I2C_WRITE:
			{
				// extern int EXT_I2C_write(const unsigned int bus, const uint8_T address, void *data, const int count)
				unsigned int *bus = (unsigned int *) req->data;
				uint8_T *address = (uint8_T *) (req->data + sizeof(unsigned int));
				int *count = (int *) (req->data + sizeof(unsigned int) + sizeof(uint8_T));
				void *data = (void *) (req->data + sizeof(unsigned int) + sizeof(int) + sizeof(uint8_T));

				LOG_PRINT(stdout, "REQUEST_I2C_WRITE: I2C(%d).address = (0x%x).count  => %d and data %d\n",
						*bus, *address, *count, *(int*)data);
				ret = EXT_I2C_write(*bus, *address, data, *count);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_I2C_TERMINATE:
			{
				// extern int EXT_I2C_terminate(const unsigned int bus)
				unsigned int *bus = (unsigned int *) req->data;

				LOG_PRINT(stdout, "REQUEST_I2C_TERMINATE: I2C(%d)\n", *bus);
				ret = EXT_I2C_terminate(*bus);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_I2C_READ_REGISTER:
			{
				unsigned int *bus = (unsigned int *) req->data;
				uint8_T *address = (uint8_T *) (req->data + sizeof(unsigned int));
				uint8_T *reg = (uint8_T *) (req->data + sizeof(unsigned int) + sizeof(uint8_T));
				int *count = (int *) (req->data + sizeof(unsigned int) + 2*sizeof(uint8_T));
				void *data = (void *) resp->data;

				LOG_PRINT(stdout, "REQUEST_I2C_READ_REGISTER: I2C(%d).address(0x%x).reg(0x%x).count => %d\n",
						*bus, *address , *reg, *count);
				ret = EXT_I2C_readRegister(*bus, *address, *reg, data, *count);
				/* Response: send availability */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				if (ret == 0) {
					resp->response.payloadSize = *count;
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_I2C_WRITE_REGISTER:
			{
				unsigned int *bus = (unsigned int *) req->data;
				uint8_T *address = (uint8_T *) (req->data + sizeof(unsigned int));
				uint8_T *reg = (uint8_T *) (req->data + sizeof(unsigned int) + sizeof(uint8_T));
				int *count = (int *) (req->data + sizeof(unsigned int) + 2*sizeof(uint8_T));
				void *data = (void *) (req->data + sizeof(unsigned int) + sizeof(int) + 2*sizeof(uint8_T));

				LOG_PRINT(stdout, "REQUEST_I2C_WRITE_REGISTER: I2C(%d).address(0x%x).reg(0x%x).count <= %d\n",
						*bus, *address, *reg, *count);
				ret = EXT_I2C_writeRegister(*bus, *address, *reg, data, *count);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_SPI_INIT:
			{
				unsigned int *channel = (unsigned int *) req->data;
				uint8_T *mode = (uint8_T *) (req->data + sizeof(unsigned int));
				uint8_T *bitsPerWord = (uint8_T *) (req->data + sizeof(unsigned int) + sizeof(uint8_T));
				uint32_T *speed = (unsigned int *) (req->data + sizeof(unsigned int) + 2*sizeof(uint8_T));

				LOG_PRINT(stdout, "REQUEST_SPI_INIT: CE=%d, mode=%d, bpw=%d, speed=%d\n",
						*channel, *mode, *bitsPerWord, *speed);
				ret = EXT_SPI_init(*channel, *mode, *bitsPerWord, *speed);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_SPI_WRITEREAD:
			{
				/* data is of type uint32 */
				unsigned int *channel = (unsigned int *) req->data;
				uint8_T *bitsPerWord = (uint8_T *) (req->data + sizeof(unsigned int));
				uint32_T *count = (uint32_T *) (req->data + sizeof(unsigned int) + sizeof(uint8_T));
				void *data = (void *) (req->data + sizeof(unsigned int) + sizeof(uint32_T) + sizeof(uint8_T));

				LOG_PRINT(stdout, "REQUEST_SPI_WRITEREAD: CE=%d, bpw=%d, count=%d\n",
						*channel, *bitsPerWord , *count);
				ret = EXT_SPI_writeRead(*channel, data, *bitsPerWord, *count);

				/* Response: Send data read */
				memcpy(resp->data, data, *count);
				resp->response.sequence = req->request.sequence;
				resp->response.status   = ret;
				if (ret == 0) {
					/* payload size is in bytes */
					resp->response.payloadSize = *count;
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_SPI_TERMINATE:
			{
				unsigned int *channel = (unsigned int *) req->data;

				LOG_PRINT(stdout, "REQUEST_SPI_TERMINATE: CE=%d\n",
						*channel);
				ret = EXT_SPI_terminate(*channel);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_SERIAL_INIT:
			{
				// int EXT_SERIAL_init(const char *port, const uint32_T baudRate, ...
				//  const uint32_T dataBits, const uint32_T Parity, ...
				//  const uint32_T stopBits, uint32_T *devNo);
				//
				// obj.raspiObj.sendRequest(obj.REQUEST_SERIAL_INIT, ...
				//    uint32(obj.BaudRate), uint32(obj.DataBits), ...
				//    uint32(obj.Parity), uint32(obj.StopBits), uint8(obj.Port));
				uint32_T *baudRate = (uint32_T *) req->data;
				uint32_T *dataBits = (uint32_T *) (req->data + sizeof(uint32_T));
				uint32_T *parity   = (uint32_T *) (req->data + 2*sizeof(uint32_T));
				uint32_T *stopBits = (uint32_T *) (req->data + 3*sizeof(uint32_T));
				char *port = (char *) (req->data + 4*sizeof(uint32_T));
				uint32_T *devNo = (uint32_T *) resp->data;

				LOG_PRINT(stdout, "REQUEST_SERIAL_INIT: port=%s, Params=(b%d,d%d,p%d,s%d)\n",
						port, *baudRate, *dataBits, *parity, *stopBits);
				ret = EXT_SERIAL_init(port, *baudRate, *dataBits, *parity, *stopBits, devNo);

				/* Response: send availability */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				if (ret == 0) {
					resp->response.payloadSize = sizeof(uint32_T);
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_SERIAL_TERMINATE:
			{
				// int EXT_SERIAL_terminate(const uint32_T deviceNumber);
				//
				// obj.raspiObj.sendRequest(obj.REQUEST_SERIAL_TERMINATE, ...
				//    uint32(obj.DeviceNumber));
				uint32_T *devNo = (uint32_T *) req->data;

				LOG_PRINT(stdout, "REQUEST_SERIAL_TERMINATE: device=%d\n", *devNo);
				ret = EXT_SERIAL_terminate(*devNo);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_SERIAL_READ:
			{
				// int EXT_SERIAL_read(const uint32_T deviceNumber, ...
				//          void *data, uint32_T *count, const double timeout)
				//
				// obj.raspiObj.sendRequest(obj.REQUEST_SERIAL_READ, ...
				//    uint32(obj.DeviceNumber), ...
				//    uint32(count * obj.SIZEOF.(precision)), ...
				//    int32(obj.PollTimeoutInMs));
				// data = typecast(obj.raspiObj.recvResponse(), precision);
				uint32_T *devNo = (uint32_T *) req->data;
				uint32_T *count = (uint32_T *) (req->data + sizeof(uint32_T));
				int32_T *timeoutInMs = (int32_T *) (req->data + 2*sizeof(uint32_T));
				uint8_T *data = (uint8_T *) resp->data;

				LOG_PRINT(stdout, "REQUEST_SERIAL_READ: device=%d, count=%d, timeout=%d\n",
						*devNo, *count, *timeoutInMs);
				ret = EXT_SERIAL_read(*devNo, data, count, *timeoutInMs);

				/* Response: send availability */
				resp->response.sequence = req->request.sequence;
				resp->response.status   = ret;
				if (ret == 0) {
					resp->response.payloadSize = *count;
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_SERIAL_WRITE:
			{
				// int EXT_SERIAL_write(const uint32_T deviceNumber, void *data, const uint32_T count);
				//
				// obj.raspiObj.sendRequest(obj.REQUEST_SERIAL_WRITE, ...
				//    uint32(obj.DeviceNumber), ...
				//    uint32(length(data)), data);
				uint32_T *devNo = (uint32_T *) req->data;
				uint32_T *count = (uint32_T *) (req->data + sizeof(uint32_T));
				uint8_T *data = (uint8_T *) (req->data + 2*sizeof(uint32_T));

            LOG_PRINT(stdout, "REQUEST_SERIAL_WRITE: device=%d, count=%d\n",
                    *devNo, *count);
            ret = EXT_SERIAL_write(*devNo, data, *count);
            setStatusResponse(resp, req, ret);
        }
        break;
        case REQUEST_CAMERABOARD_INIT:
        {
            deallocRespData(resp);
            // extern int EXT_CAMERABOARD_init(const int width, const int height,
            //  const int frameRate, const int quality, const char *cameraParamsStr);
            int *width = (int *) req->data;
            int *height = (int *) (req->data + sizeof(int));
            int *frameRate = (int *) (req->data + 2*sizeof(int));
            int *quality = (int *) (req->data + 3*sizeof(int));
            char *controlParams = (char *) (req->data + 4*sizeof(int));
            unsigned int frameSize;

				// Increase memory allocated for payload to accomodate an image frame
				frameSize = 3 * (*width) * (*height) / 2;
				if (reallocRespData(resp, frameSize) < 0) {
					// Response: send availability
					resp->response.sequence    = req->request.sequence;
					resp->response.status      = ERR_HANDLER_OUT_OF_MEMORY;
					resp->response.payloadSize = 0;
					return;
				}

				LOG_PRINT(stdout, "REQUEST_CAMERABOARD_INIT: (w, h, fps, q) = [%d, %d, %d, %d]\n",
						*width, *height, *frameRate, *quality);
				ret = EXT_CAMERABOARD_init(*width, *height, *frameRate, *quality, controlParams);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_CAMERABOARD_TERMINATE:
			{
				LOG_PRINT(stdout, "REQUEST_CAMERABOARD_TERMINATE: %d\n", 0);
				ret = EXT_CAMERABOARD_terminate();

				// Reduce memory
				if (deallocRespData(resp) < 0) {
					// Response: send availability
					resp->response.sequence    = req->request.sequence;
					resp->response.status      = ERR_HANDLER_OUT_OF_MEMORY;
					resp->response.payloadSize = 0;
					return;
				}
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_CAMERABOARD_SNAPSHOT:
			{
				uint32_T dataSize;
				uint8_T *data = (uint8_T *) resp->data;

				LOG_PRINT(stdout, "REQUEST_CAMERABOARD_SNAPSHOT: %d\n", 0);
				ret = EXT_CAMERABOARD_snapshot(data, &dataSize);

				// Response: send availability
				resp->response.sequence = req->request.sequence;
				resp->response.status   = ret;
				if (ret == 0) {
					resp->response.payloadSize = dataSize;
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_CAMERABOARD_CONTROL:
			{
				char *controlParams = (char *) req->data;

				LOG_PRINT(stdout, "REQUEST_CAMERABOARD_CONTROL: %d\n", 0);
				ret = EXT_CAMERABOARD_control(controlParams);
				setStatusResponse(resp, req, ret);
			}
			break;
		case REQUEST_JOYSTICK_INIT:
			{
				// int EXT_JOYSTICK_INIT(char* sh_evdevname)
				char *data = (char *) resp->data;
				uint16_t evDevBufFileLength;

				ret = EXT_JOYSTICK_INIT(data, &evDevBufFileLength);
				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				if (ret == 0) {
					resp->response.payloadSize = evDevBufFileLength;
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_JOYSTICK_READ:
			{
				// int EXT_JOYSTICK_READ(unsigned int button, boolean_T *value)
				char *sh_evDevname = (char *) (req->data);
				boolean_T *value = (boolean_T *) (resp->data);

				ret = EXT_JOYSTICK_READ(sh_evDevname,value);

				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				if (ret == 0) {
					resp->response.payloadSize = sizeof(boolean_T);
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_FRAMEBUFFER_INIT:
			{

				// int EXT_FRAMEBUFFER_INIT(char* sh_name)

				char *data = (char *) resp->data;
				uint16_t FrameBufFileLength;

				ret = EXT_FRAMEBUFFER_INIT(data, &FrameBufFileLength);
				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				if (ret == 0) {
					resp->response.payloadSize = FrameBufFileLength;
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_FRAMEBUFFER_WRITEPIXEL:
			{

				// int EXT_FRAMEBUFFER_SETPIXEL(int pxllocation,int pxlvalue)
				uint16_t *pxllocation = (uint16_t *) req->data;
				uint16_t *pxlvalue = (uint16_t *) (req->data + sizeof(uint16_t));
				char *sh_fbname = (char *) (req->data+2*sizeof(uint16_t));
				ret = EXT_FRAMEBUFFER_WRITEPIXEL(sh_fbname,*pxllocation,*pxlvalue);
				/* Response: send status */
				resp->response.sequence    = req->request.sequence;
				resp->response.status      = ret;
				if (ret == 0) {
					resp->response.payloadSize = sizeof(boolean_T);
				}
				else {
					resp->response.payloadSize = 0;
				}
			}
			break;
		case REQUEST_FRAMEBUFFER_DISPLAYIMAGE:
			{

            // int EXT_FRAMEBUFFER_DISPLAYIMAGE(const uint8_t flip,const uint16_t *imgArray);
            uint8_T *flip = (uint8_T *)(req->data);
            uint16_t *imgArray = (uint16_t *) (req->data+ sizeof(uint8_t));
            char *sh_fbname = (char *) (req->data+sizeof(uint8_t)+64*sizeof(uint16_t));
            ret = EXT_FRAMEBUFFER_DISPLAYIMAGE(sh_fbname,*flip,imgArray);
            /* Response: send status */
            resp->response.sequence    = req->request.sequence;
            resp->response.status      = ret;
            if (ret == 0) {
                resp->response.payloadSize = sizeof(boolean_T);
            }
            else {
                resp->response.payloadSize = 0;
            }
        }
        break;
        case REQUEST_FRAMEBUFFER_DISPLAYMESSAGE:
        {
            uint16_t *strArrayLen = (uint16_t *)(req->data);
            uint16_t *orientation = (uint16_t *)(req->data+sizeof(uint16_t));
            uint16_t *scrollSpeed = (uint16_t *)(req->data+2*sizeof(uint16_t));
            uint16_t *strArray    = (uint16_t *)(req->data+3*sizeof(uint16_t));
            char *sh_fbname = (char *) (req->data+((*strArrayLen)+3)*sizeof(uint16_t));
            ret = EXT_FRAMEBUFFER_DISPLAYMESSAGE(sh_fbname,strArray,*strArrayLen,*orientation,*scrollSpeed);
            /* Response: send status */
            resp->response.sequence    = req->request.sequence;
            resp->response.status      = ret;
            if (ret == 0) {
                resp->response.payloadSize = sizeof(boolean_T);
            }
            else {
                resp->response.payloadSize = 0;
            }
        }
        break;
        default:
            LOG_PRINT(stdout, "Invalid REQUEST, %d, received.\n", req->request.id);
            setStatusResponse(resp, req, ERR_HANDLER_INVALID_REQUEST);
    }
}
#ifdef NANOMSG_TRANSPORT
static int  waitForClientConnection(int sock, char * hostIpAddress, int port)
{
	char *respData = NULL;
	int bytesRead =0;
	int recvTimeout = -1;
	char command[100] = {'\0'};
	int ret = nn_setsockopt(sock,NN_SOL_SOCKET, NN_RCVTIMEO , &recvTimeout , sizeof(recvTimeout));
	if (ret < 0) {
		return -1;
	}
	bytesRead = nn_recv(sock, &respData,  NN_MSG  , 10000);
	if(bytesRead > 0)
	{
		if( (bytesRead == 8 )  &  (strncmp(respData,"Hello pi",bytesRead) == 0 )   )
		{
			printf("%x,%x,%x,%x,%x \n", respData[0],  respData[1],  respData[2] , respData[3] , respData[4]);
			 
			/* Find  the foreign ip address which gets connected to given tcp port, to use it 
			 * further for checking the client status  */
#ifndef __MINGW32__
			sprintf(command, "sudo netstat -tna | grep %d | awk  '/ESTABLISHED/ {print$5}'| awk -F : '{print $1}'", port);
#else			
			/* To support the stub server tests on windows platform */ 
			sprintf(command, "netstat -tna | grep %d | awk  '/ESTABLISHED/ {print$3}'| awk -F : '{print $1}'", port);
#endif
			int i = 0;
			FILE *fp = popen(command, "r");
			if(fp == NULL)
				return -1;

			/* 15 is the maximum length of any ipv4 address xxx.xxx.xxx.xxx */
			fread(hostIpAddress, 15, 1, fp);

			/*  Remove next line character if its there from the end of string */
			while(hostIpAddress[i] != '\n')
			{
                if(i == 15)
                   break;
				i++;
			}
			hostIpAddress[i] = '\0';
			fclose(fp);
		}
		else
			return -1;
	}
	return 0;
}
#endif

static int authorizeClient(int sock, REQUEST_t *req, RESPONSE_t *resp)
{
	int ret;

#ifdef NANOMSG_TRANSPORT 
	int authTimeout = AUTHORIZATION_TIMEOUT *1000, recvTimeout = RCVTIMEOUT;
	ret = nn_setsockopt(sock,NN_SOL_SOCKET, NN_RCVTIMEO , &authTimeout, sizeof(authTimeout));
	if (ret < 0) {
		perror("setting Autherization Timeout failed \n");
		return -1;
	}   
#else
	// Set a 10 second timeout on the socket receive
	if (setSockRecvTimeout(sock, AUTHORIZATION_TIMEOUT) < 0) {
		return -1;
	}
#endif



	// Receive authorization request
	if (receiveRequest(sock, req) < 0) {
		return -1;
	}

	// Client must request authorization
	if (req->request.id != REQUEST_AUTHORIZATION) {
		return -1;
	}

	// Authorize client
	ret = EXT_SYSTEM_authorize(req->data);

	// Response
	resp->response.sequence    = req->request.sequence;
	resp->response.payloadSize = 0;
	if (ret == 0) {
		resp->response.status  = 0;
	}
	else {
		resp->response.status  = ERR_HANDLER_AUTHORIZATION;
	}
	if (sendResponse(sock, resp) < 0) {
		return -1;
	}
#ifdef NANOMSG_TRANSPORT
	/* set the recieve time out to 10 seconds */
	ret = nn_setsockopt(sock,NN_SOL_SOCKET, NN_RCVTIMEO , &recvTimeout , sizeof(recvTimeout));
	if (ret < 0) {
		perror("setting recvtimeout failed \n");
		return -1;
	}
#else
	// Return receive timeout to infinite
	if (setSockRecvTimeout(sock, 0) < 0) {
		return -1;
	}
#endif

	return 0;
}

/* Check for the client status for the given port
	* return -1 if client is not alive 
	* return 1 id client is alive */
int checkForClientStatus(char *hostIpAddress, int port)
{
	char command[100] = {'\0'};
	/* Ping the client to check if client is alive && if ping success check the connection status using netstat */
#ifndef __MINGW32__
	sprintf(command, "ping -c 4 -i .2 -w 1 %s && netstat -tna | grep %d", hostIpAddress, port);
#else
	/* To support the stub server tests on windows platform */ 
	sprintf(command, "ping -w 1 %s && netstat -tna | grep %d", hostIpAddress, port);
#endif
	FILE *fp = popen(command, "r");
	char *connection = "ESTABLISHED";
	char commandData[1024] = {'\0'};
	fread(commandData , 1024, 1, fp);
	fclose(fp);

	/* "Netstat" provides the information about the connection establishment between two network peers.
	 *  Check for the 'ESTABLISHED' string in data*/
	if(strstr(commandData, connection) != NULL)
	{
		/* Client is alive */
		return 1;
	}
	else
	{
		/* Client is not alive */
		return -1;
	}
}

/* Clean up all the resources */
void cleanUpResources()
{
	int i;
	EXT_CAMERABOARD_terminate();
	/* Terminate all the opened camera devices */
	for(i = 0; i< MW_NUM_MAX_VIDEO_DEVICES; i++)
	{
		EXT_webcamTerminate(0,i);
	}
	/* Terminate all the opened GPIO */
	for(i = 0; i < 32; i++)
	{
		EXT_GPIO_terminate(i);
		
	}
	/* 1 is the bus number */
	EXT_I2C_terminate(1);
	/* 0 and 1 are the channel number */
	EXT_SPI_terminate(0);
	EXT_SPI_terminate(1);
	/* 37 is the id number for serial port */
	EXT_SERIAL_terminate(DEV_SERIAL_0);
}

/* Event handler */
void *eventHandlerThread(void *args)
{
	int sock;
	int port;
	REQUEST_t *req = NULL;
	RESPONSE_t *resp = NULL;
	char hostIpAddress[16] = {'\0'};
	short isClientAlive = 1;
	// Detach the thread from the parent.
	// Resources will be automatically de-allocated upon exit
	pthread_detach(pthread_self());

	// Extract socket file descriptor from argument
	sock = ((ARGS_t *)args)->sock;
	port = ((ARGS_t *)args)->port;
	free(args);

	// Allocate REQUEST buffer
	req = (REQUEST_t *) malloc(sizeof(REQUEST_t));
	if (req == NULL) {
		perror("malloc/REQUEST");
		goto DISCONNECT;
	}

	// Allocate RESPONSE buffer
	resp = (RESPONSE_t *) malloc(sizeof(RESPONSE_t));
	if (resp == NULL) {
		perror("malloc/REQUEST");
		goto DISCONNECT;
	}
	resp->dataReallocCount = 0;
	resp->dataSize = 0;
	resp->data = (char *)malloc(RESP_MAX_PAYLOAD_SIZE);
	if (resp->data == NULL) {
		perror("malloc/REQUEST");
		goto DISCONNECT;
	}
	resp->dataSize = RESP_MAX_PAYLOAD_SIZE;
#ifdef NANOMSG_TRANSPORT
	if (waitForClientConnection(sock,hostIpAddress, port) < 0)
		goto DISCONNECT;
	else
	{
	   /* If it is first client, Send the valid response  back to the client. */ 
        setStatusResponse(resp, req, 0);
	   	resp->response.sequence    = 0;
        if (sendResponse(sock, resp) < 0) {
        perror("sendResponse");
		goto DISCONNECT;
            }
	}
#endif
	// Authorize client
	if (authorizeClient(sock, req, resp) < 0) {
		goto DISCONNECT;
	}
	int recvBytes;
	// Event loop
	while (1) {
		

		if ((recvBytes = receiveRequest(sock, req)) < 0) {
			if(recvBytes == -1)
			{
					if(checkForClientStatus(hostIpAddress,port) == -1)
					{
					isClientAlive = 0;
					break;
					}
					else
					continue;
			}
			else if(recvBytes == -2)
			{
				/* Send the error back to client  */
           				setStatusResponse(resp, req, ERR_MULTI_CONNECTION_REQUEST);
            				if (sendResponse(sock, resp) < 0) {
                			perror("sendResponse");
					}
					continue;
			}
			/* recvBytes -3 means connection is closed by the client */
			else if(recvBytes == -3)		
					break;
				
		}

        if(req->request.sequence > (lastSeq+1)){
            LOG_PRINT(stdout, "Lost %d messages\n", req->request.sequence-lastSeq-1);
        }
        // avoid the scenario when the same message is read 
        // twice from socket to account for a possible bug 
        // in nanomsg
        if(req->request.sequence != lastSeq){ 
            // update lastSeq
            lastSeq = req->request.sequence;
            // Process REQUEST
            executeCommand(req, resp);

            // Send RESPONSE
            LOG_PRINT(stdout, "RESP = [%d, %d, %d]\n", resp->response.status,
                    resp->response.sequence, resp->response.payloadSize);
            if (sendResponse(sock, resp) < 0) {
                perror("sendResponse");
                break;
            }
        }
    }

DISCONNECT:
	if(!isClientAlive)
	{
		cleanUpResources();
	}
	if (req != NULL) {
		free(req);
	}
	if (resp != NULL) {
		if (resp->data != NULL) {
			free(resp->data);
		}
		free(resp);
	}
#ifdef NANOMSG_TRANSPORT
	if(pubSockFd >=0) /* if pub socket is created , then close the socket*/
	{
		int ret = nn_close(pubSockFd); /* closing the pub socket fd */
		assert(ret == 0);
		pubSockFd=-1;
	}
#else


	close(sock);
#endif
#ifdef _DEBUG

	printf("Client disconnected...\n");
	fflush(stdout);

#endif

	return (NULL);
}
/* EOF */
