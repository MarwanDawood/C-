/*
 * 109_threads_arg.cpp
 *
 *  Created on: Jul 12, 2020
 *      Author: marwan
 */

#include <pthread.h> // to link code, -pthread shall be added to g++ command
#include <iostream>
#include <unistd.h>


using namespace std;

void* myTurn(void *arg)
{
	int *ptr1 = (int*)arg;
	int *ptr2 = (int*)malloc(sizeof(int));

	*ptr2 = 10;

	for(int n = 0; n < 6; n++)
	{
		cout << "my turn! " << *ptr1 << endl;
		(*ptr1)++;
		(*ptr2)++;
		sleep(2);
	}
	return ptr2;
}

void yourTurn(void)
{
	for(int n = 0; n < 3; n++)
	{
		cout << "your turn! " << n << endl;
		sleep(1);
	}
}

int main(void)
{
	pthread_t newThread;
	int x = 0;
	int **ret; // or int *ret;

	// last parameter is for thread arguments
	pthread_create(&newThread, NULL, myTurn, &x);
	yourTurn();
	// to make main() waits till thread is completed
	// last parameter is for thread return
	// it accpets pointer to the pointer
	pthread_join(newThread, (void**)ret); // or (void**)&ret
	cout << "thread return is " << **ret << endl; // or *ret

	return 0;
}


