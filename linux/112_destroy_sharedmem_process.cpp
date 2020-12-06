/*
 * 112_destroy_sharedmem_process.cpp
 *
 * Application that destroys the shared memory block
 *
 *  Created on: Jul 19, 2020
 *      Author: marwan
 */

#include <iostream>
#include <unistd.h>
#include <string.h>

#include "112_common_sharedmem_process.h"

#define BLOCK_SIZE 4096

using namespace std;

int main(int argc, char *argv[])
{
	char *block = NULL;

	if (argc != 1)
	{
		cout << "ERROR: wrong usage of " << argv[0] << endl;
		return -1;
	}


	if (1 == destroy_memory_block(FILENAME))
	{
		cout << "destroying the block: " << FILENAME << endl;
	}
	else
	{
		cout << "ERROR: destroying the block: " << FILENAME << endl;
	}

	return 0;
}


