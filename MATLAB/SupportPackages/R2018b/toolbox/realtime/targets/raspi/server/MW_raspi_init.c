#include <stdio.h>
#include <stdlib.h>
#include "MW_raspi_init.h"

extern void main_terminate(void);
// Overrun detection function
void mwRaspiInit(void)
{
#ifdef MW_MATLABTARGET
    printf("**** Starting the application ****\n");
    fflush(stdout);
    
    /*Signal Handling */
    signal(SIGTERM, main_terminate);     /* kill */
    signal(SIGHUP, main_terminate);      /* kill -HUP */
    signal(SIGINT, main_terminate);      /* Interrupt from keyboard */
    signal(SIGQUIT, main_terminate);     /* Quit from keyboard */
#endif
}

int mwRaspiTerminate(void)
{
#ifdef MW_MATLABTARGET
    printf("**** Stopping the application ****\n");
    fflush(stdout);
    exit(1);
#endif
    return(1);
}

// Overrun detection function
void reportOverrun(int taskId)
{
#ifdef MW_RASPI_DETECTOVERRUN
    printf("Overrun detected: The sample time for the rate %d is too short.\n", taskId);
    fflush(stdout);
#endif
}