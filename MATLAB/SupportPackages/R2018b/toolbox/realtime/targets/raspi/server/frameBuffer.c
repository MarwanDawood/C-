#define _GNU_SOURCE

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
#include "common.h"
#include "frameBuffer.h"
#include "devices.h"


int EXT_FRAMEBUFFER_INIT(char *sh_fbname, uint16_t *FileNameLength)
{
    glob_t glob_buffer;
    int i,ii;
    int status;
    char buffer[100];
    char fbname[] = "RPi-Sense FB";
    FILE *fbfd;
    const char *pattern = "/sys/class/graphics/fb*/name";
    
    glob( pattern, 0, NULL, &glob_buffer);

    *FileNameLength = 0;
    for(i=0;i<glob_buffer.gl_pathc;i++)
    {
        fbfd = fopen(glob_buffer.gl_pathv[i],"r");
        fgets(buffer,100,fbfd);
        fclose(fbfd);
        
        if (strstr(buffer,fbname) != NULL) {
            for(ii=0;ii<100 & glob_buffer.gl_pathv[i] != '\0';ii++)
            {
                sh_fbname[ii]= glob_buffer.gl_pathv[i][ii];                
            }
            sh_fbname[ii] = '\0';
            *FileNameLength =strlen(glob_buffer.gl_pathv[i]);
            break;
        }
    }
    
    if (0 == *FileNameLength) {
        status = ERR_FRAMEBUFFER_NOTFOUND;
    }
    else {
        status = 0;
    }

    globfree(&glob_buffer);
    
    return status;    
}

int EXT_FRAMEBUFFER_WRITEPIXEL(char *sh_fbname, const uint16_t pxllocation, const uint16_t pxlvalue)
{
    int fbfd = 0;
    char *fbp = 0;
    int ii ;
    struct fb_var_screeninfo vinfo;
    long int screensize = 0;
    
    fbfd = open(sh_fbname, O_RDWR);
    if (fbfd < 0) {
        return ERR_FRAMEBUFFER_OPEN;
    }
    ioctl(fbfd, FBIOGET_VSCREENINFO, &vinfo);
    screensize = vinfo.xres * vinfo.yres * vinfo.bits_per_pixel / 8;
    fbp = (char *)mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fbfd, 0);
    *((unsigned short int*)(fbp + pxllocation)) = pxlvalue;
    munmap(fbp, screensize);
    close(fbfd);
    return(0);
}

int EXT_FRAMEBUFFER_DISPLAYIMAGE(char *sh_fbname, const uint8_t flip, const uint16_t *imgArray)
{
    int fbfd = 0;
    char *fbp = 0;
    int x,y,ii;
    struct fb_var_screeninfo vinfo;
    long int screensize = 0;
    int pxllocation=0;
    char fileName[100];
    
    for(ii=0; ii<100 & sh_fbname[ii] != '\0'; ii++)
    {
        fileName[ii]= sh_fbname[ii];                
    }
    fbfd = open(sh_fbname, O_RDWR);
    if (fbfd < 0) {
        return ERR_FRAMEBUFFER_OPEN;
    }
    ioctl(fbfd, FBIOGET_VSCREENINFO, &vinfo);
    screensize = vinfo.xres * vinfo.yres * vinfo.bits_per_pixel / 8;
    fbp = (char *)mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fbfd, 0);
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
    close(fbfd);
    return(0);
}

void fliplr(uint16_t *strArray, uint16_t len){
    uint16_t begin = 0;
    uint16_t end = len-1;
    while(begin<end){
        uint16_t temp = strArray[begin];
        strArray[begin++] = strArray[end];
        strArray[end--] = temp;
    }
}

int EXT_FRAMEBUFFER_DISPLAYMESSAGE(char *sh_fbname, uint16_t *strArray, const uint16_t strArrayLen, const uint16_t orientation, const uint16_t scrollSpeed)
{
    int result = 0;
    uint16_t offset;
    uint8_t flip = (orientation==0||orientation==180)?1:0;
    if(orientation==180 || orientation==270){
        // flip strArray from left to right
        fliplr(strArray,strArrayLen);
    }
    
    struct timespec tim;
    tim.tv_sec = (time_t)(scrollSpeed/1000);// scrollSpeed is sent in unit of milliseconds
    tim.tv_nsec = (scrollSpeed-tim.tv_sec*1000)*1000000L;
    //printf("%lld.%.9ld\n", (long long)tim.tv_sec, tim.tv_nsec);

    // display message at scrolling speed
    for(offset=0; offset<(strArrayLen-64)/8; ++offset){
        switch(orientation){
            case 0:
            case 90:{
                // starting from the beginning of the array, take a sliding window of 64 samples at every 8 sample
                result = EXT_FRAMEBUFFER_DISPLAYIMAGE(sh_fbname,flip,strArray+8*offset);
                break;
            }
            case 180:
            case 270:{
                // starting from the end of the array, take a sliding window of 64 samples at every 8 sample 
                result = EXT_FRAMEBUFFER_DISPLAYIMAGE(sh_fbname,flip,strArray+strArrayLen-8*offset-64);
                break;
            }
            default:{
                printf("invalid orientation value: %d",orientation);
                return ERR_FRAMEBUFFER_ORIENTATION;
            }
        }
        if(result!=0){
            return result;
        }

        nanosleep(&tim, NULL);
    }  

    // clear the LEDMatrix after completion of the display
    const uint16_t emptyArray[64] = {0};
    result = EXT_FRAMEBUFFER_DISPLAYIMAGE(sh_fbname,0,emptyArray);
    return result;
}