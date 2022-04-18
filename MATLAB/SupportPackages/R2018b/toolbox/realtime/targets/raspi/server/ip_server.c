#include <stdio.h>
#ifdef __WIN32__
 #include <winsock2.h>
 #include <WS2tcpip.h>
#else
 #include <sys/socket.h>
 #include <arpa/inet.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include "common.h"

#define MAXBUF (128)

// Create a UDP socket bound to a specified port
static int createUdpSocket(const unsigned short port)
{
    int sock, ret;                        
    struct sockaddr_in socketAddr; 

    // Create a udp socket
    sock = socket(PF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        fprintf(stderr, "Error opening UDP socket\n");
        return -1;
    }
      
    // Set local address / port
    memset(&socketAddr, 0, sizeof(socketAddr));  
    socketAddr.sin_family      = AF_INET;                
    socketAddr.sin_addr.s_addr = htonl(INADDR_ANY); 
    socketAddr.sin_port        = htons(port);              

    // Bind to the local address
    ret = bind(sock, (struct sockaddr *) &socketAddr, sizeof(socketAddr));
    if ( ret < 0) {
        fprintf(stderr, "Error binding socket to port %d\n", port);
        return -1;
    }

    return sock;
}


// IP address discovery thread
void *ipDiscoveryThread(void *args)
{
    int sock, ret;
    socklen_t fromLen;
    char buff[MAXBUF];
    struct sockaddr_in remoteHost;
    char hostname[64] = "localhost";
    FILE *fd;
    
    // Detach thread from parent. Resources will be automatically 
    // de-allocated when thread exits
    pthread_detach(pthread_self());
    LOG_PRINT(stdout,"IP discovery thread started %d\n",0);
    
    // Read hostname
    fd = fopen("/etc/hostname", "r");
    if (fd != NULL) {
        ret = fscanf(fd, "%s", hostname);
        fclose(fd);
    }
    
    // Create a UDP socket bound to the port number passed to this thread
    sock = createUdpSocket(*((unsigned short *) args));
    LOG_PRINT(stdout,"UDP socket bound to %d\n", *((unsigned short *) args));
    if (sock > 0) {
        fromLen = sizeof(remoteHost);
        while (1)
        {
            ret = recvfrom(sock, buff, sizeof(buff)-1, 0, (struct sockaddr *) &remoteHost, &fromLen);
            buff[ret] = 0;
            LOG_PRINT(stdout,"Received broadcast message '%s'\n", buff);
            if ((ret > 0) && (strncmp(buff, "who is raspi?", 13) == 0)) {
                sprintf(buff, "%s", hostname);
                LOG_PRINT(stdout,"Response = '%s'\n",buff);
                sendto(sock, buff, strlen(buff), 0, (struct sockaddr *) &remoteHost, fromLen);
            }
        }
        close(sock);
    }
    
    return(NULL);
}


