#include <iostream>
//doubly linked list
#include <list>
#include <algorithm>

using namespace std;

int main(void)
{
    //sequence container
    list<int> v;
    
    v.push_back(10);
    v.push_back(20);
    
    //iterator are similar to pointers
    list<int>::iterator itr = v.begin();
    cout<<*itr<<endl;
    
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
