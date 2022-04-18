/* Copyright 2016 The MathWorks, Inc. */
#define _GNU_SOURCE

#if !( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <time.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <linux/input.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <linux/input.h>
#include <unistd.h>
#include <linux/fb.h>
#include <glob.h>
#endif

#include "MW_fbBlock.h"

#if !( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
int FRAMEBUFFER_INIT()
{
    glob_t glob_buffer;
    int i,ii;
    int fd;
    int status;
    char buffer[100];
    char fbname[] = "RPi-Sense FB";
    char fbpath[100];
    char *fbdevname;
    char *tempPath;
    FILE *fbfd;
    const char *pattern = "/sys/class/graphics/fb*";
    
    glob( pattern, 0, NULL, &glob_buffer);
    
    for(i=0;i<glob_buffer.gl_pathc;i++)
    {
        strcpy(fbpath,glob_buffer.gl_pathv[i]);
        strcat(fbpath,"/name");
        fbfd = fopen(fbpath,"r");
        fgets(buffer,100,fbfd);
        fclose(fbfd);
        
        if (strstr(buffer,fbname) != NULL) {
            tempPath = strdup(glob_buffer.gl_pathv[i]);
            fbdevname = basename(tempPath);
            strcpy(fbpath,"/dev/");
            strcat(fbpath,fbdevname);
            fd = open(fbpath, O_RDWR);
            break;
        }
    }
    
    globfree(&glob_buffer);
    
    return(fd);
}

int FRAMEBUFFER_WRITEPIXEL(int fd,  uint16_T pxllocation,  uint16_T pxlvalue)
{
    char *fbp = 0;
    int ii ;
    struct fb_var_screeninfo vinfo;
    long int screensize = 0;
    
    ioctl(fd, FBIOGET_VSCREENINFO, &vinfo);
    screensize = vinfo.xres * vinfo.yres * vinfo.bits_per_pixel / 8;
    fbp = (char *)mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    *((unsigned short int*)(fbp + pxllocation)) = pxlvalue;
    munmap(fbp, screensize);
    return(0);
}

int FRAMEBUFFER_DISPLAYIMAGE (int fd, uint8_t flip, uint16_T *imgArray)
{
    char *fbp = 0;
    int x,y;
    struct fb_var_screeninfo vinfo;
    long int screensize = 0;
    int pxllocation=0;
    char fileName[100];
    
    ioctl(fd, FBIOGET_VSCREENINFO, &vinfo);
    screensize = vinfo.xres * vinfo.yres * vinfo.bits_per_pixel / 8;
    fbp = (char *)mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if(flip == 0) {
        for (x=0; x<8; x++)
        {
            for(y=0; y<8; y++)
            {
                *((unsigned short int*)(fbp + 2*(y+(8*x)))) = *(imgArray + ((8*x)+y));
            }
        }
    }
    else{
        for (x=0;x<8;x++)
        {
            for(y=0;y<8;y++)
            {
                *((unsigned short int*)(fbp + 2*(x+(8*y)))) = *(imgArray + ((8*x)+y));
            }
        }
    }
    munmap(fbp, screensize);
    
    return(0);
}

    
    int FRAMEBUFFER_TERMINATE(int fd)
    {
        close(fd);
        return(0);
    }
    
#endif