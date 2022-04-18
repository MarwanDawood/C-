// Copyright 2013 The MathWorks, Inc.
#ifndef _MW_LED_H_
#define _MW_LED_H_
#include "common.h"

#define ERR_LED_BASE               (1000)
#define ERR_LED_OPEN               (ERR_LED_BASE+1)
#define ERR_LED_GET_TRIGGER_OPEN   (ERR_LED_BASE+2)
#define ERR_LED_GET_TRIGGER_READ   (ERR_LED_BASE+3)
#define ERR_LED_SET_TRIGGER_OPEN   (ERR_LED_BASE+4)
#define ERR_LED_SET_TRIGGER_WRITE  (ERR_LED_BASE+5)
#define ERR_LED_WRITE_OPEN         (ERR_LED_BASE+6)
#define ERR_LED_WRITE_WRITE        (ERR_LED_BASE+7)

extern int EXT_LED_setTrigger(const unsigned int id, const char *trigger);
extern int EXT_LED_write(const unsigned int id, const boolean_T value);
extern int EXT_LED_getTrigger(const unsigned int id, char *trigger, unsigned int readSize);

#endif /* _MW_LED_H_ */