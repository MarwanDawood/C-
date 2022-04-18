// Copyright 2013-2017 The MathWorks, Inc.
#ifndef _MW_HANDLER_H_
#define _MW_HANDLER_H_
#include <stdio.h>
#ifdef __WIN32__
#include <winsock2.h>
#include <time.h>
#include <sys/timeb.h>
#include <signal.h>
#else
#include <sys/time.h>
#include <sys/timerfd.h>
#include <semaphore.h>
#include <sched.h>
#include <mqueue.h>
#include <errno.h>
#include <pthread.h>
#endif
#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct {
    int sock;
    int port;    
} ARGS_t;

struct rtval{
                unsigned long long time;
                boolean_T val;
        }__attribute((packed));

#define DEBUG 0

#define START           1
#define ENABLE          1
#define DISABLE         0
#define STOP            0

#define MEMORY_LOG      1
#define DIRECT_LOG      2
#define STREAM          3

#define TIME_STAMP_BYTES   8
#define  BILLION     1000000000llu
#define  MILLION     1000000
#ifdef NANOMSG_TRANSPORT
#define SERVER_URL "tcp://*:40000"
extern int pubSockFd;
#endif



/** sourceCapture:- Responsible for Data Capture process from the peripheral (Gpio, Udp, Audio)
  * mem:- it is the pointer to memory to store the captured data
**/
typedef short (*sourceCapture)(unsigned char  *mem, int);

/** Init capture:- Responsible for initialization of source peripheral related data.
  * pData is pointer to structure 
  * It return integer type 
**/
typedef int  (*initCapture)(void *pData, void *);

/** release capture:- Callback fucntion responsible for releasing spource peripheal data.
  * pData is pointer peripheral data structure 
  * It does not return anything 
**/
typedef void  (*releaseCapture)(void *pData, void*);


extern unsigned long long  timeDiff(struct timespec *startTime, struct timespec *stopTime);


/** struct headerInfo:- This memory contains each peripheral related header information. 
  * version:- Reserved for File versioning.
  * header:-  this store boardtype.
  * peritype:- Indicate the type of peripheral.
  * samplTime:- Audio sampleTime.
  * recordDuration:- To store total record Time.
  * sampleRate:- peripheral sample rate.
  * numberOfUdpPackets:- Store total number of recieved udp packets.
  * gpioNo:- Indicate gpio number.
  * reserved:- Reserved for future use.
**/
struct headerInfo{
    char  version[8];
    short header;
    short peritype;
    short sampleTime;
    short recordDuration ; /* In seconds */
    unsigned short sampleRate;
    short frameLen;
    int   numberOfUdpPackets;
    char  gpioNo;
    char  reserved[87];

};

/** struct peripheralData:- Each peripheral thread has its own  peripheral data.
  * itVal;- Used for periodic timer.
  * currTstamp:- Used to calculate relative time.
  * mem:- Memeory pointer  to store the value of gpio state.
  * totalTimeExpired:- To store the remaining time.
  * timerPeriod:- Peripheral time period for timer based peripheral.
  * wakeupsMissed:-   Indicated the missed timer events. 
  * timerCnt:-  Used to calculate remaining time period.
  * memOffset:- Indicates peripheral data buffer offset.
  * timerFd:- Store the value of file descriptor for timer.
  * hInfo:- Pointer header info strcuture to store header information for each peripheral.
  * capture:- Function pointer for data capture callback.
  * initialize:- Function pointer for intialization.
  * release:-  Function pointer for release callback
  * perId:- Store the peripheral id 
  * udpPort:- Store udp port in case of event based capture.
  * udpMainSocket:- Udp socket file descriptor.
  * fprd:- File pointer for log file.
**/
struct peripheralData{
    long long totalTimeExpired;
    unsigned  char *memBuff;
    unsigned  char *FileMemBuff;
    struct itimerspec itVal;
    struct timespec currTstamp;
    char audioCard[10];
    boolean_T mem;
    unsigned long timerPeriod;
    unsigned long wakeupsMissed;
    unsigned long timerCnt;
    unsigned long memOffset;
    short timerFd;
    struct headerInfo hInfo;
    unsigned long count;
    sourceCapture capture;
    initCapture initialize;
    releaseCapture release;
    short result ;
    int  perId ;
    int udpPort;
    int udpMainSocket;
    short enableFlag;
    short startCaptureFlag;
    short startSessionFlag;
    short totTime;
    char logType;
    FILE *fprd;
    struct peripheralData *next;
    char isGroupRequired;
};
      


/** struct sessionInfo:- This structure contains data(Read only) Shared between all the threads.
  * totTime:- Total capture time in seconds passsed from client with start command
  * startCaptureFlag:- This flag is responsible to keep the capture running until total time is not fininshed or stop command is not 
  * given from client.
  * startSessionFlag:- This flag is repsonsible to keep the sesion running after the capture of each dataset.
  * logType:- This variable use to find out the type of memory logging.
**/


      
/** struct threadData:- This structure contains pointer to peripheral data strcuture,
  * and tid to indicate thread id of each thread.
  * Self referencial pointer to maintain the link list.
**/
struct threadData{
    struct peripheralData *pData;
    pthread_t  tid;
    struct threadData *next;
};



extern pthread_cond_t countCond;
extern pthread_mutex_t countLock;
extern void *eventHandlerThread(void *args);



/*Data Capture Request */
#define REQUEST_SESSION_CREAT           2500
#define REQUEST_ADD_SOURCE              2501
#define REQUEST_CAPTURE_START           2502
#define REQUEST_CAPTURE_STOP            2503
#define REQUEST_SESSION_RELEASE         2504 
#define REQUEST_SESSION_STATUS          2505
#define REQUEST_AVAILABLE_RESOURCES     2506
#define REQUEST_DISABLE_SOURCE          2507
#define REQUEST_ENABLE_SOURCE           2508
#define REQUEST_ENABLE_ALL_SOURCE       2509
#define REQUEST_DISABLE_ALL_SOURCE      2510

/* Data Recording Session Status Message*/ 
		
#define ERR_SETUP_SOURCE_NOT_DONE            5
#define EER_CANT_ALLOCATE_MEMORY_FOR_SESSION 6
#define ERR_SESSION_ALREADY_CREATED          7
#define ERR_CAPTURE_IS_NOT_STARTED           8
#define ERR_AUDIO_DEVICE_NOT_FOUND           9
#define ERR_CAPTURE_ALREADY_RUNNING         10
#define ERR_CANT_ENABLE_SOURCE              11
#define ERR_CANT_DISABLE_SOURCE             12

/* STATUS messages */
#define STATUS_OK                   (0)
#define ERR_HANDLER_INVALID_REQUEST (1) 
#define ERR_HANDLER_OUT_OF_MEMORY   (2)
#define ERR_HANDLER_AUTHORIZATION   (3)
#define ERR_MULTI_CONNECTION_REQUEST   (4)

/* Reserved requests */
#define REQUEST_RESERVED_BASE     (0)
#define REQUEST_ECHO              (REQUEST_RESERVED_BASE)
#define REQUEST_VERSION           (REQUEST_RESERVED_BASE+1)
#define REQUEST_AUTHORIZATION     (REQUEST_RESERVED_BASE+2)

/* LED related requests */
#define REQUEST_LED_BASE           (1000)
#define REQUEST_LED_GET_TRIGGER    (REQUEST_LED_BASE)
#define REQUEST_LED_SET_TRIGGER    (REQUEST_LED_BASE + 1)
#define REQUEST_LED_WRITE          (REQUEST_LED_BASE + 2)

/* GPIO requests */
#define REQUEST_GPIO_BASE          (2000)
#define REQUEST_GPIO_INIT          (REQUEST_GPIO_BASE)
#define REQUEST_GPIO_TERMINATE     (REQUEST_GPIO_BASE + 1)
#define REQUEST_GPIO_READ          (REQUEST_GPIO_BASE + 2)
#define REQUEST_GPIO_WRITE         (REQUEST_GPIO_BASE + 3)
#define REQUEST_GPIO_GET_STATUS    (REQUEST_GPIO_BASE + 4)

/* Servo and PWM requests */
#define REQUEST_PWM_BASE           (2100)
#define REQUEST_PWM_INIT           (REQUEST_PWM_BASE)
#define REQUEST_PWM_TERMINATE      (REQUEST_PWM_BASE + 1)
#define REQUEST_PWM_DUTYCYCLE      (REQUEST_PWM_BASE + 2)
#define REQUEST_PWM_FREQUENCY      (REQUEST_PWM_BASE + 3)
#define REQUEST_SERVO_INIT         (REQUEST_PWM_BASE + 4)
#define REQUEST_SERVO_WRITE        (REQUEST_PWM_BASE + 5)
#define REQUEST_SERVO_TERMINATE    (REQUEST_PWM_BASE + 6)

/* I2C Requests */
#define REQUEST_I2C_BASE           (3000)
#define REQUEST_I2C_BUS_AVAILABLE  (REQUEST_I2C_BASE)
#define REQUEST_I2C_INIT           (REQUEST_I2C_BASE+1)
#define REQUEST_I2C_READ           (REQUEST_I2C_BASE+2)
#define REQUEST_I2C_WRITE          (REQUEST_I2C_BASE+3)
#define REQUEST_I2C_TERMINATE      (REQUEST_I2C_BASE+4)
#define REQUEST_I2C_READ_REGISTER  (REQUEST_I2C_BASE+5)
#define REQUEST_I2C_WRITE_REGISTER (REQUEST_I2C_BASE+6)

/* SPI Requests */
#define REQUEST_SPI_BASE           (4000)
#define REQUEST_SPI_INIT           (REQUEST_SPI_BASE)
#define REQUEST_SPI_TERMINATE      (REQUEST_SPI_BASE+1)
#define REQUEST_SPI_WRITEREAD      (REQUEST_SPI_BASE+2)
#define REQUEST_SPI_READ_REGISTER  (REQUEST_SPI_BASE+3)
#define REQUEST_SPI_WRITE_REGISTER (REQUEST_SPI_BASE+4)

/* Serial Requests */
#define REQUEST_SERIAL_BASE        (5000)
#define REQUEST_SERIAL_INIT        (REQUEST_SERIAL_BASE)
#define REQUEST_SERIAL_READ        (REQUEST_SERIAL_BASE+1)
#define REQUEST_SERIAL_WRITE       (REQUEST_SERIAL_BASE+2)
#define REQUEST_SERIAL_TERMINATE   (REQUEST_SERIAL_BASE+3)

/* CameraBoard Requests */
#define REQUEST_CAMERABOARD_BASE       (6000)
#define REQUEST_CAMERABOARD_INIT       (REQUEST_CAMERABOARD_BASE)
#define REQUEST_CAMERABOARD_TERMINATE  (REQUEST_CAMERABOARD_BASE+1)
#define REQUEST_CAMERABOARD_SNAPSHOT   (REQUEST_CAMERABOARD_BASE+2)
#define REQUEST_CAMERABOARD_CONTROL    (REQUEST_CAMERABOARD_BASE+3)

/*Joystick Requests */
#define REQUEST_JOYSTICK_BASE           (7000)
#define REQUEST_JOYSTICK_INIT           (REQUEST_JOYSTICK_BASE+1)
#define REQUEST_JOYSTICK_READ           (REQUEST_JOYSTICK_BASE+2)

/*frame Buffer*/
#define REQUEST_FRAMEBUFFER_BASE           (7500)
#define REQUEST_FRAMEBUFFER_INIT           (REQUEST_FRAMEBUFFER_BASE+1)
#define REQUEST_FRAMEBUFFER_WRITEPIXEL     (REQUEST_FRAMEBUFFER_BASE+2)
#define REQUEST_FRAMEBUFFER_DISPLAYIMAGE   (REQUEST_FRAMEBUFFER_BASE+3)
#define REQUEST_FRAMEBUFFER_DISPLAYMESSAGE (REQUEST_FRAMEBUFFER_BASE+4)

/* Webcam requests */
#define REQUEST_WEBCAM_BASE        (9900)
#define REQUEST_WEBCAM_INIT        (REQUEST_WEBCAM_BASE)
#define REQUEST_WEBCAM_SNAPSHOT    (REQUEST_WEBCAM_BASE + 1)
#define REQUEST_WEBCAM_TERMINATE   (REQUEST_WEBCAM_BASE + 2)

#ifdef __cplusplus
}
#endif
#endif 
