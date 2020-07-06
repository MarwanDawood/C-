/*
 * 103_zombie.cpp
 *
 *  Created on: Jul 5, 2020
 *      Author: marwan
 */

#include <iostream>
#include <sys/types.h>
#include <unistd.h>
#include <wait.h>

using namespace std;

int main(void)
{
	while(1)
	{
		if (0 == fork())
		{
			cout << "Child started and done with pid " << getpid() << endl;
			return 0;
		}
		else
		{
			// Wait() is needed to terminate the child process after it is done
			// Removing wait(), will create zombie child processes and killing the parent
			// process by ctrl+c will kill the parent and all the children
			// ps -e -> to view all process
			// top -> to view top active processes
			wait(NULL);
			cout << "Parent just won't die" << endl;
			// sleep in seconds
			sleep(2);
		}
	}
}

