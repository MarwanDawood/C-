//#include <iostream>
//using namespace std;
#include <stdio.h>
#define LEN (5)

int arr[][LEN] = {
    {1, 2, 3, 2, 1},
    {0, 0, 0, 0, 0},
    {2, 4, 1, 4, 1},
    {1, -1, 0, -1, 1},
    {-2, -1, -2, -2, -2}};

int pali(int *arr)
{
    int i = 0;
    int j = LEN - 1;
    int cnt = 0;

    while (arr[i] == arr[j])
    {
        i++;
        j--;
        cnt++;
        if (cnt == (LEN / 2))
        {
            return 1;
        }
    }
    return 0;
}

int main(void)
{
    for (int i = 0; i < (int)(sizeof(arr) / (sizeof(int) * LEN)); i++)
    {
        //cout << "result is " << pali(arr[i]) << endl;
        printf("Test %d result is %d\n", i, pali(arr[i]));
    }
}
