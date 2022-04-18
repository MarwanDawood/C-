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
#include <glob.h>
#endif
#include "common.h"
#include "MW_joystickBlock.h"
#include "devices.h"

#define DEV_INPUT_EVENT "/dev/input"
#define EVENT_DEV_NAME "event"

#if !( defined(MATLAB_MEX_FILE) || defined(RSIM_PARAMETER_LOADING) ||  defined(RSIM_WITH_SL_SOLVER) )
int JOYSTICK_BLOCK_INIT()
{
    glob_t glob_buffer;
    int ii;
    int fd = 0;
    char buffer[100];
    char evdevpath[100];
    char *evdevname;
    char *bpath;
    char jsname[] = "Raspberry Pi Sense HAT Joystick";
    FILE *fbfd;
    const char *pattern = "/sys/class/input/event*";
    
    glob(pattern, 0, NULL, &glob_buffer);
        
    for(ii = 0; ii < glob_buffer.gl_pathc; ii++)
    {
        strcpy(evdevpath,glob_buffer.gl_pathv[ii]);
        strcat(evdevpath,"/device/name");
        fbfd=fopen(evdevpath,"r");
        fgets(buffer,100,fbfd);
        fclose(fbfd);
        if (strstr(buffer, jsname) != NULL)
        {
            bpath = strdup(glob_buffer.gl_pathv[ii]);
            evdevname = basename(bpath);
            strcpy(evdevpath,"/dev/input/");
            strcat(evdevpath,evdevname);
            fd = open(evdevpath, O_RDONLY);
            break;
        }
        
    }
    globfree(&glob_buffer);
    
    return (fd);
}

int JOYSTICK_BLOCK_READ(int fd)
{
    int key_enter, key_up, key_down, key_right, key_left;
    char key_map[KEY_MAX/8 +1];
    int value;    
    key_enter = KEY_ENTER;
    key_up = KEY_UP;
    key_down = KEY_DOWN;
    key_right = KEY_RIGHT;
    key_left = KEY_LEFT;
    memset(key_map,0,sizeof(key_map));
       
    ioctl(fd, EVIOCGKEY(sizeof(key_map)), key_map);
      
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
        value= 1;
    }
    else if ((keyb_up & mask_up) > 0) {
        value= 3;
    }
    else if ((keyb_down & mask_down) > 0) {
        value= 5;
    }
    else if ((keyb_right & mask_right) > 0) {
        value= 4;
    }
    else if ((keyb_left & mask_left) > 0) {
        value= 2;
    }
    else {
        value= 0;
    }
        
    return(value);
}
 int JOYSTICK_BLOCK_TERMINATE(int fd)
 {
     close(fd);
     return(0);
 }
 #endif
