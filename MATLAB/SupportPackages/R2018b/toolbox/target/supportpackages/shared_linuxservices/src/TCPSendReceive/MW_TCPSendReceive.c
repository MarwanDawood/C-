#include "MW_TCPSendReceive.h"

#ifndef MW_TCP_DEFAULT_TIMEOUT
#define MW_TCP_DEFAULT_TIMEOUT 0.0
#endif

#if ( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
/* This will be run in Rapid Accelerator Mode*/
#include <stdint.h> /* int types */
#include <stddef.h> /* size_t on Mac */

void TCPStreamSetup(uint16_t portNumber, uint16_t localClientPort, uint16_t *connStream, uint16_t server, double blockingTimeout, int16_t *errorNo, char *hostName) {}
void littleEndianCheck(uint8_t *isLittleEndian) {}
void TCPStreamStepSend(void *dataIn, size_t dataInSize, uint16_t connStream, uint16_t isSer, int16_t *errorNo) {}
void TCPStreamStepRecv(void *msgRec, int8_t *recvStatus, size_t dataSizeToRead, uint16_t connStream, int16_t *errorNo,uint16_t isSer) {}

#else
/* This will be run in Normal/External Mode*/

/* Local data */
static ConnectionInfo connectionInfoArray[MAX_NUM_CONNECTIONS];

/* Local function prototypes */
static int16_t initTCPConnection(int connectionID,
                                 ConnectionMode operMode,
                                 SOCKET sock,
                                 double blockingTimeout,
                                 uint16_t portNumber,
                                 char *hostName,
                                 uint16_t localClientPort);

static uint16_t getConnectionIdx(void);

ConnectionInfo * getConnectionInfo(int connectionID);

static void freeConnection(ConnectionInfo *connection);

static int16_t socketDataSend(
                              ConnectionInfo *connection,
                              const void *src,
                              const size_t size);

static int16_t socketDataRecv(
                              ConnectionInfo *connection,
                              void *dst,
                              size_t size,
                              int8_t *recvStatus);

static int checkSocketPending(
                              const SOCKET sock,
                              int *outPending,
                              double blockingTimeout);

static SOCKET createListenSocket(uint16_t port, int16_t *errorNo);

static SOCKET createClientSocket(char *hostName, uint16_t portNum, uint16_t clientPortToBind, int16_t *errorNo);

static int serverAcceptConnection(ConnectionInfo *connection);

static unsigned long hostnameLookup(char *hostName);

static int8_t connectionLookup(char *hostName, uint16_t port);

void setTimeoutForSocket(int sockfd, double timeout);

void setReceiveBufferSize(int sock, int32_t ReceiveBufferSize);
void setSendBufferSize(int sock,int32_t SendBufferSize);

/* Local functions */
void waitForConnection(uint16_t streamID) {
    struct timespec timeToWait;
    struct timeval now;
    double blockingTimeout;
    ConnectionInfo *cliConn = getConnectionInfo(streamID);
    
    gettimeofday(&now,NULL);
    if (cliConn->blockingTimeout < 0)
    {
        blockingTimeout = MW_TCP_DEFAULT_TIMEOUT;
    }
    else
    {
        blockingTimeout = cliConn->blockingTimeout;
    }
    
    timeToWait.tv_sec = now.tv_sec + floor(blockingTimeout);
    timeToWait.tv_nsec = (now.tv_usec + ((blockingTimeout - floor(blockingTimeout))*pow(10,6)))*1000UL;
    
    LOG(LOG_DEBUG,"waitForConnection: lock mutex\n");
    pthread_mutex_lock(&cliConn->connect_mutex);
    LOG(LOG_DEBUG,"calling pthread_cond_timedwait\n");
    pthread_cond_timedwait(&cliConn->connect_cv, &cliConn->connect_mutex, &timeToWait);
    LOG(LOG_DEBUG,"pthread_cond_timedwait finished. Unlock the mutex\n");
    pthread_mutex_unlock(&cliConn->connect_mutex);
}

int checkDataAvailable(ConnectionInfo *connection, size_t size) {
    int dataAvailable = 0;
    struct timeval timeNow;
    double blockingTimeout,startTime,currentTime,diffTime;
    if (connection->blockingTimeout < 0)
    {
        connection->blockingTimeout = MW_TCP_DEFAULT_TIMEOUT;
    }
    else
    {
        blockingTimeout = connection->blockingTimeout;
    }
    
    gettimeofday(&timeNow,NULL);
    startTime = timeNow.tv_sec+(timeNow.tv_usec/1000000.0);
    LOG(LOG_DEBUG, "checkDataAvailable: start while loop for waiting %f streamID = %d\n",blockingTimeout,connection->streamID);
    do {
        ioctl(connection->sock, FIONREAD, &dataAvailable);
        /*LOG(LOG_DEBUG,"dataAvailable at recv buff = %d",dataAvailable);*/
        if(dataAvailable >= size)
            break;
        usleep(1000);
        gettimeofday(&timeNow,NULL);
        currentTime = timeNow.tv_sec+(timeNow.tv_usec/1000000.0);
        diffTime = currentTime - startTime;
        /*LOG(LOG_DEBUG,"while loop running difftime = %f, dataAvailable = %d",diffTime,dataAvailable);*/
    } while(diffTime < blockingTimeout);
    return dataAvailable;
}

/* Function: initTCPConnection
 * Initialize a client-server connection
 * A return value of TCPSTREAM_ERROR indicates an error.
 */
static int16_t initTCPConnection(int connectionID,
                                 ConnectionMode operMode,
                                 SOCKET sock,
                                 double blockingTimeout,
                                 uint16_t portNumber,
                                 char *hostName,
                                 uint16_t localClientPort) {
    int16_t retVal = TCPSTREAM_NO_ERROR;
    ConnectionInfo *connection = &connectionInfoArray[connectionID];
    
    /* initialize the new ConnectionInfo */
    connection->isInUse = 1;
    connection->operMode = operMode;
    if (1 == isinf(blockingTimeout))
    {
        connection->blockingTimeout = (double)INT_MAX/1000.0;
    }
    else
    {
        connection->blockingTimeout = blockingTimeout;
    }
    /* initialize to NULL early so that calls to
     * freeConnection on error will succeed */
    connection->serverData = NULL;
    connection->SendBufferSize = -1;
    connection->ReceiveBufferSize = -1;
    
    if (operMode == SERVER_MODE) {
        /* initialize server data */
        connection->serverData = (ServerData *)malloc(sizeof(ServerData));
        if (connection->serverData == NULL) {
            LOG(LOG_INFO, "initTCPConnection: serverData malloc failed\n");
            freeConnection(connection);
            retVal = TCP_ERR_NOCONN_SERVER;
            return retVal;
        }
        connection->serverData->port = portNumber;
        /* provided sock is the listening sock */
        connection->serverData->listenSock = sock;
        /* later call to serverAcceptConnection will set sock */
        connection->sock = INVALID_SOCKET;
        /*
         *Save this info to reuse the connection.
         * g1502287
         */
        connection->remotePort = portNumber;
        sprintf(connection->remoteHost,"%s",hostName);
    } else {
        /* store the provided socket */
        connection->sock = INVALID_SOCKET;
        connection->clientSock = sock;
        connection->remotePort = portNumber;
        sprintf(connection->remoteHost,"%s",hostName);
        connection->localClientPort = localClientPort;
    }
    LOG(LOG_INFO, "Connection id %d \n", connectionID);
    
    /* display the size of the socket receive buffer */
    socklen_t optionLen = sizeof(int);
    int optionValue;
    getsockopt(sock, SOL_SOCKET, SO_SNDBUF, (char *) &optionValue, &optionLen);
    LOG(LOG_INFO, "Connection id %d, SendBufSize: %d \n", connectionID, optionValue);
    getsockopt(sock, SOL_SOCKET, SO_RCVBUF, (char *) &optionValue, &optionLen);
    LOG(LOG_INFO, "Connection id %d, RecvBufSize: %d \n", connectionID, optionValue);
    
    LOG(LOG_INFO, "Connection id %d, blockingTimeout: %f \n", connectionID,
        connection->blockingTimeout);
    if (connection->operMode == SERVER_MODE)
        LOG(LOG_INFO, "Connection id %d, type: server \n", connectionID);
    else
        LOG(LOG_INFO, "Connection id %d, type: client \n", connectionID);
    
    LOG(LOG_INFO, "Connection id %d, socket id %d \n", connectionID, (int) sock);
    /* relevant to both clients and servers */
    LOG(LOG_INFO, "Connection id %d, server port: %d \n", connectionID, portNumber);
    return retVal;
}

/* Function: getConnectionInfo
 * Retrieve a ConnectionInfo instance given its connectionID
 * (as returned by initTCPConnection)
 * NOTE: An invalid connectionID will lead to a NULL pointer being returned
 */
ConnectionInfo * getConnectionInfo(int connectionID) {
    /* return NULL for invalid or uninitialized connectionIDs */
    /*LOG(LOG_INFO,"getConnectionInfo form streamid = %d \n",connectionID);*/
    ConnectionInfo *connection = NULL;
    if ((connectionID >= 0) && (connectionID < MAX_NUM_CONNECTIONS)) {
        if (connectionInfoArray[connectionID].isInUse)
            connection = &connectionInfoArray[connectionID];
        else
            LOG(LOG_INFO, "getConnectionInfo: connection not in use.\n");
    }
    return connection;
}

/* Function: getConnectionIdx
 * Returns a connectionID corresponding to a ConnectionInfo that is not
 * already in use.
 * A TCPSTREAM_ERROR will be returned if all available ConnectionInfo instances
 * are already in use.
 */
static uint16_t getConnectionIdx(void) {
    uint16_t connectionID;
    int foundUnusedConnectionInfo = 0;
    /* linear search for an unused ConnectionInfo */
    for (connectionID = 0; connectionID < MAX_NUM_CONNECTIONS; connectionID++) {
        if (!connectionInfoArray[connectionID].isInUse) {
            foundUnusedConnectionInfo = 1;
            break;
        }
    }
    if (!foundUnusedConnectionInfo) {
        /* all ConnectionInfo's are in use */
        LOG(LOG_INFO, "getConnectionIdx: all %d available connections are in use\n", MAX_NUM_CONNECTIONS);
        connectionID = TCPSTREAM_ERROR;
    }
    LOG(LOG_INFO, "getConnectionIdx: id = %d\n", connectionID);
    return connectionID;
}

/* Function: freeConnection
 * Frees memory associated with the ConnectionInfo referenced by connectionID.
 * Marks the ConnectionInfo instance as no longer in use.
 */
static void freeConnection(ConnectionInfo *connection) {
    /* mark the ConnectionInfo as not in use */
    connection->isInUse = 0;
    connection->blockingTimeout = -1;
    connection->sock = -1;
    connection->clientSock = -1;
    /* free dynamic memory */
    if (connection->operMode == SERVER_MODE) {
        free(connection->serverData);
        connection->serverData = NULL;
    }
}


/* Function: checkSocketPending
 *  Returns true, via the 'pending' arg, if data is pending on the comm line.
 *  Returns false otherwise.
 *  TCPSTREAM_NO_ERROR is returned on success, TCPSTREAM_ERROR on failure.
 */
static int checkSocketPending(
                              const SOCKET sock,
                              int *outPending,
                              double blockingTimeout) {
    fd_set ReadFds;
    int pending;
    struct timeval tval;
    struct timeval *tvalPtr;
    int retVal = TCPSTREAM_NO_ERROR;
    
    FD_ZERO(&ReadFds);
    FD_SET(sock, &ReadFds);
    LOG(LOG_INFO, "checkSocketPending: blockingTimeout = %f\n", blockingTimeout);


    //if(blockingTimeout < 0)
    if (1 == isinf(blockingTimeout))
        tvalPtr = NULL; /*infinite blocking - specify NULL ptr*/
    else {
        if (blockingTimeout < 0)
        {
            blockingTimeout = MW_TCP_DEFAULT_TIMEOUT;
        }
        tval.tv_sec = floor(blockingTimeout);
        tval.tv_usec = (blockingTimeout - floor(blockingTimeout))*pow(10,6);
        tvalPtr = &tval;
    }
    
    pending = select((int)(sock + 1), &ReadFds, NULL, NULL, tvalPtr);
    if (pending == SOCK_ERR)
        retVal = TCPSTREAM_ERROR;
    *outPending = (pending==1);
    return (retVal);
}

/* Function: socketDataRecv
 *  Attempts to gets the specified number of bytes from the specified socket.
 *  The number of bytes read is returned via the 'recvStatus' parameter.
 *  TCPSTREAM_NO_ERROR is returned on success, TCPSTREAM_ERROR is returned on
 *  failure.
 */
static int16_t socketDataRecv(ConnectionInfo *connection, void *dst, size_t size, int8_t *recvStatus) {
    
    size_t nRead = 0;
    int16_t retVal = TCPSTREAM_NO_ERROR;
    int dataAvailable = 0;
    
    
    /* dst data type depends on block mask selection. Comment out hardcoded uint8_t*/
    /* LOG(LOG_INFO,"socketDataRecv: initial dst = %d, recvStatus = %d\n", *(uint8_t*)dst, *recvStatus);*/
    dataAvailable = checkDataAvailable(connection, size);
    
    if((size > 0) && (dataAvailable >= size)){
        /*Read from recv buffer*/
        errno = 0;
        nRead = recv(connection->sock, dst, size, 0U);
        /* dst data type depends on block mask selection. Comment out hardcoded uint8_t*/
        LOG(LOG_INFO, "socketDataRecv: dataRead = %d, nRead = %d, errno = %d\n", *(uint8_t*)dst, nRead, errno);
        if((nRead == 0) && (errno == 0)){
            /*peer disconnected. Return error to CLOSE the socket*/
            retVal = (connection->operMode ==  SERVER_MODE) ? TCP_ERR_NOCLIENT : TCP_ERR_NOSERVER;
            return retVal;
        }
        if (nRead == SOCK_ERR) {
            if(errno == ECONNRESET || errno == ENOTCONN)
                retVal = (connection->operMode ==  SERVER_MODE) ? TCP_ERR_NOCLIENT : TCP_ERR_NOSERVER;
        } else
            retVal = TCPSTREAM_NO_ERROR;
        
        if (retVal==TCPSTREAM_NO_ERROR) {
            if(nRead == size)
                *recvStatus = RECEIVE_SUCCESS; /*Received requested amount of data. Set status as 1*/
        }
    } else {
        /*Requested data not available.
         * Use recv to check connection is active or not
         */
        LOG(LOG_DEBUG, "socketDataRecv: requested data not available, check connection using recv\n");
        errno = 0;
        /* Recv with size 0 returns zero though connection is good.  So minimum expected size is always 1.
           Since, recv is called with MSG_PEEK, the recv data buffer is unchanged. */
        if (size < 1)
            size = 1;
        nRead = recv(connection->sock, dst, size,  MSG_PEEK | MSG_DONTWAIT);
        /* dst data type depends on block mask selection. Comment out hardcoded uint8_t*/
        LOG(LOG_INFO, "socketDataRecv: dataRead = %d, nRead = %d, errno = %d \n",*(uint8_t*)dst, nRead, errno);
        if((nRead == 0) && (errno == 0)){
            /*peer disconnected. Return error to CLOSE the socket*/
            retVal = (connection->operMode ==  SERVER_MODE) ? TCP_ERR_NOCLIENT : TCP_ERR_NOSERVER;
        }
        /*memset dst to zero to outupt 0*/
        memset(dst,0,size);
    }
    
    /* dst data type depends on block mask selection. Comment out hardcoded uint8_t*/
    /* LOG(LOG_INFO, "socketDataRecv: final dst = %d, recvStatus = %d\n", *(uint8_t*)dst, *recvStatus);*/
    
    return retVal;
}

/* Function: socketDataSend
 * Utility function to send data via the specified socket
 */
static int16_t socketDataSend(ConnectionInfo *connection, const void *src, const size_t size) {
    int nSent;
    int retVal = TCPSTREAM_NO_ERROR;
    const void *sendSrc = src;
    
    errno = 0;
#ifndef __APPLE__
    nSent = send(connection->sock, (send_buffer_t)sendSrc, size, MSG_NOSIGNAL);
#else
    /* For iOS, MSG_NOSIGNAL flag is not defined. We need to set SO_NOSIGPIPE via setsockopt */
    const int set = 1;
    setsockopt(connection->sock, SOL_SOCKET, SO_NOSIGPIPE, &set, sizeof(int));
    nSent = send(connection->sock, (send_buffer_t)sendSrc, size, 0);
#endif
    LOG(LOG_INFO, "socketDataSend: call to send returned: %d, errno: %d \n", nSent, errno);
    if (nSent == SOCK_ERR) {
        if (errno == ECONNRESET || errno == EPIPE || errno == ENOTCONN)
            retVal = (connection->operMode == SERVER_MODE) ? TCP_ERR_NOCLIENT : TCP_ERR_NOSERVER;
    }
    return retVal;
}

/* Function: createListenSocket
 * Opens the listening socket to be used for accepting an incoming connection.
 */
static SOCKET createListenSocket(uint16_t port, int16_t *errorNo) {
    
    struct sockaddr_in serverAddr;
    int sockStatus;
    socklen_t sFdAddSize = (socklen_t) sizeof(struct sockaddr_in);
    SOCKET lFd;
    int option;
    
    LOG(LOG_INFO, "createListenSocket: create a socket to listen for incoming connections\n");
    memset((void *) &serverAddr,0,(size_t)sFdAddSize);
    serverAddr.sin_family      = AF_INET;
    serverAddr.sin_port        = htons((unsigned short int) port);
    serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    
    lFd = socket(AF_INET, SOCK_STREAM, 0);
    
    if (lFd == INVALID_SOCKET) {
        *errorNo = TCP_ERR_NOCONN_SERVER;
        LOG(LOG_INFO, "createListenSocket: call to socket() failed\n");
    } else {
        /*
         * Listening socket should always use the SO_REUSEADDR option
         * ("Unix Network Programming - Networking APIs:Sockets and XTI",
         * Volume 1, 2nd edition, by W. Richard Stevens).
         */
        LOG(LOG_INFO, "createListenSocket: set socket option SO_REUSEADDR\n");
        option = 1;
        sockStatus =
        setsockopt(lFd,SOL_SOCKET,SO_REUSEADDR,(char*)&option,sizeof(option));
        if (sockStatus == SOCK_ERR) {
            LOG(LOG_INFO, "createListenSocket: setsocketopt() call failed\n");
            close(lFd);
            lFd = INVALID_SOCKET;
            *errorNo = TCP_ERR_NOCONN_SERVER;
        }
        
        if (lFd != INVALID_SOCKET) {
            /* Disable Nagle's Algorithm*/
            option = 1;
            sockStatus =
            setsockopt(lFd,IPPROTO_TCP,TCP_NODELAY,(char*)&option,sizeof(option));
            if (sockStatus == SOCK_ERR) {
                LOG(LOG_INFO, "createListenSocket: setsocketopt() TCP_NODELAY call failed\n");
                close(lFd);
                *errorNo = TCP_ERR_NOCONN_SERVER;
                lFd = INVALID_SOCKET;
            }
        }
    }
    
    LOG(LOG_INFO, "createListenSocket: bind socket\n");
    if (lFd != INVALID_SOCKET) {
        sockStatus = bind(lFd, (struct sockaddr *) &serverAddr, sFdAddSize);
        if (sockStatus == SOCK_ERR) {
            LOG(LOG_INFO, "createListenSocket: bind() call failed: %d\n", errno);
            close(lFd);
            lFd = INVALID_SOCKET;
            *errorNo = TCP_ERR_SOCBIND;
        }
    }
    
    LOG(LOG_INFO, "createListenSocket: listen for conncetions on socket\n");
    if (lFd != INVALID_SOCKET) {
        sockStatus = listen(lFd, 2); /*TO DO: check for backlog arg*/
        if (sockStatus == SOCK_ERR) {
            LOG(LOG_INFO, "createListenSocket: listen() call failed\n");
            close(lFd);
            lFd = INVALID_SOCKET;
            *errorNo = TCP_ERR_NOCONN_SERVER;
        }
    }
    
    return lFd;
}

/* Function: serverAcceptConnection
 *  Called when the target is not currently connected to the host, this
 *  function attempts to open the connection.
 *
 *  In the case of sockets, this is a passive operation in that the host
 *  initiates contact, the target simply listens for connection requests.
 */
static int serverAcceptConnection(ConnectionInfo *connection) {
    struct sockaddr_in clientAddr;
    socklen_t sFdAddSize = sizeof(struct sockaddr_in);
    SOCKET cFd = INVALID_SOCKET;
    int error = TCPSTREAM_NO_ERROR;
    int pending;
    
    /* Check that the listening socket is still valid and open a new socket if not */
    if (connection->serverData->listenSock == INVALID_SOCKET) {
        int16_t error = 0;
        connection->serverData->listenSock = createListenSocket(connection->serverData->port, &error);
    }
    
    /* pass listenSock rather than sock */
    LOG(LOG_INFO, "serverAcceptConnection: call checkSocketPending\n");
    error = checkSocketPending(connection->serverData->listenSock,
                               &pending,
                               connection->blockingTimeout);
    LOG(LOG_INFO, "serverAcceptConnection: pending = %d\n", pending);
    
    if ((pending > 0) && (error==TCPSTREAM_NO_ERROR)) {
        LOG(LOG_INFO, "serverAcceptConnection: wait to accept incoming connection\n");
        cFd = accept(connection->serverData->listenSock,
                     (struct sockaddr *)&clientAddr,
                     &sFdAddSize);
        
        if (cFd == INVALID_SOCKET) {
            LOG(LOG_INFO, "serverAcceptConnection: call to accept() for socket failed\n");
            error = TCPSTREAM_ERROR;
        }
        else {
            /* set sock */
            /*First client to get connected to the server.
             *assign this value within the thread. connection->sock = cFd;
             *TO DO
             *Stop further connections
             */
        }
        LOG(LOG_INFO, "serverAcceptConnection: descriptor for accepted socket, cFd = %d\n", cFd);
        
        if (error == TCPSTREAM_ERROR) {
            close(connection->serverData->listenSock);
            connection->serverData->listenSock = INVALID_SOCKET;
        }
    }
    return cFd;
}

/* Function: hostnameLookup
 * Lookup target network name.
 */
static unsigned long hostnameLookup(char *hostName) {
    
    struct hostent *hp = NULL;
    struct in_addr *iaddr = NULL;
    unsigned long addr = INADDR_NONE;
    
    /* Default to localhost if hostname not specified.*/
    if (hostName == NULL) {
        static char localhost[] = "localhost";
        hostName = localhost;
    }
    
    /*
     * See if the address is an IPV4 dot separated address:
     */
    addr = inet_addr(hostName);
    
    if (addr == INADDR_NONE) {
        /* Since the address is not an IPV4 dot separated address,
         * do a name lookup to get this:
         */
        hp = gethostbyname(hostName);
        if (hp == NULL) {
            LOG(LOG_INFO, "hostnameLookup: gethostbyname() call failed\n");
            addr = INADDR_NONE;
        } else {
            iaddr = (struct in_addr *) hp->h_addr;
            addr = iaddr->s_addr;
        }
    }
    return(addr);
}


/* Function: connectionLookup
 * Lookup for existing connections.
 */
static int8_t connectionLookup(char *hostName, uint16_t port) {
    int8_t i, streamIndex = -1;
    if (hostName == NULL) return streamIndex;
    
    for(i = 0; i < MAX_NUM_CONNECTIONS; i++) {
        if(connectionInfoArray[i].isInUse == 1) {
            if((strcmp(connectionInfoArray[i].remoteHost, hostName) == 0) && (connectionInfoArray[i].remotePort == port)){
                streamIndex = i;
                break;
            }
        }
    }
    return streamIndex;
}

/* Function: createClientSocket
 * Create a socket for client connection and bind if required
 */
static SOCKET createClientSocket(char *hostName, uint16_t portNum, uint16_t clientPortToBind, int16_t *errorNo) {
    
    struct sockaddr_in remoteAddr,localAddr;
    unsigned long addr = INADDR_NONE;
    SOCKET cSock = INVALID_SOCKET;
    addr = hostnameLookup(hostName);
    
    if(addr != INADDR_NONE) {
        remoteAddr.sin_addr.s_addr = addr;
        remoteAddr.sin_family = AF_INET; /*hp->h_addrtype;*/
        remoteAddr.sin_port   = htons((unsigned short) portNum);
        
        LOG(LOG_INFO, "createClientSocket: create client socket\n");
        cSock = socket(PF_INET,SOCK_STREAM,0);
        if (cSock == INVALID_SOCKET) {
            *errorNo = TCP_ERR_NOCONN_CLIENT;
            LOG(LOG_INFO, "createClientSocket: socket() call failed\n");
            return cSock;
        } else {
            /*bind to a local port if configured */
            if(clientPortToBind > 0){
                localAddr.sin_addr.s_addr = INADDR_ANY;
                localAddr.sin_family = AF_INET;
                localAddr.sin_port   = htons((unsigned short) clientPortToBind);
                
                if(bind(cSock, (struct sockaddr *) &localAddr, sizeof(localAddr)) < 0){
                    LOG(LOG_INFO, "createClientSocket: local port binding failed\n");
                    close(cSock);
                    *errorNo = TCP_ERR_SOCBIND;
                    return INVALID_SOCKET;
                }
            }
        }
    } else {
        /* Error in resolving host address */
        *errorNo = TCP_ERR_NOHOST;
    }
    return cSock;
}


/* Function: TCPStreamOpen
 * Open the connection with the target.
 */
int16_t TCPStreamOpen(char *hostName, uint16_t portNumer, uint16_t localClientPort, ConnectionMode operMode, uint16_t *streamID, double blockingTimeout) {
    int16_t result = TCPSTREAM_NO_ERROR;
    ConnectionInfo * connInfo;
    
    SOCKET sock = INVALID_SOCKET;
    
    /* determine the streamID for this new connection */
    *streamID = getConnectionIdx();
    if (*streamID == TCPSTREAM_ERROR)
        return TCPSTREAM_ERROR;
    
    if (result != TCPSTREAM_ERROR) {
        if (operMode == CLIENT_MODE)
            sock = createClientSocket(hostName, portNumer,localClientPort,&result);
        else
            sock = createListenSocket(portNumer, &result);
        
        if (sock != INVALID_SOCKET) {
            result = initTCPConnection(*streamID,
                                       operMode,
                                       sock,
                                       blockingTimeout,
                                       portNumer,
                                       hostName,
                                       localClientPort);
        }
    }
    
    if (result != TCPSTREAM_NO_ERROR) {
        if (sock != INVALID_SOCKET) {
            /* cleanup - better to terminate here */
            close(sock);
        }
    }
    else
    {
        /* Update connection stream id into conn structure */
        connInfo = getConnectionInfo(*streamID);
        if (connInfo != NULL)
        {
            connInfo->streamID = *streamID;
        }
    }
    return result;
}


/* Function: TCPStreamRecv
 * Abstract: Receive data
 */
int16_t TCPStreamRecv(
                      void *msgRec,
                      int8_t *recvStatus, size_t dataSizeToRead, uint16_t streamID) {
    int16_t retVal = TCPSTREAM_NO_ERROR;
    ConnectionInfo *connection = getConnectionInfo(streamID);
    LOG(LOG_DEBUG, "TCPStreamRecv: %d calling socketDataRecv\n", streamID);
    retVal = socketDataRecv(connection, msgRec, dataSizeToRead, recvStatus);
    LOG(LOG_INFO, "TCPStreamRecv: recvStatus = %d\n", *recvStatus);
    
    return retVal;
}

/* Function: TCPStreamClose
 * close the connection and free the socket.
 */
int TCPStreamClose(int streamID) {
    int retVal = TCPSTREAM_NO_ERROR;
    /*TO DO
     * gracefully close all sockets and exit.
     */
    return retVal;
}

void *clientConn_handler(void *input) {
    uint16_t streamId = *(uint16_t *)input;
    ConnectionInfo *cliConn = getConnectionInfo(streamId);
    if (cliConn == NULL) {
        LOG(LOG_INFO, "clientConn_handler: cliConn is NULL, streamId: %d\n", streamId);
        return NULL;
    }
    struct sockaddr_in remoteAddr;
    LOG(LOG_INFO, "clientConn_handler: start %d\n", streamId);
    
    remoteAddr.sin_addr.s_addr = hostnameLookup(cliConn->remoteHost);
    remoteAddr.sin_family = AF_INET; /*hp->h_addrtype;*/
    remoteAddr.sin_port   = htons((unsigned short) cliConn->remotePort);
    if (remoteAddr.sin_addr.s_addr == INADDR_NONE)
        return NULL;
    while(1) {
        if(connect(cliConn->clientSock, (struct sockaddr *)&remoteAddr, sizeof(remoteAddr)) == 0) {
            LOG(LOG_INFO, "clientConn_handler: %d connect success\n", streamId);
            
            /* set the user specified timeout for socket */
            setTimeoutForSocket(cliConn->clientSock, cliConn->blockingTimeout);
            
            /* Change Buffer size */
            setReceiveBufferSize(cliConn->clientSock,cliConn->ReceiveBufferSize);
            setSendBufferSize(cliConn->clientSock,cliConn->SendBufferSize);
            
            pthread_mutex_lock(&cliConn->connect_mutex);
            cliConn->sock = cliConn->clientSock;
            
            /* signal the wait for connection timed waiting to wakeup the step function.*/
            pthread_cond_signal(&cliConn->connect_cv);
            
            /* wait here till the connection is lost.*/
            LOG(LOG_INFO, " clientConn_handler: %d, pthread cond wait\n", streamId);
            pthread_cond_wait(&cliConn->connect_cv, &cliConn->connect_mutex);
            LOG(LOG_INFO, "clientConn_handler: %d, wake from sleep\n", streamId);
            pthread_mutex_unlock(&cliConn->connect_mutex);
        }
#ifdef __APPLE__
        /* failure to connect invalidates the socket descriptor on BSD derived systems.
         So, we need to create a new client socket before calling connect*/
        else {
            int errorNo = 1;
            close(cliConn->clientSock);
            cliConn->clientSock = createClientSocket(cliConn->remoteHost, cliConn->remotePort,cliConn->localClientPort, errorNo);
        }
#endif
        sleep(1);
        LOG(LOG_INFO, "clientConn_handler: %d, while loop running\n", streamId);
    }
}

void *serverConn_handler(void *input) {
    uint16_t streamId = *(uint16_t *)input;
    ConnectionInfo *serConn = getConnectionInfo(streamId);
    if (serConn == NULL) {
        LOG(LOG_INFO, "serverConn_handler: serConn is NULL, streamId: %d\n", streamId);
        return NULL;
    }
    SOCKET cFd = 0;
    
    LOG(LOG_INFO,"serverConn_handler: start \n");
    while(1) {
        cFd = serverAcceptConnection(serConn);
        if(cFd > 0){
            /* connection success. save it to struct */
            LOG(LOG_INFO,"serverConn_handler: connect success\n");
            setTimeoutForSocket(cFd, serConn->blockingTimeout);
            /* Change Buffer size */
            setReceiveBufferSize(cFd,serConn->ReceiveBufferSize);
            setSendBufferSize(cFd,serConn->SendBufferSize);
            
            pthread_mutex_lock(&serConn->connect_mutex);
            serConn->sock = cFd;
            LOG(LOG_INFO,"serverConn_handler: pthread cond wait \n");
            pthread_cond_wait(&serConn->connect_cv, &serConn->connect_mutex);
            LOG(LOG_INFO,"serverConn_handler: wake from sleep \n");
            pthread_mutex_unlock(&serConn->connect_mutex);
        }
        sleep(1);
        LOG(LOG_INFO,"serverConn_handler: while loop running \n");
    }
    LOG(LOG_INFO,"serverConn_handler: end \n");
}

#ifndef isinf
static inline uint8_t isinf(double x)
{
    union {int64_t i, double f} f;
    f.f = x;
    return (uint8_t)(f.i == 0x7FF0000000000000LL);
}
#endif



void TCPStreamSetup(uint16_t portNumber, uint16_t localClientPort, uint16_t *connStream, uint16_t server, double blockingTimeout, int16_t *errorNo, char *hostName) {
    ConnectionMode operMode;
    pthread_t tid;
    int status;
    int persistConn = -1;
    /* *errorNo = TCPSTREAM_NO_ERROR;*/ 
    
    ConnectionInfo * connData = NULL;
    setlogmask (LOG_UPTO(LOG_DEBUG)); /*TO DO : Get a location for calling setlogmask */
    LOG(LOG_INFO, "TCPStreamSetup: stream setup hostName = %s, portNumber = %d, connectionMode = %s \n", hostName, portNumber, (server == 0) ? "Client" : "Server");
    
    /* Set thread stack size attribute */
#ifdef PARROT_LINUX_COMM
    pthread_attr_t attr;
    size_t stackSize;
    pthread_attr_init(&attr);
    stackSize = (512 > PTHREAD_STACK_MIN) ? 512:PTHREAD_STACK_MIN;
    status = pthread_attr_setstacksize(&attr, stackSize);
    LOG(LOG_INFO, "TCPStreamSetup:Return value of Pthread_attr_setstacksize= %d  \n",status);
#endif
    
    /* check for existing connections */
    persistConn = connectionLookup(hostName, portNumber);
    if(persistConn < 0) {
        LOG(LOG_INFO, "TCPStreamSetup: no existing connection, create new\n");
    }
    else {
        LOG(LOG_INFO, "TCPStreamSetup: existing connection available, persistConn ID = %d \n", persistConn);
        *connStream = persistConn;

        /* Update time out */
        connData = getConnectionInfo(*connStream);
        /* Check time out set to default */
        /* Don't change blocking time to infinity if connection set with a infinity */
        if (1 == isinf(connData->blockingTimeout))
        {
            /* Do nothing */
        }
        else
        {
            connData->blockingTimeout = connData->blockingTimeout < blockingTimeout ? blockingTimeout : connData->blockingTimeout;

        }
        /* *errorNo = TCP_ERR_NOCONN;*/
        return;
    }
    
    if(server == 1) {
        operMode = SERVER_MODE;
        LOG(LOG_INFO, "TCPStreamSetup: open server stream");
        *errorNo = TCPStreamOpen(hostName,portNumber,localClientPort,operMode,connStream,blockingTimeout);
        LOG(LOG_INFO, "TCPStreamSetup: server stream val: hostName = %s, portNumber = %d, streamId = %i, sockfd = %d \n", hostName, portNumber, *connStream,connectionInfoArray[*connStream].sock);
        
        /*TO DO :
         * set thread priority using pthread_setschedparam(),pthread_setschedprio()
         */
        connData = getConnectionInfo(*connStream);
        if (connData == NULL) {
            *errorNo = TCP_ERR_NOCONN_SERVER;
            return;
        }
        pthread_mutex_init(&(connData->connect_mutex), NULL);
        pthread_cond_init (&(connData->connect_cv), NULL);
        LOG(LOG_INFO, "TCPStreamSetup: creating server connection handler thread, streamid = %d\n", *connStream);
#ifdef PARROT_LINUX_COMM
        pthread_create(&tid,&attr,serverConn_handler, &(connData->streamID));
#else
        pthread_create(&tid,NULL,serverConn_handler, &(connData->streamID));
#endif
        
        LOG(LOG_INFO, "TCPStreamSetup: end of pthread_create \n");
    } else {
        LOG(LOG_INFO, "TCPStreamSetup: open client stream\n");
        operMode = CLIENT_MODE;
        *errorNo = TCPStreamOpen(hostName,portNumber,localClientPort,operMode,connStream,blockingTimeout);
        LOG(LOG_INFO, "TCPStreamSetup: client stream val: hostName = %s, portNumber = %d, streamId = %i, sockfd = %d\n", hostName, portNumber, *connStream,connectionInfoArray[*connStream].sock);
        /*TO DO :
         * set thread priority using pthread_setschedparam(),pthread_setschedprio()
         */
        connData = getConnectionInfo(*connStream);
        
        if (connData == NULL) {
            *errorNo = TCP_ERR_NOCONN_CLIENT;
        } else {
            pthread_mutex_init(&(connData->connect_mutex), NULL);
            pthread_cond_init (&(connData->connect_cv), NULL);
            LOG(LOG_INFO,"TCPStreamSetup: creating client connection handler thread, streamid = %d\n",*connStream);
#ifdef PARROT_LINUX_COMM
            pthread_create(&tid,&attr,clientConn_handler, &(connData->streamID));
#else
            pthread_create(&tid,NULL,clientConn_handler, &(connData->streamID));
#endif
            LOG(LOG_INFO,"TCPStreamSetup: end of pthread_create\n");
        }
    }
#ifdef PARROT_LINUX_COMM
    pthread_attr_destroy(&attr);
#endif
}

void TCPStreamStepSend(void *dataIn, size_t dataInSize, uint16_t connStream, uint16_t isSer, int16_t *errorNo) {
    LOG(LOG_INFO, "TCPStreamStepSend: connStream = %d, dataInSize = %d\n", connStream, dataInSize);
    ConnectionInfo *connData = NULL;
    int pending = 0;
    if(connStream >= 0){
        connData = getConnectionInfo(connStream);
        LOG(LOG_INFO,"TCPStreamStepSend: check connection and send data\n");
        if (connData == NULL) {
            *errorNo = (isSer == 1) ? TCP_ERR_NOCONN_SERVER : TCP_ERR_NOCONN_CLIENT;
            return;
        }
        if(connData->sock <= 0){
            /*No connection. Threads are running to connect to client/server.
             * Block the step function if required.
             */
            if(connData->operMode == SERVER_MODE) {
                /*block on listen socket*/
                LOG(LOG_INFO, "TCPStreamStepSend: invalid socket, block on listen socket\n");
                checkSocketPending(connData->serverData->listenSock, &pending, connData->blockingTimeout);
            }else {
                /*block on client socket */
                LOG(LOG_DEBUG, "TCPStreamStepSend: connStream %d wait for a successful connection\n", connStream);
                waitForConnection(connStream);
            }
        }
        if(connData->sock > 0) {
            /*valid connection. Send data*/
            *errorNo = socketDataSend(connData, dataIn, dataInSize);
            
            if((*errorNo == TCP_ERR_NOCLIENT) || (*errorNo == TCP_ERR_NOSERVER)){
                LOG(LOG_INFO, "TCPStreamStepSend: error in connection, close the socket\n");
                close(connData->sock);
                LOG(LOG_INFO, "TCPStreamStepSend: lock the mutex and signal the thread\n");
                pthread_mutex_lock(&connData->connect_mutex);
                connData->sock = INVALID_SOCKET;
                
                /*recreate socket if in client mode */
                if(connData->operMode == CLIENT_MODE){
                    LOG(LOG_INFO, "TCPStreamStepSend: re-create new socket for client connection\n");
                    connData->clientSock = createClientSocket(connData->remoteHost, connData->remotePort,connData->localClientPort,errorNo);
                }
                LOG(LOG_INFO, "TCPStreamStepSend: signal the thread to reconnect\n");
                pthread_cond_signal(&connData->connect_cv);
                pthread_mutex_unlock(&connData->connect_mutex);
                LOG(LOG_INFO, "TCPStreamStepSend: Unlock the mutex\n");
            }
        } else
            *errorNo = (connData->operMode == SERVER_MODE) ? TCP_ERR_NOCLIENT : TCP_ERR_NOSERVER;
    }
    if((*errorNo != TCP_ERR_NOCLIENT) && (*errorNo != TCP_ERR_NOSERVER)) {
        *errorNo = TCP_ERR_CONNSUCCESS;
        LOG(LOG_INFO, "TCPStreamStepSend: Sent successfully\n");
    }

}

void TCPStreamStepRecv(void *msgRec, int8_t *recvStatus, size_t dataSizeToRead, uint16_t connStream, int16_t *errorNo, uint16_t isSer) {
    LOG(LOG_INFO, "TCPStreamStepRecv: connStream = %d\n", connStream);
    memset(msgRec,0,dataSizeToRead);
    memset(recvStatus,0,sizeof(int8_t));
    ConnectionInfo * connData = NULL;
    int recvOk = TCPSTREAM_ERROR;
    int pending = 0;
    if(connStream >= 0){
        connData = getConnectionInfo(connStream);
        if (connData == NULL) {
             *errorNo = (isSer == 1) ? TCP_ERR_NOCONN_SERVER : TCP_ERR_NOCONN_CLIENT;
            return;
        }
        LOG(LOG_INFO, "TCPStreamStepRecv: check connection and receive data\n");
        
        if(connData->sock <= 0){
            /*
             * No connection. Threads are running to connect to client/server.
             * Block the step function if required.
             */
            if(connData->operMode == SERVER_MODE){
                /*block on listen socket */
                LOG(LOG_INFO, "TCPStreamStepRecv: invalid socket, block on listen socket\n");
                checkSocketPending(connData->serverData->listenSock, &pending, connData->blockingTimeout);
            } else {
                /*block on client socket */
                LOG(LOG_DEBUG, "TCPStreamStepRecv: connStream %d, wait for a successful connection\n", connStream);
                waitForConnection(connStream);
            }
        }
        
        if(connData->sock > 0){
            /*valid connection. Start receiving*/
            *errorNo = TCPStreamRecv(msgRec,recvStatus,dataSizeToRead,connStream);
            if((*errorNo == TCP_ERR_NOCLIENT) || (*errorNo == TCP_ERR_NOSERVER)){
                /*ERROR in connection
                 * close the connection and signal the thread to wakeup and reconnect.
                 */
                LOG(LOG_INFO, "TCPStreamStepRecv: error in connection, close the socket\n");
                close(connData->sock);
                LOG(LOG_INFO, "TCPStreamStepRecv: lock the mutex and signal the thread\n");
                pthread_mutex_lock(&connData->connect_mutex);
                connData->sock = INVALID_SOCKET;
                
                /*recreate socket if in client mode */
                if(connData->operMode == CLIENT_MODE){
                    LOG(LOG_INFO, "TCPStreamStepRecv: re-create new socket for client connection\n");
                    connData->clientSock = createClientSocket(connData->remoteHost, connData->remotePort,connData->localClientPort, errorNo);
                }
                LOG(LOG_INFO, "TCPStreamStepRecv: signal the thread to reconnect\n");
                pthread_cond_signal(&connData->connect_cv);
                pthread_mutex_unlock(&connData->connect_mutex);
                LOG(LOG_INFO, "TCPStreamStepRecv: unlocked the mutex\n");
            }
        } else
            *errorNo = (connData->operMode == SERVER_MODE) ? TCP_ERR_NOCLIENT : TCP_ERR_NOSERVER;
    }
   if((*errorNo != TCP_ERR_NOCLIENT) && (*errorNo != TCP_ERR_NOSERVER)) {
        *errorNo = TCP_ERR_CONNSUCCESS;
        LOG(LOG_INFO, "TCPStreamStepRecv: received successfully\n");
    }
}

/* Function: littleEndianCheck
 * Return 1 for little endian, 0 for big endian
 */
void littleEndianCheck(uint8_t *isLittleEndian) {
    *isLittleEndian = 0;
    unsigned int i = 1;
    char *c = (char*)&i;
    if(*c)
        *isLittleEndian = 1;
}

/* Function setTimeoutForSocket
 */
void setTimeoutForSocket(int sockfd, double timeout) {
    LOG(LOG_INFO, "setTimeoutForSocket: timeout = %f, socket = %d\n", timeout, sockfd);

    /* Apply timeout only on valid socket */
    if(sockfd > 0)
    {
        /*if (timeout == 0.0) {
            int saved_flags = 0;
            saved_flags = fcntl(sockfd,F_GETFL);
            fcntl(sockfd, F_SETFL, saved_flags | O_NONBLOCK);
            LOG(LOG_INFO, "setTimeoutForSocket: set non blocking mode\n");
            return;
        }*/
        struct timeval tval;
        /* If timeout is 0 then it's always blocking as per https://linux.die.net/man/7/socket */
        timeout = isinf(timeout) ? 0.0 : timeout;
        tval.tv_sec = floor(timeout);
        tval.tv_usec = (timeout - floor(timeout))*pow(10,6);
        int sockstatus = setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, (char *)&tval,sizeof(struct timeval));
        LOG(LOG_INFO, "setTimeoutForSocket: socket status %d\n", sockstatus);
        sockstatus = setsockopt(sockfd, SOL_SOCKET, SO_SNDTIMEO, (char *)&tval,sizeof(struct timeval));
        LOG(LOG_INFO, "setTimeoutForSocket: socket status %d\n", sockstatus);
    }
}

/* Change Buffer size */
void setReceiveBufferSize(int sock, int32_t ReceiveBufferSize)
{
    if (ReceiveBufferSize > -1)
    {
        setsockopt(sock, SOL_SOCKET, SO_RCVBUF, (char *) &ReceiveBufferSize, sizeof(ReceiveBufferSize));
        LOG(LOG_INFO, "sock %d, Changed RecvBufSize: %d \n", sock, ReceiveBufferSize);
    }
}
void setSendBufferSize(int sock,int32_t SendBufferSize)
{
    if (SendBufferSize > -1)
    {
        setsockopt(sock, SOL_SOCKET, SO_SNDBUF, (char *) &SendBufferSize, sizeof(SendBufferSize));
        LOG(LOG_INFO, "sock %d, Changed SendBufSize: %d \n", sock, SendBufferSize);
    }
}
            
            
#endif