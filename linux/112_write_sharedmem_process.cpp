/*
 * 112_write_sharedmem_process.cpp
 *
 * Application that writes to shared memory
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

	if (argc != 2)
	{
		cout << "ERROR: wrong usage of " << argv[0] << endl;
		return -1;
	}

	// grab the shared memory block
	if (NULL == (block = attach_memory_block((char*)FILENAME, BLOCK_SIZE)))
	{
		cout << "ERROR: couldn't get memory block";
		return -1;
	}

	cout << "writing: " << argv[1] << endl;
	strncpy(block, argv[1], BLOCK_SIZE);
	detach_memory_block(block);

	return 0;
}

