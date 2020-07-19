/*
 * 112_common_sharedmem_process.cpp
 *
 * Common functions used in shared memory application
 *
 *  Created on: Jul 19, 2020
 *      Author: marwan
 */

// sharing memory between 2 independent processes
// The concept is to assign the shared memory area to process #1,
// we can refer to this memory area as a file since everything in Linux is a file,
// then if process #2 wants to use the shared memory, it uses this file

// tfok : get the key associated to the created memory file
// shmget : get the memory block ID associated with that key
// shmat : map the block ID to the prcoess adress space (attach)
// shmdt : detach memory block from process
// shmctl : destroy memory block

#include <unistd.h>
#include <iostream>
#include <sys/ipc.h>
#include <sys/shm.h>

#include "112_common_sharedmem_process.h"

#define IPC_ERROR (-1)
#define IPC_CREATE_PERMISSION (0644) //this is octal
using namespace std;

static int get_shared_block(char *filename, int size)
{
	key_t key;
	int ret = IPC_ERROR;

	// get the key for this filename and the block #0 associated with it
	if (IPC_ERROR != (key = ftok(filename, 0)))
	{
		// proceed in case of valid key
		// get the shared memory block associated with that key
		ret = shmget(key, size, IPC_CREATE_PERMISSION | IPC_CREAT);
	}
	return ret;
}

char *attach_memory_block(char *filename, int size)
{
	int shared_block_id = get_shared_block(filename, size);
	char *res = NULL;

	if (IPC_ERROR == shared_block_id)
	{
		cout << "ERROR: get file key\n";
		return NULL;
	}
	else
	{
		// map the shared memory block to the process memory
		// shared memory attach
		res = (char*)shmat(shared_block_id, NULL, 0);
	}

	return res;
}

bool detach_memory_block(char *block)
{
	// shared memory detach
	// return TRUE if detachment is successful
	return (IPC_ERROR != shmdt(block));
}

bool destroy_memory_block(char *filename)
{
	int shared_block_id = get_shared_block(filename, 0);
	int ret = IPC_ERROR;

	if (IPC_ERROR != shared_block_id)
	{
		// remove block identifier
		ret = (IPC_ERROR != shmctl(shared_block_id, IPC_RMID, 0));
	}

	return ret;
}
