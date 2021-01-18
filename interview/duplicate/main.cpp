// function that removes all duplicated from a char string
// example: “hello zrygc world” => “helo zrygcwd”

#include <stdio.h>

void removeDuplicates(char *str)
{
    char cntr = 0;
    int map[8] = {0};

    for (int i = 0; str[i] != '\0'; i++)
    {
        char d = str[i] / 32;
        char r = str[i] % 32;

        if (((map[d] >> r) & 1) == 0)
        {
            *(str + cntr) = str[i];
            cntr++;
        }
        map[d] |= 1 << r;
    }
    *(str + cntr) = '\0';
}

int main(void)
{
    char str[] = "hello zrygc world";

    removeDuplicates(str);
    printf("result is: %s\n", str);
    return 0;
}