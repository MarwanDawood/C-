/*
 * 110_threads_mutex.cpp
 *
 *  Created on: Jul 12, 2020
 *      Author: marwan
 */
// Threads shall be used when there is some heavy-lifting on one process and you whant
// to handle some other easy tasks in the other thread (you need the results concurrently)
// While process shall be used for the extensive processing

#include <iostream>
#include <pthread.h>

#define BIG	   1000000000

using namespace std;
int counter = 0;
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

// parallelism : two threads running in parallel on different cores at the same time
// concurrency : two threads are running on the same core and the system keep switching
//               between them and this shared memory switching/handling causes slower execution
void *count_big_thread(void* arg)
{
	for (int n = 0; n < BIG; n++)
	{
		pthread_mutex_lock(&lock);
		counter++;
		pthread_mutex_unlock(&lock);
	}

	return NULL;
}

int main(void)
{
	pthread_t t;

	// threads shall avoid "race conditions" and be thread-safe
	pthread_create(&t, NULL, count_big_thread, NULL);
	count_big_thread(NULL);
	pthread_join(t, NULL);

	cout << "sum value is " << counter << endl;
	return 0;
}
