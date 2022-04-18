/*
 * Copyright 2014-2016 The MathWorks, Inc.
 *
 * File: rtiostream_raspi_tcpip.c     
 *
 * Abstract: This source file implements both client-side and server-side TCP/IP
 *  communication. Typically, this driver is used to support host-target
 *  communication where the client-side device driver runs on the host and the
 *  server-side driver runs on the target. For this implementation, both
 *  client-side and server-side driver code has been combined into a single
 *  file.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <limits.h>
#include "rtiostream.h"

# include <signal.h>
# include <sys/time.h>      
# include <sys/types.h>     
# include <sys/socket.h>
# include <netinet/in.h>    
# include <netinet/tcp.h>   
# include <arpa/inet.h>     
# include <netdb.h>
# include <errno.h>
# include <fcntl.h>  
# include <unistd.h>

# include <strings.h>
#if defined(_VX_TOOL_FAMILY)
#include <sockLib.h>
#endif

#ifdef USE_MEXPRINTF
#include "mex.h"
#define printf mexPrintf
#define SERVER_PORT_PRINTF(FORMAT, ARG1) mexPrintf(FORMAT, ARG1)
#else
/* If stdout is redirected to file, it is essential that the port number is 
 * available immediately in the output file. With LCC, printf does not flush 
 * correctly to the redirected output file - use fprintf & fflush instead. */
#define SERVER_PORT_PRINTF(FORMAT, ARG1) fprintf(stdout, FORMAT, ARG1); \
                                         fflush(stdout)
#endif

/***************** DEFINES ****************************************************/

#define SERVER_STREAM_ID (1) /* Allow a single server-side connection */

#define HOSTNAME_MAXLEN (64U)

#define SERVER_PORT_NUM  (17725U)   /* sqrt(pi)*10000 */

#define  TMP_BUF_SIZ (40)

#define DEFAULT_RECV_TIMEOUT_SECS (1)

/* 
 * EXT_BLOCKING  
 *
 * Depending on the implementation of the main program (e.g., grt_main.c,
 * rt_main.c), the EXT_BLOCKING flag must be set to either 0 or 1.
 *
 * rt_main.c (tornado/vxworks): rt_main.c is a real-time, multi-tasking target.
 * The upload and packet servers are called via background (low priority) tasks.
 * In this case, it is o.k. for the transport function to block as the blocked
 * tasks will simply be pre-empted in order to enable the model to run.  It is
 * desirable to block instead of to poll to free up the cpu for any other
 * potential work. 
 */
# define EXT_BLOCKING (0)  

# define INVALID_SOCKET (-1)
# define SOCK_ERR (-1)

  typedef int SOCKET;

/***************** TYPEDEFS **************************************************/

typedef struct ServerCommsData_tag {
    int     port;
    SOCKET    listenSock; /* listening socket to accept incoming connections */
    SOCKET    sock;       /* socket to send/receive packets */ 
} ServerCommsData;

/**************** LOCAL DATA *************************************************/

static ServerCommsData ServerData = {SERVER_PORT_NUM, INVALID_SOCKET, INVALID_SOCKET};
static unsigned int Blocking = EXT_BLOCKING;
static unsigned int RecvTimeoutSecs = DEFAULT_RECV_TIMEOUT_SECS;

/************** LOCAL FUNCTION PROTOTYPES ************************************/

static int socketDataSet(
    const SOCKET sock,
    const void *src,
    const size_t size,
    size_t *sizeSent);

static int socketDataGet(
    const SOCKET   sock,
    char          *dst,
    const size_t   size,
    size_t        *sizeRecvd);

static int socketDataPending(
    const SOCKET sock,
    int    *outPending,
    unsigned int timeoutSecs);

static int serverStreamRecv( 
    void * dst,
    size_t size,
    size_t * sizeRecvd);

static int serverStreamOpen(void);

static SOCKET serverOpenConnection(void);

static int processArgs(
    const int      argc,
    void         * argv[],
    char        ** hostName, 
    unsigned int * portNum,
    unsigned int * isClient,
    unsigned int * isBlocking,
    unsigned int * recvTimeout);

/*************** LOCAL FUNCTIONS **********************************************/

/* Function: socketDataPending =================================================
 * Abstract:
 *  Returns true, via the 'pending' arg, if data is pending on the comm line.
 *  Returns false otherwise.
 *
 *  RTIOSTREAM_NO_ERROR is returned on success, RTIOSTREAM_ERROR on failure.
 */
static int socketDataPending(
    const SOCKET sock,
    int    *outPending, 
    unsigned int timeoutSecs)
{
    fd_set          ReadFds;
    int             pending;
    struct timeval  tval;
    int retVal = RTIOSTREAM_NO_ERROR;
    
    FD_ZERO(&ReadFds);
    FD_SET(sock, &ReadFds);

    tval.tv_sec  = timeoutSecs;
    tval.tv_usec = 0;

    /*
     * Casting the first arg to int removes warnings on windows 64-bit
     * platform.  It is safe to cast a SOCKET to an int here because on
     * linux SOCKET is typedef'd to int and on windows the first argument
     * to select is ignored (so it doesn't matter what the value is).
     */
    pending = select((int)(sock + 1), &ReadFds, NULL, NULL, &tval);
    if (pending == SOCK_ERR) {
        retVal = RTIOSTREAM_ERROR;
    }

    *outPending = (pending==1);
    return(retVal);    

} /* end socketDataPending */ 


/* Function: socketDataGet =====================================================
 * Abstract:
 *  Attempts to gets the specified number of bytes from the specified socket.
 *  The number of bytes read is returned via the 'sizeRecvd' parameter.
 *  RTIOSTREAM_NO_ERROR is returned on success, RTIOSTREAM_ERROR is returned on
 *  failure.
 *
 * NOTES:
 *  o it is not an error for 'sizeRecvd' to be returned as 0
 *  o this function blocks if no data is available
 */
static int socketDataGet(
    const SOCKET   sock,
    char          *dst,
    const size_t   size,
    size_t        *sizeRecvd)
{
    int nRead;
    int retVal;

    nRead = recv(sock, dst, (int)size, 0U);

    if (nRead == SOCK_ERR) {
        retVal = RTIOSTREAM_ERROR;
    } else {
        retVal = RTIOSTREAM_NO_ERROR;
    }

    if (retVal!=RTIOSTREAM_ERROR) {
        *sizeRecvd = (size_t) nRead;
    }

    return retVal;
} /* end socketDataGet */ 


/* Function: socketDataSet =====================================================
 * Abstract:
 *  Utility function to send data via the specified socket
 */
static int socketDataSet(
    const SOCKET sock,
    const void *src,
    const size_t size,
    size_t *sizeSent)
{
    int nSent;    
    int sizeLim;
    int retVal = RTIOSTREAM_NO_ERROR;
    
    /* Ensure size is not out of range for socket API send function */
    if (size > (size_t) INT_MAX) {
        sizeLim = INT_MAX;
    } else {
        sizeLim = (int) size;
    }

    nSent = send(sock, src, sizeLim, 0);

    if (nSent == SOCK_ERR) {
        retVal = RTIOSTREAM_ERROR;
    } else { 
        *sizeSent = (size_t)nSent;
    }

    return retVal;
}

/* Function: serverStreamRecv =================================================
 * Abstract:
 *  Send data from the server-side
 */
static int serverStreamRecv( 
    void * dst,
    size_t size,
    size_t * sizeRecvd)
{
    int retVal = RTIOSTREAM_NO_ERROR;
    int pending = 1;

    *sizeRecvd = 0;

    if (ServerData.sock == INVALID_SOCKET) {
        
        /* Attempt to open connection */
        ServerData.sock = serverOpenConnection();
    }   

    if (ServerData.sock != INVALID_SOCKET) {
        
        if (Blocking==0) {
            retVal = socketDataPending(ServerData.sock, &pending, 0);
        }
        
        if ( (pending !=0) && (retVal==RTIOSTREAM_NO_ERROR) && (size>0) ) {
            
            retVal = socketDataGet(ServerData.sock, (char *)dst, size, sizeRecvd);
            
            if (*sizeRecvd == 0) { /* Connection closed gracefully by client */
                
                close(ServerData.sock);
                ServerData.sock = INVALID_SOCKET;
            }
        }
        
        if ( retVal == RTIOSTREAM_ERROR ) {
            
            close(ServerData.sock);
            ServerData.sock = INVALID_SOCKET;
        }
    }

    return retVal;
}

/* Function: serverStreamOpen =================================================
 * Abstract:
 *  Opens the listening socket to be used for accepting an incoming connection.
 */
static int serverStreamOpen(void)
{

    struct sockaddr_in serverAddr;
    int sockStatus;

    int sFdAddSize     = (int) sizeof(struct sockaddr_in);

    SOCKET lFd         = ServerData.listenSock;
    int option         = 1;     
    int streamID       = SERVER_STREAM_ID;

    
    if (lFd == INVALID_SOCKET) {
        /*
         * Create a TCP-based socket.
         */
        memset((void *) &serverAddr,0,(size_t)sFdAddSize);
        serverAddr.sin_family      = AF_INET;
        serverAddr.sin_port        = htons((unsigned short int) ServerData.port);
        serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
        
        lFd = socket(AF_INET, SOCK_STREAM, 0);

        if (lFd == INVALID_SOCKET) {
            printf("socket() call failed.\n");
        } else {
            /*
             * Listening socket should always use the SO_REUSEADDR option
             * ("Unix Network Programming - Networking APIs:Sockets and XTI",
             *   Volume 1, 2nd edition, by W. Richard Stevens).
             */
            sockStatus = 
                setsockopt(lFd,SOL_SOCKET,SO_REUSEADDR,(char*)&option,sizeof(option));
            if (sockStatus == SOCK_ERR) {
                printf("setsocketopt() call failed.\n");
                close(lFd);
                lFd = INVALID_SOCKET;
            }
            /* Disable Nagle's Algorithm*/ 
            sockStatus = 
            setsockopt(lFd,IPPROTO_TCP,TCP_NODELAY,(char*)&option,sizeof(option));
            if (sockStatus == SOCK_ERR) { 
                printf("setsocketopt() TCP_NODELAY call failed.\n");
                close(lFd); 
                lFd = INVALID_SOCKET; 
            } 
        }
        
        if (lFd != INVALID_SOCKET) {
            sockStatus = bind(lFd, (struct sockaddr *) &serverAddr, sFdAddSize);
            if (sockStatus == SOCK_ERR) {
                printf("bind() call failed: %s\n", strerror(errno));
                close(lFd);
                lFd = INVALID_SOCKET;
            }
        }
        
        if (lFd != INVALID_SOCKET) {
            if (ServerData.port == 0) {
               /* port 0 specifies dynamic free port allocation
                * reuse serverAddr to store the actual address / port */
               sockStatus = getsockname(lFd, (struct sockaddr *) &serverAddr, &sFdAddSize);           
               if (sockStatus == SOCK_ERR) {
                  fprintf(stderr,"getsockname() call failed: %s\n", strerror(errno));
                  close(lFd);
                  lFd = INVALID_SOCKET;               
               }
               else {                  
                  /* write the server port number to stdout */
                  SERVER_PORT_PRINTF("Server Port Number: %u\n", ntohs(serverAddr.sin_port));
               }                 
            }
        }

        if (lFd != INVALID_SOCKET) {
            sockStatus = listen(lFd, 2);
            if (sockStatus == SOCK_ERR) {
                printf("listen() call failed.\n");
                close(lFd);
                lFd = INVALID_SOCKET;
            }
        }
        ServerData.listenSock = lFd;
    }

    if (lFd == INVALID_SOCKET) {
        streamID = RTIOSTREAM_ERROR;
    }
    return streamID;

}
/* Function: serverOpenConnection =================================================
 * Abstract:
 *  Called when the target is not currently connected to the host, this 
 *  function attempts to open the connection.  
 *
 *  In the case of sockets, this is a passive operation in that the host
 *  initiates contact, the target simply listens for connection requests.
 *
 * NOTES:
 
 * Blocks if Blocking == 1, poll for pending connections otherwise. When
 * polling, there may be no open requests pending.  In this case, this
 * function returns without making a connection; this is not an error.
 */
static SOCKET serverOpenConnection(void)
{
    struct sockaddr_in clientAddr;
    int     sFdAddSize     = (int) sizeof(struct sockaddr_in);
    SOCKET  cFd            = INVALID_SOCKET;
    SOCKET  lFd            = ServerData.listenSock;
    int error             = RTIOSTREAM_NO_ERROR;
    int pending            = 1;

    /* Check that the listening socket is still valid and open a new socket if
     * not */
    if (lFd == INVALID_SOCKET) {
        serverStreamOpen();
        lFd = ServerData.listenSock;
    }

    if (Blocking==0) {
        error = socketDataPending(lFd, &pending, 0);
    }
    
    
    if ( (pending > 0) && (error==RTIOSTREAM_NO_ERROR) ) {

        /*
         * Wait to accept a connection on the comm socket.
         */
        cFd = accept(lFd, (struct sockaddr *)&clientAddr,
                     &sFdAddSize);
        
        if (cFd == INVALID_SOCKET) {
            printf("accept() for comm socket failed.\n");
            error = RTIOSTREAM_ERROR;
        } 

        if (error == RTIOSTREAM_ERROR) {
            close(ServerData.listenSock);
            ServerData.listenSock = INVALID_SOCKET;
        } 
    }

    return cFd;
} 

/* Function: processArgs ====================================================
 * Abstract:
 *  Process the arguments specified by the user when opening the rtIOStream.
 *      
 *  If any unrecognized options are encountered, ignore them.
 *
 * Returns zero if successful or RTIOSTREAM_ERROR if 
 * an error occurred.
 *
 *  o IMPORTANT!!!
 *    As the arguments are processed, their strings should be NULL'd out in
 *    the argv array. 
 */
static int processArgs(
    const int      argc,
    void         * argv[],
    char        ** hostName, 
    unsigned int * portNum,
    unsigned int * isClient,
    unsigned int * isBlocking,
    unsigned int * recvTimeout)
{
    int        retVal    = RTIOSTREAM_NO_ERROR;
    int        count           = 0;

    while(count < argc) {
        const char *option = (char *)argv[count];
        count++;

        if (option != NULL) {

            if ((strcmp(option, "-hostname") == 0) && (count != argc)) {

                *hostName = (char *)argv[count];
                count++;
                argv[count-2] = NULL;
                argv[count-1] = NULL;

            } else if ((strcmp(option, "-port") == 0) && (count != argc)) {
                char       tmpstr[2];
                int itemsConverted;
                const char *portStr = (char *)argv[count];

                count++;     
                
                itemsConverted = sscanf(portStr,"%d%1s", (int *) portNum, tmpstr);
                if ( (itemsConverted != 1) || 
                     ( ((*portNum != 0) && (*portNum < 255)) || (*portNum > 65535)) 
                    ) {
                    
                    retVal = RTIOSTREAM_ERROR;
                } else {

                    argv[count-2] = NULL;
                    argv[count-1] = NULL;
                }           
                
            } else if ((strcmp(option, "-client") == 0) && (count != argc)) {
                
                *isClient = ( strcmp( (char *)argv[count], "1") == 0 );

                count++;
                argv[count-2] = NULL;
                argv[count-1] = NULL;

            } else if ((strcmp(option, "-blocking") == 0) && (count != argc)) {
                
                *isBlocking = ( strcmp( (char *)argv[count], "1") == 0 );

                count++;
                argv[count-2] = NULL;
                argv[count-1] = NULL;

            } else if ((strcmp(option, "-recv_timeout_secs") == 0) && (count != argc)) {
                char       tmpstr[2];
                int itemsConverted;
                const char *timeoutSecsStr = (char *)argv[count];

                count++;     
                
                itemsConverted = sscanf(timeoutSecsStr,"%d%1s", (int *) recvTimeout, tmpstr);
                if ( itemsConverted != 1 ) {
                    retVal = RTIOSTREAM_ERROR;
                } else {

                    argv[count-2] = NULL;
                    argv[count-1] = NULL;
                }           

            } else {
                /* do nothing */
            }
        }
    }
    return retVal;
}

/***************** VISIBLE FUNCTIONS ******************************************/

/* Function: rtIOStreamOpen =================================================
 * Abstract:
 *  Open the connection with the target.
 */
int rtIOStreamOpen(int argc, void * argv[])
{
    char               *xHostName = NULL;
    unsigned int        xPortNum     = (SERVER_PORT_NUM);
    unsigned int        isClient = 0;
    int result = RTIOSTREAM_NO_ERROR;
    int streamID = RTIOSTREAM_ERROR;

    Blocking = EXT_BLOCKING; /* Set default value */

    processArgs(argc, argv, &xHostName, &xPortNum, &isClient, &Blocking,
        &RecvTimeoutSecs);    

    if (result != RTIOSTREAM_ERROR) {
        if (isClient == 1) {

        } else {
            ServerData.port = xPortNum;
            ServerData.sock = INVALID_SOCKET;
            streamID = serverStreamOpen();
        }
    }
    return streamID;
}

/* Function: rtIOStreamSend =====================================================
 * Abstract:
 *  Sends the specified number of bytes on the comm line. Returns the number of
 *  bytes sent (if successful) or a negative value if an error occurred. As long
 *  as an error does not occur, this function is guaranteed to set the requested
 *  number of bytes; the function blocks if tcpip's send buffer doesn't have
 *  room for all of the data to be sent
 */
int rtIOStreamSend(
    int streamID,
    const void *src,
    size_t size,
    size_t *sizeSent)
{
    int retVal;

    if (streamID == SERVER_STREAM_ID) {
        if (ServerData.sock == INVALID_SOCKET) {

            ServerData.sock = serverOpenConnection();

        }
    
        retVal = socketDataSet(ServerData.sock, src, size, sizeSent);

    } else { /* Client stream */

        SOCKET sock = (SOCKET) streamID;
        retVal = socketDataSet(sock, src, size, sizeSent);

    }
    return retVal;
}


/* Function: rtIOStreamRecv ================================================
 * Abstract: receive data
 *
 */
int rtIOStreamRecv(
    int      streamID,
    void   * dst, 
    size_t   size,
    size_t * sizeRecvd) 
{
    int retVal = RTIOSTREAM_NO_ERROR;

    if (streamID == SERVER_STREAM_ID) {

        retVal = serverStreamRecv(dst, size, sizeRecvd); 

    } else { /* Client stream */

        int pending = 1;
        SOCKET cSock = (SOCKET) streamID;

        {
            unsigned int timeout=0;
            if (Blocking == 0) {
                timeout = 0;
            } else {
                timeout = RecvTimeoutSecs;
            }
            retVal = socketDataPending(cSock,&pending,timeout);
        }

        if (pending==0) {
            *sizeRecvd = 0U;
        } else {
            retVal = socketDataGet(cSock, (char *)dst, size, sizeRecvd);
        }
    }

    return retVal;
}


/* Function: rtIOStreamClose ================================================
 * Abstract: close the connection.
 *
 */
int rtIOStreamClose(int streamID)
{
    int retVal = RTIOSTREAM_NO_ERROR;
    
    if (streamID == SERVER_STREAM_ID) {
        char * tmpBuf[TMP_BUF_SIZ];
        int numRecvd;
        numRecvd = recv( ServerData.sock, (void *) tmpBuf, TMP_BUF_SIZ, 0);
        while (numRecvd > 0) {
            numRecvd = recv( ServerData.sock, (void *) tmpBuf, TMP_BUF_SIZ, 0);
        }
        close(ServerData.sock);
        ServerData.sock = INVALID_SOCKET;

        close(ServerData.listenSock);

        ServerData.listenSock = INVALID_SOCKET;

    } else {
        SOCKET cSock = (SOCKET) streamID;
        close(cSock);
        
    }

    return retVal;
}

