/*
 * 07_stack_queue_prio.cpp
 *
 *  Created on: Jul 20, 2020
 *      Author: marwan
 */

#include <iostream>
#include <stack>
#include <queue>

using namespace std;

int main(void)
{
	//stack<int> stck;
	stack<int, deque<int>> stck;  // this is the default built-in datatype
	//stack<int, vector<int>> stck;
	stck.push(100);
	stck.push(300);
	stck.push(200);

	//while(0 != stck.size())
	while(!stck.empty())
	{
		cout << stck.top() << endl; // print top stack element
		stck.pop();	// remove the top element from the stack
	}

	/*** QUEUE ***/
	cout << endl;
	//queue<int> q;
	queue<int, deque<int>> q;  // this is the default built-in datatype

	q.push(100);
	q.push(300);
	q.push(200);

	while(!q.empty())
	{
		cout << "front is " << q.front() << endl;
		cout << "back is " << q.back() << endl;
		q.pop();
	}

	/*** PRIORITY QUEUE ***/
	// it is a queue sorted in the descending order
	cout << endl;
	//priority_queue<int> pq;
	//priority_queue<int, deque<int>, less<int>> pq;  // this is the default built-in datatype
	priority_queue<int, vector<int>, greater<int>> pq; // to change it to ascending order

	pq.push(100);
	pq.push(30);
	pq.push(400);
	pq.push(129);

	while(!pq.empty())
	{
		cout << pq.top() << endl;
		pq.pop();
	}
	return 0;
}

