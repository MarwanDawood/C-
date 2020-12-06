/*
 * 112_common_sharedmem_process.h
 *
 *  Created on: Jul 19, 2020
 *      Author: marwan
 */

#ifndef SHARED_MEMORY_PROCESS_H_
#define SHARED_MEMORY_PROCESS_H_

#define BLOCK_SIZE 4096
#define FILENAME ((char*)"112_read_sharedmem_process.cpp")

char *attach_memory_block(char *filename, int size);
bool detach_memory_block(char *block);
bool destroy_memory_block(char *filename);

#endif /* SHARED_MEMORY_PROCESS_H_ */
