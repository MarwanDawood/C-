/* Copyright 2018 The MathWorks, Inc. */
#include<stdio.h>
#include "common.h"
#include "handler.h"

/** makePeriodic:- This function is responsible to initialize the timer.
  * pdata:- Pointer to peripheralData structure.
**/
extern int makePeriodic(struct peripheralData *pdata);

/** waitperiod:- This function is responsible to wait the timer to expire.
  * pdata:- Pointer to peripheralData structure.
**/
extern void waitPeriod(struct peripheralData  *pdata);


/** gpioRead:- Thread function for timer based peripheral.
  * pdata:- Pointer to peripheralData structure.
**/
extern void *gpioRead(void  *pdata);

unsigned long long timeDiff(struct timespec *, struct timespec *);
