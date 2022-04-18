# Copyright 2013-2019 The MathWorks, Inc.
#
# 

#OPTIM = -g -O0 -D_DEBUG
OPTIM   = -O2
CC      = gcc
OBJDIR  = obj
EXENAME = matlabIOserver
 
INCLUDE+= -I/opt/userland
INCLUDE+= -I/opt/userland/host_applications/linux/libs/bcm_host/include
INCLUDE+= -I/opt/userland/interface/vcos
INCLUDE+= -I/opt/userland/interface/vcos/pthreads
INCLUDE+= -I/opt/userland/interface/vmcs_host/linux
INCLUDE+= -I/opt/userland/host_applications/linux/apps/raspicam
INCLUDE+= -I/opt/nanomsg/include
CFLAGS  = $(OPTIM) -Wall $(INCLUDE) -Winline -pipe -D_DEBUG -D_MATLABIO_
LDFLAGS = -L/opt/vc/lib 
LIBS    = -lmmal -lmmal_core -lmmal_util -lmmal_vc_client -lvcos -lbcm_host -lpthread -lasound -lm -lnanomsg

SRC = auth.c \
      server.c \
      handler.c \
      devices.c \
      LED.c \
      GPIO.c \
      I2C.c \
      SPI.c \
      serial.c \
      system.c \
      picam.c \
      ip_server.c \
      v4l2_cam.c \
      MW_pigs.c \
      RaspiCamControl.c \
      RaspiPreview.c \
      RaspiCLI.c \
      RaspiHelpers.c \
      RaspiCommonSettings.c \
      joystick.c \
      frameBuffer.c \
      alsa_rdwr.c \
      TimerBasedRecorder.c \
      UdpRecorder.c \
      AudioRecorder.c \
      recorder.c\
     
# Tell compile to search for *.c files in ../raspicam as well
vpath %.c /opt/userland/host_applications/linux/apps/raspicam

OBJ = $(patsubst %.c,$(OBJDIR)/%.o,$(SRC)) 

$(OBJDIR)/%.o : %.c
	@echo [Compiling] $<
	$(CC) -c $(CFLAGS) -DNANOMSG_TRANSPORT=1  $< -o $@

# Make calls first target as the default target
all: directories build

directories:
	@mkdir -p $(OBJDIR)

build:	$(OBJ)
	echo [Linking]
	@$(CC) -o $(EXENAME) $(OBJ) $(LDFLAGS) $(LIBS)

# Dependencies
auth.c: common.h auth.h
server.c: common.h server.h handler.h devices.h
handler.c: common.h handler.h devices.h LED.h GPIO.h I2C.h SPI.h serial.h system.h MW_pigs.h joystick.h frameBuffer.h  TimerBasedRecorder.h
devices.c: common.h devices.h
LED.c: common.h LED.h
GPIO.c: common.h GPIO.h
I2C.c: common.h I2C.h
SPI.c: common.h SPI.h
serial.c: common.h serial.h
system.c: common.h system.h
picam.c: common.h picam.h
ip_server.c: common.h ip_server.h
v4l2_cam.c: common.h v4l2_cam.h
joystick.c: common.h joystick.h
frameBuffer.c: common.h frameBuffer.h
MW_pigs.c: common.h MW_pigs.h
TimerBasedRecorder.c :common.h TimerBasedRecorder.h handler.h dataCapture.h
UdpRecorder.c : common.h UdpRecorder.h handler.h
AudioRecorder.c :common.h AudioRecorder.h handler.h alsa_rdwr.h
recorder.c : recorder.h
.PHONY: exename
exename:
	@echo $(EXENAME)

.PHONY:	clean
clean:
	@echo "[Clean]"
	@rm -f $(OBJ)

.PHONY:	depend
depend:
	makedepend -Y $(SRC)

