// Fig. 8.34: fig08_34.c
// Using function strerror
#include <stdio.h>
#include <string.h>
#include <errno.h>
int
main (void)
{
  printf ("%s\n", strerror (EACCES));
}				// end main
