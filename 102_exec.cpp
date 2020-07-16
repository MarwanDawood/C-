/*
 * 102_exec.cpp
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
	// Create a child process
	if (0 == fork())
	{
		cout << "Child pid is " << getpid() << endl;
		//         - v (vector, i.e array)
		//        |
		// exec --     p (path, search in the env variable paths for the program)
		//               e (environment, use different env variables for the process
		//                  than passed ones)
		//                 NULL (need to be NULL terminated)
		//        |
		//         - l (list)

		// Call another program to run and replace the child process
		// execlp("ls","ls","-al",NULL);
		execl("/bin/ls","ls","-al",NULL);
		cout << "after exec" << endl;
	}
	else
	{
		// fork() return 0 for parent process
		cout << "Parent pid is: " << getpid() << endl;
	}
}
