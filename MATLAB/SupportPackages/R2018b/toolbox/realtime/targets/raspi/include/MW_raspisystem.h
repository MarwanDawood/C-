/* Copyright 2018 The MathWorks, Inc. */
#ifndef _MWRASPISYSTEM_H_
#define _MWRASPISYSTEM_H_
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

int MW_execSystemCmd(char *cmd, uint32_t outSize, char *out);

#endif
