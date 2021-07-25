#include <stdio.h>

#define NAME_MAX 10

int main(void)
{
    static char name[NAME_MAX + 2]; // + 2 because of newline and null
    if(!fgets(name, sizeof(name), stdin))
    {
        fputs("io error\n", stderr);
        return 1;
    }

    // don't print newline
    printf("Hello %.*s. Nice to meet you.\n", strlen(name) - 1, name);
}
