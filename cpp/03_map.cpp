#include <iostream>
#include <map>

using namespace std;

int main(void)
{
    //pair of key and value
    pair<int, int> p = make_pair(1,20);
    cout<<p.first<<"-"<<p.second<<endl;
    
    //map is always sorted by key
    //unordered_map is similar to map but keys are not sorted
    //multimap is a map that accepts multiple values with the same key
    //it can add data with insert() only
    map<int, int> mp;
    
    mp[2]=300;
    mp[1]=100;
    mp.insert(make_pair(5,400));
    map<int, int>::iterator it = mp.begin();
    
    //iterate
    for(it = mp.begin(); it != mp.end(); it++)
    {
        cout<<it->first<<"---"<<it->second<<endl;
    }
    return 0;
}
