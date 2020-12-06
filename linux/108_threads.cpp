/*
 * 108_threads.cpp
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
	for(int n = 0; n < 6; n++)
	{
		cout << "my turn! " << n << endl;
		sleep(2);
	}
	return NULL;
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

	pthread_create(&newThread, NULL, myTurn, NULL);
	// myTurn();
	yourTurn();
	// to make main() waits till thread is completed
	pthread_join(newThread, NULL);

	return 0;
}


