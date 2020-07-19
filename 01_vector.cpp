#include <iostream>
//contiguous memory allocation
#include <vector>
#include <algorithm> //to use sort()

using namespace std;

int main(void)
{
    //sequence container
    vector<int> v;
    
    v.push_back(10);
    v.push_back(20);
    v.push_back(5);
    
    //iterator are similar to pointers
    vector<int>::iterator itr = v.begin();
    cout<<*itr<<endl;
    
    //it needs vector because vector is random memory allocation
    sort(v.begin(), v.end());
    //print the iterator
    for(; itr != v.end(); itr++)
    {
        cout<<*itr<<endl;
    }
    cout<<"size => "<<v.size()<<endl;
    v.clear();
    cout<<"size => "<<v.size()<<endl;
    
    return 0;
}
