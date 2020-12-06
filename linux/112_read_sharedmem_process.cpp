/*
 * 112_read_sharedmem_process.cpp
 *
 * Application that reads from shared memory block
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

	// grab the shared memory block
	if (NULL == (block = attach_memory_block(FILENAME, BLOCK_SIZE)))
	{
		cout << "ERROR: couldn't get memory block";
		return -1;
	}

	cout << "reading: \"" << block << "\"\n";
	detach_memory_block(block);

	return 0;
}


