#include <stdio.h>
#include "MW_raspi_init.h"

// Overrun detection function
void reportOverrun(int taskId)
{
    printf("Overrun detected: The sample time for the rate %d is too short.\n", taskId);
    fflush(stdout); 
}