#include <iostream>
#include <set>
#include <map>
using namespace std;

//Set: associative containers just like maps
//only one value (key value)

//multiset: allows for multiple duplicate values
int main(void)
{
	map<int, string> mp;
	
	multiset<int> st;
	st.insert(100), st.insert(200), st.insert(40), st.insert(10), st.insert(100);
	st.erase(40);
	st.erase(st.begin());

	for (auto &itr : st)
		cout<<itr<<endl;
}
