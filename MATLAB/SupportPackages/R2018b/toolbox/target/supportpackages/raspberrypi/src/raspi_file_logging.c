/* 
 *
 * Copyright 2017-2018 The MathWorks, Inc.
 *
 * File: raspi_file_logging.c
 *
 *
 */

#define MW_STRINGIFY(x) #x
#define MW_TOSTRING(x) MW_STRINGIFY(x)

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "rtwtypes.h"
#include <sys/stat.h>
#include "ert_targets_logging.h"

#if !defined(MAT_FILE) || (defined(MAT_FILE) && MAT_FILE == 1)

FILE *MW_fopen(const char *filename, const char *mode)
{
#if defined(MAT_FILE_LOC) && defined(MAX_MATFILE_NAME_LEN)
    char fileInHomeDir[MAX_MATFILE_NAME_LEN];
    sprintf(fileInHomeDir,"%s/%s",MW_TOSTRING(MAT_FILE_LOC),filename);
    return fopen(fileInHomeDir,mode);
#else
    return fopen(filename,mode);
#endif
}


size_t MW_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream)
{
  return fwrite(ptr, size, nmemb, stream);
}

size_t MW_fread(void *ptr, size_t size, size_t nmemb, FILE *stream)
{
   return fread(ptr, size, nmemb, stream);
}

void MW_rewind(FILE *stream)
{
    rewind(stream);
}

int MW_fclose(FILE *stream)
{
    return (int)fclose(stream);
}

int MW_remove(const char *filename) 
{
	remove(filename);
}

#endif
