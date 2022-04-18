// Copyright 2016 The MathWorks, Inc.
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
#include <glob.h>
#include "common.h"
#include "joystick.h"
#include "devices.h"

#define DEV_INPUT_EVENT "/dev/input"
#define EVENT_DEV_NAME "event"

int EXT_JOYSTICK_INIT(char *sh_evdevName, uint16_t *FileNameLength)
{
    glob_t glob_buffer;
    int i,ii;
    int status;
    char buffer[100];
    char fbname[] = "Raspberry Pi Sense HAT Joystick";
    FILE *fbfd;
    const char *pattern = "/sys/class/input/event*/device/name";
    
    glob(pattern, 0, NULL, &glob_buffer);
    
    *FileNameLength = 0;
    for(i = 0; i < glob_buffer.gl_pathc; i++)
    {
        fbfd = fopen(glob_buffer.gl_pathv[i],"r");
        fgets(buffer,100,fbfd);
        fclose(fbfd);
        if (strstr(buffer, fbname) != NULL)
        {
            for(ii=0; ii<100 & glob_buffer.gl_pathv[i] != '\0'; ii++)
            {
                sh_evdevName[ii]= glob_buffer.gl_pathv[i][ii];
            }
            sh_evdevName[ii] = '\0';
            *FileNameLength = strlen(glob_buffer.gl_pathv[i]);
            break;
        }
    }
    globfree(&glob_buffer);
    
    if (0 == *FileNameLength) {
        status = ERR_JOYSTICK_NOTFOUND;
    }
    else {
        status = 0;
    }
    
    return status;
}


int EXT_JOYSTICK_READ(char *sh_evdevName,boolean_T *value)
{
    int key_enter, key_up, key_down, key_right, key_left;
    int fd = 0;
    char key_map[KEY_MAX/8 +1];
    int ii;
    char fileName[100] = {'\0'};
    
    key_enter = KEY_ENTER;
    key_up = KEY_UP;
    key_down = KEY_DOWN;
    key_right = KEY_RIGHT;
    key_left = KEY_LEFT;
    memset(key_map,0,sizeof(key_map));
   
    for(ii=0;(ii<100 & sh_evdevName[ii] != '\0');ii++)
    {
        fileName[ii]= sh_evdevName[ii];
    }
    
    fd = open(fileName, O_RDONLY);
    if (fd < 0) {
        return ERR_JOYSTICK_OPEN;
    }
    ioctl(fd, EVIOCGKEY(sizeof(key_map)), key_map);
    close(fd);
    
    int keyb_enter = key_map[key_enter/8];
    int keyb_up = key_map[key_up/8];
    int keyb_down = key_map[key_down/8];
    int keyb_right = key_map[key_right/8];
    int keyb_left = key_map[key_left/8];
    
    int mask_enter = 1 << (key_enter % 8);
    int mask_up = 1 << (key_up % 8);
    int mask_down = 1 << (key_down % 8);
    int mask_right = 1 << (key_right % 8);
    int mask_left = 1 << (key_left % 8);
    
    if ((keyb_enter & mask_enter) > 0) {
        *value=(boolean_T)1;
    }
    else if ((keyb_up & mask_up) > 0) {
        *value=(boolean_T)3;
    }
    else if ((keyb_down & mask_down) > 0) {
        *value=(boolean_T)5;
    }
    else if ((keyb_right & mask_right) > 0) {
        *value=(boolean_T)4;
    }
    else if ((keyb_left & mask_left) > 0) {
        *value=(boolean_T)2;
    }
    else {
        *value=(boolean_T)0;
    }
    // printf("keypressed = %d\n", keypress);
    
    return(0);
}