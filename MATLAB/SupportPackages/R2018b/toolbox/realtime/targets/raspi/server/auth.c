// Copyright 2013-2015 The MathWorks, Inc.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define HASH_SIZE    (256)
#define HASH_PREFIX  "/tmp/."
#define FAILURE_WAIT (3)

static int verifyHash(char *hash)
{
    FILE *fp;
    char buf[HASH_SIZE+6] = HASH_PREFIX;
    int hash_pid;
    
    strncat(buf, hash, HASH_SIZE);
    bzero((char *)hash, strlen(hash));
    fp = fopen(buf,"r+");
    if (fp == NULL) {
        printf("Cannot open %s\n", hash);
        return -1;
    }
    if (fscanf(fp, "%d", &hash_pid) != 1) {
        printf("No hash pid\n");
        return -1;
    }
    ftruncate(fileno(fp), 0);
    fclose(fp);
    unlink(buf);
    
    // Test hash
    if (hash_pid != getpid()) {
        return -1;
    }
    
    return(0);
}

// External interface for user authentication
int EXT_SYSTEM_authorize(char *hash)
{
    if (verifyHash(hash) != 0) {
        sleep(FAILURE_WAIT);
        return -1;
    }
    
    return(0);
}

#ifdef TEST_EXT_SYSTEM_authorize
int main(int argc, char **argv)
{
    int ret;
    
    if (argc != 1) {
        fprintf(stderr, "Usage: %s\n", argv[0]);
        return 1;
    }
    
    // Call authorization function
    ret = EXT_SYSTEM_authorize();
    if (ret == 0) {
        fprintf(stdout, "Success.\n");
    }
    else {
        fprintf(stdout, "Wrong username or password.\n");
    }
    
    return 0;
}
#endif

/* EOF */