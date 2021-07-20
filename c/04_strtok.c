// Fig. 8.26: fig08_26.c
// Using function strtok
#include <stdio.h>
#include <string.h>
int
main (void)
{
// initialize array string
  char string[] = "This is a sentence with 7 tokens";
  char *tokenPtr;		// create char pointer
  printf ("%s\n%s\n\n%s\n",
	  "The string to be tokenized is:", string, "The tokens are:");
  tokenPtr = strtok (string, " ");	// begin tokenizing sentence
// continue tokenizing sentence until tokenPtr becomes NULL
  while (tokenPtr != NULL)
    {
      printf ("%s\n", tokenPtr);
      /* These calls contain NULL as their first argument. The NULL argument indicates that the call to strtok should
         continue tokenizing from the location in string saved by the last call to strtok . */
      tokenPtr = strtok (NULL, " ");	// get next token
    }				// end while
}				// end main
