/*
 * 101_fork.cpp
 *
 *  Created on: Jul 5, 2020
 *      Author: marwan
 */


#include <iostream>
#include <sys/types.h>
#include <unistd.h>

using namespace std;

int main(void)
{
	// fork() creates a child process, it returns here child process p
	if (0 == fork())
	{
		cout << "Child pid is " << getpid() << endl;
	}
	else
	{
		// fork() return 0 for parent process
		cout << "Parent pid is: " << getpid() << endl;
	}
}
