#include <iostream>
#include <set>
#include <map>
using namespace std;

//creating our own comparator
template <typename type>
struct mycomp {
	bool operator() (const type & first, const type & second) const {
		//here we are ordering based on the second element (the values and not the keys)
		return first.second < second.second;
	}
};
int main(void)
{
	//std::less means it will start from smallest value
	// (this is the default parameter)
	set<int, less<int>> st;
	st.insert(100), st.insert(200), st.insert(40), st.insert(10), st.insert(100);
	for (auto &itr:st)
		cout<<itr<<" - "<<endl;

	cout<<endl;
	//std::greater means it will start from biggest value
	map<int, string, greater<int>> mp;
	mp[10]="abc", mp[40]="def", mp[20]="xyz";
	for (auto &itr:mp)
		cout<<itr.first<<" - "<<itr.second<<endl;

	cout<<endl;
	//customized comparator
	set<pair<int, int>, mycomp<pair<int, int>>> stcmpr;
	stcmpr.insert({10, 40}), stcmpr.insert({20, 30}), stcmpr.insert({100, 300}), stcmpr.insert({80, 50});
	for (auto &itr:stcmpr)
		cout<<itr.first<<" - "<<itr.second<<endl;

}
