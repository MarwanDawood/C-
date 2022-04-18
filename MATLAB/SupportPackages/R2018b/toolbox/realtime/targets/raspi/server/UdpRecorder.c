/* Copyright 2018 The MathWorks, Inc. */
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <sys/socket.h>
#include <pthread.h>
#include <arpa/inet.h>
#ifdef NANOMSG_TRANSPORT
#include <nanomsg/nn.h>
#include <nanomsg/pubsub.h>
#endif
#include "TimerBasedRecorder.h"
#include "common.h"
#include "UdpRecorder.h"
#include "handler.h"
#include "recorder.h"

#define MAX_MEMORY_NODE 1024000
#define MAX_PACKET_SIZE     1600
#define PAYLOAD_BYTES        2
#define SUB_TOKEN_SIZE          9
/* diag Main Socket For Server */
int diagMainSocket;   

struct timespec currTstamp ,endTstamp , selEndTime,  selStartTime;
struct timespec udpStartTimel;
fd_set readFds;
int rv =-1;
struct timeval udpSelectTime;

/* Wait for data recieved on specified port */
int waitonFdWithTimeout(int sock, unsigned long timeoutInSeconds)
{
	udpSelectTime.tv_sec = timeoutInSeconds;
	udpSelectTime.tv_usec = 0;
	FD_ZERO(&readFds);
	FD_CLR(0, &readFds);
	FD_SET(sock, &readFds);
	rv = select(sock + 1, &readFds, NULL, NULL, &udpSelectTime);
	return rv;
}

/* Udp release call back fucntion to close the udp socket, and reinitalize the counter */
void udpRelease(void *arg, void *null)
{
	struct peripheralData *pData = (struct peripheralData *)arg;
	int err;
	pData->startCaptureFlag = STOP;    
	/* Close udp log file pointer */
	if(pData->fprd != NULL)
	{
		//pData->startCaptureFlag = 0;
		err = fclose(pData->fprd); /* close the log file */
		if(err != 0 )
			perror("error in closing udp file");
		else
		{
			pData->fprd = NULL;
		}
	}


	/* close socket descriptor */
	if(pData->udpMainSocket >0)
	{
		err = close(pData->udpMainSocket);
		if(err == 0)
		{
#if DEBUG
			printf(" Close udp main socket sucessfull\n");
#endif
		}
		else
		{
			perror("UDP socket error:");
		}
		pData->udpMainSocket = -1;
	}

	pData->totalTimeExpired = 0;
}

/* udp Read call back to read data from udp port  */
short udpRead(unsigned char *buff, int udpMainSocket)
{
	/* Address Of Client That Communicate with Server */
	struct sockaddr_in ClientAddress;
	socklen_t Length = sizeof(ClientAddress);
	short ret;
	ret = recvfrom(udpMainSocket , buff , MAX_PACKET_SIZE , 0, (struct sockaddr*)&ClientAddress,&Length);
#if DEBUG
	printf("RX:%d\n",ret);
#endif
	return ret;
}

/* Initialization of Udp port for udp data recieving */
int  initializeUdp(void *arg, void *null)
{
	struct peripheralData *pData = (struct peripheralData *)arg;

	int Status , ioFlag = -1; // Status Of Function
	struct sockaddr_in ServerAddress; // Address Of Server
	pData->udpMainSocket = socket(AF_INET, SOCK_DGRAM, 0);
	if (pData->udpMainSocket == -1 )
	{
		perror ("Sorry System Can Not Create Socket!\n");
	}
#if DEBUG
	printf("port number is %d\n", pData->udpPort);
#endif
	ServerAddress.sin_family = AF_INET;
	ServerAddress.sin_port = htons(pData->udpPort);
	ServerAddress.sin_addr.s_addr = htonl(INADDR_ANY);
	Status = bind (pData->udpMainSocket ,(struct sockaddr*)&ServerAddress, sizeof(ServerAddress));
	if ( Status == -1 )
	{
		perror("Bind error:");
	}
	if ((ioFlag = fcntl(pData->udpMainSocket, F_GETFL, 0)) != -1)
		fcntl(pData->udpMainSocket, F_SETFL, ioFlag | O_NONBLOCK);    

	/* Initialization of udpRead, and udp release  call  back function */
	pData->capture = udpRead;
	pData->release = udpRelease;
	return 0;
}

long long  writeUdpHeaderInfo( struct peripheralData *pData)
{
	long long tmpTime;
	char buff[30];
	int err;
	sprintf(pData->hInfo.version, "VER.%d.%d", 1, 1);
	pData->hInfo.recordDuration = (short)(pData->totTime);
	sprintf(buff, "/tmp/udp%d_log_message.bin", pData->udpPort);

	/* Creation of binary file for udp read */
	pData->fprd=fopen(buff , "wb");
	if( pData->fprd == NULL )
		perror("UDP log file creation failed \n");

	/* Read the current time */
	if(clock_gettime( CLOCK_REALTIME , &udpStartTimel ) == -1 ) {
		perror( "clock gettime" );
		exit( EXIT_FAILURE );
	}

	/* Conversion of absolute time to relative time with nano second resolution */
	//tmpTime = (long long )udpStartTimel.tv_sec * 1000000000 + ( long long )udpStartTimel.tv_nsec;
	tmpTime = (long long )udpStartTimel.tv_sec * BILLION + ( long long )udpStartTimel.tv_nsec;
	if (pData->logType == DIRECT_LOG)
	{
		/* Wriite header information in to teh file */
		err = fwrite(&(pData->hInfo), 1 , sizeof(struct headerInfo), pData->fprd);
		if(err > 0)
		{
#if DEBUG
			printf(" UDP  file writting header info  %d bytes\n", err);
#endif
		}
		else
		{
			perror(" UDP file write error:");
		}
		/* File writting of start time */
		err = fwrite(&tmpTime , 1 , sizeof(unsigned long long) ,  pData->fprd);
		if(err > 0)
		{
#if DEBUG
			printf(" UDP  file writting start time %d bytes\n", err);
#endif
		}
		else
		{
			perror(" UDP file write error:");
		}
	}
	else
	{
		return tmpTime;    
	}
	return 0;

}
struct udpData *allocUdpMemory()
{
	struct udpData *newNode;
	/* Allocate memory for udpData Structure */
	newNode = (struct udpData *) malloc(sizeof( struct udpData));
	if(newNode == NULL)
	{
		perror("Unable to allocate memory for udpData structure\n");
		exit(1);
	}
	else
	{
#if DEBUG
		printf("Memory allocation done for udpdata structure\n");
#endif
		newNode->data = malloc(MAX_MEMORY_NODE);
		newNode->offset = 0;
		newNode->next =NULL;

		if(newNode->data == NULL)
		{
			perror("Unable to allocate memory for data element of udpData structure\n");
			exit(1);
		}
		else
		{
#if DEBUG
			printf("Memory allocation done for  data element of udpdata structure\n");
#endif
		}
	}
	return newNode;
}

/* UDP Read thread */
void *udpReadThread(void  *Data)
{
	struct peripheralData *pData = (struct peripheralData *)Data;
	/* Address Of Client That Communicate with Server */
	struct udpData *udpDataNode=NULL, *current = NULL;
	long long tmpTime;
	short udpPayloadSz = 0;
	int ret;
	long long remainTimeUs = 0;
	int err;
	unsigned char *tmpBuff = NULL;

	err = pthread_detach(pthread_self());
	if(err == 0)    {
#if DEBUG
		printf(" UDP pthread_detach successfull\n");
#endif
	}else    {
		perror(" UDP pthread error:");
	}

	/* initialization function callback */
	pData->initialize = initializeUdp;
	/* loop continues until clear session command is not recieved from client */
	while(pData->startSessionFlag == START)
	{

		waitForStartRecordEvent();
		if(pData->startSessionFlag == STOP)
			break;
		if (checkResourceEnable(pData)!= ENABLE )
		{
			pData->startCaptureFlag = STOP;    /* Making start capture flag 0 */
			continue;
		}
		pData->initialize(pData, (void *)(NULL));

		if(pData->logType == STREAM)
		{

			tmpBuff = malloc( MAX_PACKET_SIZE );
			if(tmpBuff == NULL)
			{
				perror(" Memory allocation Error:-");
				exit(EXIT_FAILURE);
			}
			else
			{
#if DEBUG
				printf("allocated bytes \n");
#endif
			}
			sprintf( (char *)tmpBuff,"udp%d|", pData->udpPort);
			//sleep(1);
			tmpBuff = tmpBuff + SUB_TOKEN_SIZE + TIME_STAMP_BYTES + PAYLOAD_BYTES; 
		}
		/* If logtype is direct file writting */
		else if(pData->logType == DIRECT_LOG)
		{
			writeUdpHeaderInfo(pData);
			/* Local buffer initialization for data reading from udp port */
			tmpBuff = malloc( MAX_PACKET_SIZE );
		}
		/*  if logtype is memory writting */
		else if (pData->logType == MEMORY_LOG)
		{
			tmpTime = writeUdpHeaderInfo(pData);
			udpDataNode = allocUdpMemory();
			current = udpDataNode;
		}
		int rxUdpCount=0;
		/* Continue the loop until total time given time expire or recieve stop command from client */
		while((pData->totalTimeExpired > 0) && (pData->startCaptureFlag == START))
		{
#if DEBUG
			printf("UDP TotRem T:%llu ,start_flg:%d \n ", pData->totalTimeExpired, pData->startCaptureFlag );    
#endif
			if(pData->logType == MEMORY_LOG)
			{
				/* if allocated memory is left less than, memory required for 1 itrearion then create 1 more memory node */
				if(current->offset >= (MAX_MEMORY_NODE - MAX_PACKET_SIZE))
				{
#if DEBUG
					printf("Creating new node for data storage \n");
#endif
					current = udpDataNode;
					while(current->next != NULL)
					{
						current = current->next;
					}    
					current->next = allocUdpMemory();
					current = current->next;
				}    
			}
			/* Reading start  time */
			if( clock_gettime( CLOCK_REALTIME, &selStartTime) == -1 ) {
				perror( "clock gettime" );
				exit( EXIT_FAILURE );
			}
			/* Wait for data recieving for a specific time */
			ret = waitonFdWithTimeout(pData->udpMainSocket, 1 );
			if((ret >= 1))
			{   
				if(FD_ISSET(pData->udpMainSocket , &readFds)) /* UDP packet received on the port */
				{
					if(pData->logType == DIRECT_LOG)
					{
						/* read data from udp port */
						udpPayloadSz = pData->capture(&tmpBuff[0], pData->udpMainSocket);
					}
					else if(pData->logType == MEMORY_LOG)
					{
#if DEBUG
						printf("UDMoff:1@%d\n", current->offset);
#endif
						*((short *)(current->data + current->offset + TIME_STAMP_BYTES)) = pData->capture(&current->data[current->offset+ TIME_STAMP_BYTES + PAYLOAD_BYTES], pData->udpMainSocket);    
						udpPayloadSz =  *((short *)(current->data+current->offset+TIME_STAMP_BYTES));
					}
#ifdef NANOMSG_TRANSPORT
					else if(pData->logType == STREAM)
					{
						udpPayloadSz = pData->capture(tmpBuff,pData->udpMainSocket);
					}
#endif    
					if(udpPayloadSz > 0 )
					{
						rxUdpCount++;
						/* Calculate the current time after receiving the udp packet */
						if( clock_gettime( CLOCK_REALTIME, &pData->currTstamp) == -1 ) {
							perror( "clock gettime" );
							exit( EXIT_FAILURE );
						}
						if(pData->logType == DIRECT_LOG)
						{
							/* Calculate t5he total  relative  time */ 
							tmpTime = timeDiff(&udpStartTimel, &pData->currTstamp);
							/* File writting the relative time relative time, payload size and payload */
							err = fwrite(&tmpTime , 1 , sizeof(long long ) , pData->fprd);
							if(err > 0)
							{
#if DEBUG
								printf(" UDP  file writtingggg %d bytes\n",err);
#endif
							}
							else
							{
								perror(" UDP file write error:");
							}
							err = fwrite(&udpPayloadSz, 1, sizeof(short), pData->fprd);
							if(err > 0)
							{
#if DEBUG
								printf(" UDP  file writtinggg %d bytes\n",err);
#endif
							}
							else
							{
								perror(" UDP file write error:");
							}
							err = fwrite(&tmpBuff[0] , 1 , udpPayloadSz , pData->fprd);
							if(err > 0)
							{
#if DEBUG
								printf(" UDP  file writting.. %d bytes\n", err);
#endif
							}
							else
							{
								perror(" UDP file write error:");
							}
						}
#ifdef NANOMSG_TRANSPORT
						else if (pData->logType == STREAM)
						{
							int bytes;
							tmpBuff = tmpBuff - (TIME_STAMP_BYTES + PAYLOAD_BYTES);
							*((unsigned long long *)tmpBuff) = timeDiff(&udpStartTimel, &pData->currTstamp);
							tmpBuff = tmpBuff + TIME_STAMP_BYTES;
							*((short *)tmpBuff) = udpPayloadSz;
							tmpBuff = tmpBuff - (TIME_STAMP_BYTES + SUB_TOKEN_SIZE);
							bytes = nn_send(pubSockFd, tmpBuff , (udpPayloadSz+(SUB_TOKEN_SIZE + TIME_STAMP_BYTES + PAYLOAD_BYTES)) , 0);
							if(bytes <= 0 )
								perror("Error while publishing UDP data.. \n");
							tmpBuff = tmpBuff + (SUB_TOKEN_SIZE + TIME_STAMP_BYTES + PAYLOAD_BYTES);
						}
#endif
						else if(pData->logType == 1)
						{
							*((unsigned long long  *)(current->data+current->offset))= timeDiff(&udpStartTimel, &pData->currTstamp);
							current->offset = TIME_STAMP_BYTES + PAYLOAD_BYTES + udpPayloadSz + current->offset;
						}
					}
					else  
					{
						ret = errno;
						switch(ret)
						{
							case EAGAIN:    printf(" EAGAIN\n");    break;
							case EBADF:     printf(" EBADF\n");     break;
							case EFAULT:    printf(" EFAULT\n");    break;
							case EINVAL:    printf(" EINVAL\n");    break;
							case EINTR:     printf(" EINTR\n");     break;
							default:        printf(" error in rcvfrom %d \n",ret); break;
						}
					}    
				}
				else
				{
#if DEBUG
					printf("OTHER EVNT:%d \n",ret); 
#endif
				}
			}else if(ret ==0)
			{
#if DEBUG
				printf("Select Tout \n");
#endif
			}
			else
			{
#if DEBUG
				printf("Select FAIL \n");
#endif
			}
			/* Reading end time */
			if( clock_gettime( CLOCK_REALTIME, &selEndTime) == -1 ) {
				perror( "clock gettime" );
				exit( EXIT_FAILURE );
			}
			/* Calculate t5he total  relative  time */ 
			remainTimeUs = ( unsigned long long )timeDiff(&selStartTime, &selEndTime);
			/* Calculate the total remaining time to expire */
			pData->totalTimeExpired  = pData->totalTimeExpired - (remainTimeUs/1000);
#if DEBUG
			printf("Elapsed time :%llu \n",remainTimeUs);
			printf("Total remiang time %lld capture flag is  is %d\n ", pData->totalTimeExpired , pData->startCaptureFlag );    
#endif
		}

		pData->startCaptureFlag = STOP;    /* Making start capture flag 0 */
		/* reinitialize the counters and free the allocated  memory */
#if DEBUG
#endif
		if(pData->logType == DIRECT_LOG)
		{    
			fseek(pData->fprd , 0 , SEEK_SET);
			pData->hInfo.numberOfUdpPackets=rxUdpCount;
			rxUdpCount=0;
			err = fwrite(&(pData->hInfo) , 1 , 24 , pData->fprd);
			if(err > 0)
			{
#if DEBUG
				printf(" UDP  file writting header info  %d bytes\n",err);
#endif
			}
			else
			{
				perror(" UDP file write error:");
			}
			rxUdpCount=0;
			free(tmpBuff);    
		}
#if NANOMSG_TRANSPORT
		else if(pData->logType == 3)
		{
			//fseek(pData->fprd , 0 , SEEK_SET);
			pData->hInfo.numberOfUdpPackets=rxUdpCount;
			rxUdpCount=0;
			/* Send Header and intial time */
			int bytes = nn_send(pubSockFd, &pData->hInfo , sizeof(struct headerInfo ) , 0);
			bytes = nn_send(pubSockFd, &udpStartTimel, sizeof(long long  ) , 0);
			//    err = fwrite(&(pData->hInfo) , 1 , 24 , pData->fprd);
			if(bytes > 0)
			{
#if DEBUG
				printf(" UDP  data sent   %d bytes\n",bytes);
#endif
			}
			else
			{
				perror(" UDP nn send error:");
			}
			//rxUdpCount=0;
			tmpBuff = tmpBuff-(SUB_TOKEN_SIZE + TIME_STAMP_BYTES + PAYLOAD_BYTES);
			free(tmpBuff);    
		}
#endif
		else if(pData->logType == MEMORY_LOG)
		{
			pData->hInfo.numberOfUdpPackets=rxUdpCount;
#if DEBUG
#endif
			rxUdpCount=0;
			err = fwrite(&(pData->hInfo), 1 , sizeof(struct headerInfo), pData->fprd);
			if(err > 0)
			{
#if DEBUG
				printf(" UDP  file writting header info  %d bytes\n",err);
#endif
			}else{
				perror(" UDP file write error:");
			}
			/* File writting of start time */
			err = fwrite(&tmpTime , 1 , sizeof(unsigned long long) ,  pData->fprd);
			if(err > 0)
			{
#if DEBUG
				printf(" UDP  file writting .. \n");
#endif
			}else    {
				perror(" UDP file write error:");
			}
			current = udpDataNode;
			while (current != NULL)
			{
				int ret = fwrite(current->data, 1, current->offset, pData->fprd);
				if(ret<0)
					perror("Error while writting udp data to file \n");
				current = current->next;
			}
			struct udpData *temp;


			/* deallocate the memory allocated for data */
			temp = udpDataNode;
			while(temp != NULL)
			{
				udpDataNode = temp->next;

				free(temp->data);
				free(temp);
				temp = udpDataNode;
			}
		}

		pData->release(pData, (void*)NULL);
	}

	return NULL;
}
