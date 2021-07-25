#include <iostream>
#include "catch.h"
using namespace std;

extern int varr;
int main()
{
    if (varr==100)
        cout << "Test CMake!\n";
    else
        cout << "Test CMakeNot linked!\n";
    return 0;
}