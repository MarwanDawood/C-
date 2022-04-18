/* Copyright 2013 The MathWorks, Inc. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>

#define UDP_PORT                  (18726)
#define NUM_MAX_INTERFACES        (8)
#define SHUT_DOWN_CLIENT_MSG      "shut down"
#define SHUT_DOWN_CLIENT_MSG_SIZE (9)
#define RECV_BUFF_SIZE            (31)
#define SLEEP_INTERVAL            (3)


int main(int argc, char**argv)
{
    int sock, ret, i;
    struct sockaddr_in ifAddress;
    char buff[32];
    char hostname[64] = "localhost";
    char ifList[NUM_MAX_INTERFACES][16];
    FILE *fd;
    int numNic = 0;
    int broadcastFlag = 1;
    
    /* Check arguments */
    if (argc != 2) {
        fprintf(stderr, "Usage:  udp_ip <filename>\n");
        exit(1);
    }
    
    /* Read hostname */
    fd = fopen("/etc/hostname", "r");
    if (fd != NULL) {
        ret = fscanf(fd, "%s", hostname);
        fclose(fd);
    }
    
    /* Read IP address list */
    fd = fopen(argv[1], "r");
    if (fd != NULL) {
        for (i = 0; i < NUM_MAX_INTERFACES; i++) 
        {
            ret = fscanf(fd, "%s", ifList[i]);
            if (ret < 1) {
                break;
            }
            numNic++;
#ifdef _DEBUG
            printf("Add %s to the IF list.\n", ifList[i]);
#endif
        }
        fclose(fd);
    }
    if (numNic == 0) {
        /* No interfaces are identified in the given file name */
        strcpy(ifList[0], "255.255.255.255");
        numNic = 1;
    }    
    
    /* Create a UDP socket */
    sock = socket(AF_INET, SOCK_DGRAM, 0);
    while (sock < 0) {
        fprintf(stderr, "Error opening UDP socket\n");
        sleep(SLEEP_INTERVAL);
        sock = socket(AF_INET, SOCK_DGRAM, 0);
    }
    ret = setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcastFlag, 
            sizeof(broadcastFlag));
    if (ret == -1) {
        perror("setsocketopt");
    }
    
    /* Initialize socket address structure */
    bzero(&ifAddress, sizeof(ifAddress));
    ifAddress.sin_family = AF_INET;
    ifAddress.sin_port   = htons(UDP_PORT);
    while (1)
    {
        for (i = 0; i < numNic; i++) 
        {
    #ifdef _DEBUG
            printf("Sending a message to %s\n", ifList[i]);
    #endif
            ifAddress.sin_addr.s_addr = inet_addr(ifList[i]);
            sendto(sock, hostname, strlen(hostname), 0,
                    (struct sockaddr *)&ifAddress, sizeof(ifAddress));
            ret = recvfrom(sock, buff, RECV_BUFF_SIZE, MSG_DONTWAIT, NULL, NULL);
            if (ret > 0) {
                buff[ret] = 0;
                if (strncmp(buff, SHUT_DOWN_CLIENT_MSG, SHUT_DOWN_CLIENT_MSG_SIZE) == 0) {
                #ifdef _DEBUG
                    printf("Terminating server..\n");
                #endif    
                    exit(0);
                }
            }
        }
        sleep(SLEEP_INTERVAL);
    }
    
    return 0;
}
