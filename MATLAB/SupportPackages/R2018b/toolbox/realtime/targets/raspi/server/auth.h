// Copyright 2015 The MathWorks, Inc.
#ifndef _MW_AUTH_H_
#define _MW_AUTH_H_
#include "common.h"

#define ERR_AUTH_BASE      (11000)
#define ERR_AUTH_ERROR     (ERR_AUTH_BASE)

extern int EXT_SYSTEM_authorize(char *hash);

#endif // _MW_AUTH_H_