/*
 * 111_coredump.cpp
 *
 *  Created on: Jul 12, 2020
 *      Author: marwan
 */

#include <iostream>
#include <unistd.h>

using namespace std;

int main(void)
{
	int rnum = 0;
	int *good_ptr = (int*)malloc(sizeof(int));
	int *bad_ptr = NULL;

	// initializing random number generator with the seed
	srand(time(NULL));

	while(1)
	{
		// getting a random number in the range 0 - 255
		rnum = rand() % 255;
		if (rnum == 13)
		{
			*bad_ptr = rnum;
		}
		else
		{
			*good_ptr = rnum;
		}
		cout << "Random number is " << rnum << endl;
		usleep(10);
	}
	return 0;
}


