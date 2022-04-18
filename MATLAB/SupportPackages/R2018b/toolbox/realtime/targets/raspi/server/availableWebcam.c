/* Copyright 2018 The MathWorks, Inc. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "availableWebcam.h"


extern void main_terminate(void);
void MW_trim(char* str)
{
    int index, i;
    /* Trim leading white spaces  */
    index = 0;
    while(str[index] == ' ' || str[index] == '\t' || str[index] == '\n')
    {
        index++;
    }
    /* Shift all trailing characters to its left */
    i = 0;
    while(str[i + index] != '\0')
    {
        str[i] = str[i + index];
        i++;
    }
    str[i] = '\0'; // Terminate string with NULL
    
    /* Trim trailing white spaces  */
    i = 0;
    index = -1;
    while(str[i] != '\0')
    {
        if(str[i] != ' ' && str[i] != '\t' && str[i] != '\n')
        {
            index = i;
        }
        
        i++;
    }
    /* Mark the next character to last non white space character as NULL */
    str[index + 1] = '\0';
}

void getCameraList()
{
    /*Get the list of aweb cameras*/
    FILE *fp;
    char webCamName[1024];
    int i = 0;
    
    
    /* Open the command for reading. */
    fp = popen("/usr/bin/v4l2-ctl --list-devices", "r");
    if (fp == NULL) {
        MW_REPORT_ERROR("Failed to read camera list\n" );
        main_terminate();
    }
    
    /* Read the output a line at a time - output it. */
    
    while (fgets(webCamName, sizeof(webCamName)-1, fp) != NULL)
    {
        MW_trim(webCamName);
        strcpy(wc[i].Name,webCamName);
        fgets(webCamName, sizeof(webCamName)-1, fp);
        MW_trim(webCamName);
        strcpy(wc[i].Address,webCamName);
        //remove the trailing new line
        fgets(webCamName, sizeof(webCamName)-1, fp);
        //register the count of available webcam
        numberOfConnetions++;
        i++;
    }
    
    /*Get the list of supported resolution for each camera*/
    getCameraResolution();
    
}

int getCameraAddrIndex(char* cameraName)
{
    
    /* For the given camera name, find its index in the availablewebcam structure*/
    int i,j;
    
    MW_trim(cameraName);
    
    
    for (i = 0 ; i < (numberOfConnetions);i++ )
    {
        
        if (strcmp(cameraName,wc[i].Name) ==0)
        {
            return(i);
        }
    }
    MW_REPORT_ERROR("Selected Web Camera did not match any available Web Cameras on your Raspberry Pi.\n");
    MW_REPORT_ERROR_ARGS1("Selected Web Camera :\n%s\n",cameraName);
    MW_REPORT_ERROR("Available Web Cameras:\n");
    MW_REPORT_ERROR("Index\t||\tName\t||\tAddress\t\n");
    for (j = 0; j <(numberOfConnetions); j++)
    {
        MW_REPORT_ERROR_ARGS3("%d\t||%s||%s\n",j,wc[j].Name,wc[j].Address);
    }
    main_terminate();
    
}



void getCameraResolution()
{
    FILE *fp;
    int i=0,j=0,res1,res2;
    static int indx_count = 0;
    char webCamRes[1024],queryString[1024],res1_str[32],res2_str[32];
    char *token;
    char *search = "x";
    char *cameraBoardName = "bcm2835-v4l2";
    char cameraBoardRes[7][10]={"160x120","320x240","640x480","800x600","1024x768","1280x720","1920x1080"};
    
    
    /*Get the supported resolutions*/
    for (i = 0 ; i < numberOfConnetions; i++)
    {
        if(strstr(wc[i].Name, cameraBoardName) != NULL)
        {
           for(j = 0; j < 7; j++)
           {
                MW_stringSplit(cameraBoardRes[j],"x",res1_str,res2_str);
                
                res1 = MW_convertstring2num(res1_str);
                wc[i].wcr[j].imWidth= res1;

                res2 = MW_convertstring2num(res2_str);
                wc[i].wcr[j].imHeight = res2;
                
                numSupportedRes[i]++;	                
           }
           
        }else
        {
            sprintf(queryString,"v4l2-ctl -d %s --list-framesize=YUYV | awk '{if(NR>1)print $3}'",wc[i].Address);

            fp = popen(queryString, "r");
            if (fp == NULL) {
                MW_REPORT_ERROR("Failed to read camera resolutions\n" );
            }
            j = 0;
            while (fgets(webCamRes, sizeof(webCamRes)-1, fp) != NULL)
            {
                MW_trim(webCamRes);
                strcpy(wc[i].wcr[j].resolution,webCamRes);        

                /*Split the resolution sring to a nd y resolutions*/
                MW_stringSplit(wc[i].wcr[j].resolution,"x",res1_str,res2_str);
                res1 = MW_convertstring2num(res1_str);
                wc[i].wcr[j].imWidth= res1;

                res2 = MW_convertstring2num(res2_str);
                wc[i].wcr[j].imHeight = res2;
        		j++;  
                numSupportedRes[i]++;	
            }
            pclose(fp);
        }        
    }
}

int validateResolution(int camIndex, int imwidth, int imheight)
{
    int i;

    for (i =0; i < (numSupportedRes[camIndex]); i++)
    {
        if ((imwidth == wc[camIndex].wcr[i].imWidth)&&(imheight == wc[camIndex].wcr[i].imHeight))
        {
            return(1);
        }
    }
    /* If no match could be found, print an error and exit*/
    MW_REPORT_ERROR_ARGS2("Specified camera resolution of [%d %d] is not supported.\n",imwidth,imheight);
    MW_REPORT_ERROR("Supported resolutions:\n");
    for (i =0; i < (numSupportedRes[camIndex]-1); i++)
    {
        MW_REPORT_ERROR_ARGS2("[%d, %d]\n",wc[camIndex].wcr[i].imWidth,wc[camIndex].wcr[i].imHeight);
    }

    main_terminate();
}

int MW_convertstring2num(char* numString)
{
    int x;
    sscanf(numString, "%d", &x);
    return(x);
}

void MW_stringSplit(char* OrignalStr, char* search, char* str1, char* str2)
{
    char *token;
    char OrgStr_tmp[1024];

    strcpy(OrgStr_tmp,OrignalStr);

    token = strtok(OrgStr_tmp, search);
    strcpy(str1,token); 
    

    token = strtok(NULL, search);
    strcpy(str2,token); 
    
}

/* LocalWords:  aweb usr ctl webcam availablewebcam framesize YUYV awk sring
 */
