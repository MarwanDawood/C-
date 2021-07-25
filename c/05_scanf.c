#include <stdio.h>

#define NAME_MAX    10
#define NAME_MAX_S "10"

int main(void)
{
    static char name[NAME_MAX + 1]; // + 1 because of null
    if(scanf("%" NAME_MAX_S "[^\n]", name) != 1)
    {
        fputs("io error or premature end of line\n", stderr);
        return 1;
    }

    printf("Hello %s. Nice to meet you.\n", name);
}
