/*
 * 105_signals.cpp
 *
 *  Created on: Jul 7, 2020
 *      Author: marwan
 */

#include <iostream>
#include <unistd.h>
#include <wait.h>

using namespace std;

void handler(int num)
{
	write(STDOUT_FILENO, "I wonn't die\n", 13); //13 is the string size
}

void seghandler(int num)
{
	write(STDOUT_FILENO, "segmentation fault\n", 19);  //19 is the string size
}

int main(void)
{
	int* ptr = NULL;
	struct sigaction sa;
	sa.sa_handler = handler;

	//signal(SIGINT, handler);  // handles ctrl+c or kill -INT <pid>
	signal(SIGTERM, handler); // handles kill -TERM <pid>
	signal(SIGKILL, handler); // --> cannot handle kill -9 <pid> or kill -KILL <pid>
							  // kill -STOP <pid> to stop the process
	                          // kill -CONT <pid> to continue the process with the same pid
	signal(SIGSEGV, seghandler);	// killall -9 <program name>

	sigaction(SIGINT, &sa, NULL); // this is a more powerful and portable interface, it is new

	//*ptr = 100;	// dereference NULL pointer generates segmentation fault

	while(1)
	{
		cout << "2 seconds passed for pid " << getpid() << endl;
		sleep(2);
	}
	return 0;
}
