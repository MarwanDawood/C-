/*
 * 104_maloc.cpp
 *
 *  Created on: Jul 6, 2020
 *      Author: marwan
 */


#include <iostream>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>

using namespace std;

int main(void)
{
	for (int i = 0; i < 5; i++)
	{
		void *ptr = malloc(50000);
		cout << "Got memory, address is " << ptr << endl;
	}
}
