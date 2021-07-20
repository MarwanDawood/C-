// Fig. 8.32: fig08_32.c
// Using function memset
#include <stdio.h>
#include <string.h>
int
main (void)
{
  char string1[10];
  printf ("Enter 10 haracters: ");
  scanf ("%s", string1);
  printf ("string1 = %10s\n", string1);
  printf ("string1 after memset = %s\n", (char *) memset (string1, 'b', 5));
}				// end main
