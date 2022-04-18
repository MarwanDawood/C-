/* Copyright 2018 The MathWorks, Inc. */

#include "MW_raspisystem.h"

int MW_execSystemCmd(char *cmd, uint32_t outSize, char *out)
{
    int ret = 0,bufferLoc = 0;
    FILE *fp;
    char buffer[outSize];
    size_t readLength = 0;
    
    fp = popen(cmd,"r");
    if (fp == NULL){
        printf("Error in executing the cmd \n");
        return -1;
    }
    
    /*Read the cmd output if any */
    while (fgets((buffer+bufferLoc),(outSize - bufferLoc),fp) != NULL){
        readLength = strlen(buffer+bufferLoc);
        
        if((bufferLoc+readLength) < outSize){
            /*Advance the pointer to new location */
            bufferLoc += readLength;
        }
        else{
            /*cmd output exceeds outSize chars*/
            break;
        }
    }
    
    sprintf(out,"%s",buffer);
    
    return ret;
}
