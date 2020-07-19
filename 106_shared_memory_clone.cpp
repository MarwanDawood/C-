/*
 * 106_shared_memory_clone.cpp
 *
 *  Created on: Jul 8, 2020
 *      Author: marwan
 */

// sharing memory between 2 cloned processes, 1 parent and children

#include <unistd.h> // for fork()
#include <iostream>
#include <wait.h>
#include <sys/mman.h> // for mmap()
#include <stdlib.h> // for types, not used


using namespace std;

#define PAGESIZE 4096

int v = 5; /* defined here because I want it to be visible in the parent and the child,
              otherwise, it will be a copy of the parent local variables */
int main(void)
{
	int *shared_memory = (int*)mmap(NULL, PAGESIZE,
		                            PROT_READ | PROT_WRITE,
			                        MAP_SHARED | MAP_ANONYMOUS, -1, 0);
	*shared_memory = 35;

	if (0 == fork())
	{
		*shared_memory = 10;
		v = 80;
	}
	else
	{
		wait(NULL);
	}

	cout << "Not shared " << v << endl;
	cout << "Shared " <<  *shared_memory << endl;
}


