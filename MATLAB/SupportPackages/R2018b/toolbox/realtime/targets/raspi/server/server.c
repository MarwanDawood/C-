/* Copyright 2013 - 2018 The MathWorks, Inc. */
#include <stdio.h>      
#ifdef __WIN32__
 #include <winsock2.h>
#else
 #include <sys/socket.h> 
 #include <arpa/inet.h>  
#endif
#include <stdlib.h>    
#include <string.h>     
#include <unistd.h>    
#include <pthread.h> 
#include <signal.h>
#ifdef NANOMSG_TRANSPORT
#include <nanomsg/nn.h>
#include <nanomsg/reqrep.h>
#endif
#include "common.h"
#include "server.h"
#include "handler.h"
#include "devices.h"
#include "ip_server.h"

// Local defines
#define NUM_MAX_PENDING_CONNECTIONS (5)
#define ERRNO_OPEN_SOCKET           (-1)
#define ERRNO_BIND_SOCKET           (-2) 
#define ERRNO_LISTEN_SOCKET         (-3)
#define ERRNO_ACCEPT                (-4)
#ifndef __WIN32__
 #define INVALID_SOCKET  (-1)
#endif
unsigned short gus_Port;
#ifdef NANOMSG_TRANSPORT
static unsigned char isInterrupted =1;
#endif
// Open and bind to a specified port 
int bindSocket(unsigned short port)
{
    int sock, ret;                        
#ifdef NANOMSG_TRANSPORT
    char serverAddr[30]={'\0'}; 
    sprintf(serverAddr, "tcp://*:%d",port); 
	printf("binding Address:: %s\n",serverAddr);
    // Open a socket 
    sock = nn_socket (AF_SP, NN_REP);
    if (sock == INVALID_SOCKET) {
        fprintf(stderr, "Error opening socket\n");
        exit(ERRNO_OPEN_SOCKET);
    }
      
    // Set local address / port
    // Bind to the local address
    ret = nn_bind(sock, serverAddr);
    if ( ret < 0) {
        fprintf(stderr, "Error binding socket\n");
        exit(ERRNO_BIND_SOCKET);
    }
#else
    struct sockaddr_in serverAddr; 

    // Open a socket 
    sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock == INVALID_SOCKET) {
        fprintf(stderr, "Error opening socket\n");
        exit(ERRNO_OPEN_SOCKET);
    }
      
    // Set local address / port
    memset(&serverAddr, 0, sizeof(serverAddr));  
    serverAddr.sin_family      = AF_INET;                
    serverAddr.sin_addr.s_addr = htonl(INADDR_ANY); 
    serverAddr.sin_port        = htons(port);              

    // Bind to the local address
    ret = bind(sock, (struct sockaddr *) &serverAddr, sizeof(serverAddr));
    if ( ret < 0) {
        fprintf(stderr, "Error binding socket\n");
        exit(ERRNO_BIND_SOCKET);
    }

    // Listen to incoming connections
    ret = listen(sock, NUM_MAX_PENDING_CONNECTIONS);
    if (ret < 0) {
        fprintf(stderr, "Error binding socket\n");
        exit(ERRNO_LISTEN_SOCKET);
    }
#endif

    return sock;
}

// Accept incoming connections 
int acceptConnection(int serverSock)
{
    int clientSock;      
    struct sockaddr_in addr; 
    unsigned int addrLen;

    addrLen = sizeof(addr);
    clientSock = accept(serverSock, (struct sockaddr *) &addr, &addrLen);
    if (clientSock == INVALID_SOCKET) {
        fprintf(stderr, "Error accepting incoming connection\n");
        exit(ERRNO_ACCEPT);
    }
    LOG_PRINT(stdout, "Client connected %s\n", inet_ntoa(addr.sin_addr));

    return clientSock;
}

#ifndef __MINGW32__
// Exit handler
static void exitHandler(int sig, siginfo_t *siginfo, void *context)
{
#ifdef NANOMSG_TRANSPORT
    isInterrupted =0 ; 
#endif
}
#endif

// Entry point 
int main(int argc, char *argv[])
{
    int sock;
    ARGS_t *args;   
#ifndef __MINGW32__
    struct sigaction act;
#endif

#ifdef __WIN32__
   WORD versionWanted = MAKEWORD(1, 1);
   WSADATA wsaData;
   WSAStartup(versionWanted, &wsaData);
#endif
    // Check input arguments
    if (argc != 2) {
        fprintf(stderr, "Usage:  %s <SERVER PORT>\n", argv[0]);
        exit(1);
    }
    gus_Port = atoi(argv[1]);
 
#ifndef __MINGW32__
    // Catch terminate signals
    memset(&act, 0, sizeof(act));
    act.sa_sigaction = &exitHandler;
    act.sa_flags = SA_SIGINFO;
    if ((sigaction(SIGTERM, &act, NULL) < 0) ||
            (sigaction(SIGINT, &act, NULL) < 0) ||
            (sigaction(SIGQUIT, &act, NULL) < 0)) {
        perror("sigaction");
        exit(1);
    }
#endif
    
#ifdef NANOMSG_TRANSPORT
    DEV_init();
    sock = bindSocket(gus_Port);
    while (isInterrupted)
    {
        args = (ARGS_t *) malloc(sizeof(ARGS_t));
        if(args == NULL){
                fprintf(stderr, "Not enough memory\n");
                exit(1);
        }
        args->sock = sock;
        args->port = gus_Port;
        (void *)eventHandlerThread(args);  
    
   }
   
#else
    // Create IP address discovery thread
    int clientSock;                   
    pthread_t thread;              
  
    if (pthread_create(&thread, NULL, ipDiscoveryThread, (void *) &gus_Port) != 0) {
        perror("Cannot create IP discovery thread: ");
        exit(1);
    }
    
    // Init device table
    DEV_init();
    sock = bindSocket(gus_Port);
    while (1) {
        clientSock = acceptConnection(sock);
        // Create separate memory for client argument
        args = (ARGS_t *) malloc(sizeof(ARGS_t));
        if (args == NULL) {
            fprintf(stderr, "Not enough memory\n");
            exit(1);
        }
        args->sock = clientSock;

        // Create an event handler thread for client
        if (pthread_create(&thread, NULL, eventHandlerThread, (void *) args) != 0) {
            perror("Cannot create handler thread: ");
            exit(1);
   }
    }
#endif  
  
   return 0;
}
