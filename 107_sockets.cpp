/*
 * 107_sockets.cpp
 *
 *  Created on: Jul 11, 2020
 *      Author: marwan
 */


#include <sys/socket.h>
#include <iostream>
#include <unistd.h>
#include <string.h> // used for strlen
#include <netinet/in.h> // used for structure definition
#include <arpa/inet.h> // used for inet_pton function
#include <stdio.h> // used for sprintf function

using namespace std;

#define SERVER_PORT	80
#define MAXLINE	4096

// argc (ARGument Count) : number of Cmd arguments passed by the user including
//                         the name of the program
// argv(ARGument Vector) : is array of character pointers listing all the arguments.
// argv[0] is the name of the program
int main(int argc, char *argv[])
{
	struct sockaddr_in servaddr; // Internet socket address
	int sockfd = 0;
	int n = 0;
	int sendBytes = 0;
	char sendLine[MAXLINE];
	char recvLine[MAXLINE];
	int ipVersion = AF_INET;

	if (argc != 2)
	{
		cout << "wrong usage of the application " << argv[0] << endl;
	}

	// check if it is IPv4 or IPv6
	if (strlen(argv[1]) > 16)
	{
		ipVersion = AF_INET6;
		cout << "IPv6 for "<< argv[1] << endl;
	}
	else
	{
		cout << "IPv4 for "<< argv[1] << endl;
	}

	// AF_INET : Address Family Internet
	// 0 is for TCP, there is also UDP
	if ((sockfd = socket(ipVersion, SOCK_STREAM, 0)) < 0)
	{
		cout << "Error while creating the socket." << endl;
	}

	// Set address to zero
	memset(&servaddr, 0, sizeof(servaddr));
	// socket Internet address family
	servaddr.sin_family = ipVersion;
	// htons : host to network to handle the byte order in different machines (endianess)
	servaddr.sin_port = htons(SERVER_PORT);

	// translate the presentation (textual) of IP address into a network (binary) equivalent
	// @todo inet_pton cannot handle IPv6 addresses
	if (inet_pton(ipVersion, argv[1], &servaddr.sin_addr) <= 0)
	{
		cout << "inet_pton error for " << argv[1] << endl;
	}

	if (connect(sockfd, (struct sockaddr*)&servaddr, sizeof(servaddr)) < 0)
	{
		cout << "connect failed" << endl;
	}

	// connected? then prepare the message
	// the carriage return and new line are to indicate the end of the message
	sprintf(sendLine, "GET / HTTP/1.1\r\n\r\n");
	sendBytes = strlen(sendLine);

	// send the request
	// @todo if sending fails, retry
	if (write(sockfd, sendLine, sendBytes) != sendBytes)
	{
		cout << "write error" << endl;
	}

	// read the server response
	while((n = read(sockfd, recvLine, MAXLINE - 1)) > 0)
	{
		cout << recvLine << endl;
		memset(recvLine, 0, MAXLINE);
	}

	if (n < 0)
	{
		cout << "error read" << endl;
	}
}
