/* Copyright 2018 The MathWorks, Inc. */
#include <stdio.h>
#include "common.h"
#include "handler.h"

/** udpReadThread:- Thread function for udp data Read.
  * arg:- pointer to struct peripheralData strcuture.
  * It return Null pointer on sucessfull closing the thread.
**/
extern void *udpReadThread(void  *pData );

/** waitonFdWithTimeout:- having implemenattion of select system call in case no Data is available on port.
  * sock:- File descriptor of socket.
  * timeoutInSeconds:- time to wait for unblock the reacvfrom system call.
  * It returns the time remaining.
**/
extern int waitonFdWithTimeout(int sock, unsigned long timeoutInSeconds);


unsigned long long timeDiff(struct timespec *, struct timespec *);

/** struct udpData :- This structure store udp data recived from the udp port in case of logType is 1.
  * data:- Pointer to data memory.
  * offset:- Store the value of offset in the entire allocated memory.
  * next:- Self referencial structure to maintain the link list of memory.
**/
struct udpData{
    unsigned char *data ;
    unsigned int offset;
    struct udpData *next;
};
