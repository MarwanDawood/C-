%% Running Linux(R) Shell Commands
%
% This example shows you how to run Linux shell commands on your Raspberry
% Pi(R) hardware.
 
% Copyright 2012-2015 The MathWorks, Inc.


%% Introduction
%
% Raspberry Pi hardware runs a Linux(R) distribution as the operating
% system. Using utilities shipped in the Simulink Support Package for
% Raspberry Pi Hardware, you can remotely execute Linux shell commands on
% the Raspberry Pi hardware directly from the MATLAB(R) command line. For
% example, you can run and stop a Simulink(R) model, list the contents of a
% directory, look up the CPU load of a process running on the Raspberry Pi
% hardware, etc. You can also launch an interactive SSH session
% directly from within MATLAB.

%% Prerequisites
%
% * We recommend completing
% <raspberrypi_gettingstarted.html Getting Started with Raspberry Pi(R) Hardware> example. 


%% Create a Communication Object
%
% Simulink Support Package for Raspberry Pi Hardware uses an SSH connection
% over TCP/IP to remotely execute Linux shell commands while building and
% running Simulink models on the Raspberry Pi hardware. You can use the
% infrastructure developed for this purpose to communicate with the
% Raspberry Pi hardware.
% 
% Create a raspberrypi object by executing the following on the MATLAB
% command line:
%
%  r = raspberrypi
%
% The *raspberrypi* function returns a connection object, h, for Raspberry
% Pi hardware that has been set up using the targetupdater function. The
% hostname, user name, and password used to construct the raspberrypi
% object are the default MATLAB session values for these parameters.
% Simulink Support Package for Raspberry Pi Hardware saves one set of
% communication parameters, i.e. hostname, user name and password, for the
% Raspberry Pi hardware as default MATLAB session values. Note, the default
% MATLAB session values for the communication parameters are first
% determined during the firmware update process. The communication
% parameters may subsequently be changed using the *Tools > Run on Target
% Hardware > Options...* UI in a Simulink model and are sticky, meaning
% that once you change the communication parameter values they are saved as
% default MATLAB session values, and are used for all Simulink models.
%
% You may explicitly specify the hostname or IP address, user name,
% password when you create the raspberrypi object:
%
%  r = raspberrypi('<hostname or IP address>','<user name>','<password>');
%
% The command above shows how to specify hostname, user name, and password.
% You may want to use this form if you have multiple Raspberry Pi hardware
% in your network that you want to connect at the same time.
%
% *NOTE:* In case of a connection failure, a diagnostics error message is
% reported on the MATLAB command line. If the connection has failed, the
% most likely cause is incorrect IP address or hostname.


%% Execute system commands on your Raspberry Pi
%
% You can use the system method of the raspberrypi object to execute
% various Linux shell commands on the Raspberry Pi hardware from MATLAB.
% Try taking a directory listing.
%
%  system(r,'ls -al ~')
%
% This statement executes a directory list shell command and returns the
% resulting text output at the MATLAB command prompt. You can store the
% result in a MATLAB variable to perform further processing. Establish who
% is the owner of the .profile file under /home/pi.
%
%  output = system(r,'ls -al /home/pi');
%  ret = regexp(output, '\s+[\w-]+\s+\d\s+(\w+)\s+.+\.profile\s+', 'tokens');
%  ret{1}
%  
% You can also achieve the same result using a single shell command.
%
%  system(r,'stat --format="%U" /home/pi/.profile')
%  
% Blink the user LED using system commands.
%  
%  system(r,'echo "none" | sudo tee /sys/class/leds/led0/trigger');
%  system(r,'echo 0 | sudo tee /sys/class/leds/led0/brightness');
%  system(r,'echo 1 | sudo tee /sys/class/leds/led0/brightness');
%  
% The user LED is, by default, wired to trigger off of SD card activity.
% The LED is re-wired to not have a trigger, enabling setting the LED state
% manually. You can return the LED back to its original state.
%  
%  system(r,'echo "mmc0" | sudo tee /sys/class/leds/led0/trigger');
%  
% You cannot execute interactive system commands using the system() method. 
% To execute interactive commands on the Raspberry Pi hardware, you must
% open a terminal session. 
%  
%  openShell(r)
%  
% This command opens a PuTTY terminal that can execute interactive shell
% commands like 'top'.


%% Run/Stop a Simulink Model
% Simulink Support Package for Raspberry Pi Hardware generates a Linux
% executable for each Simulink model you run on the Raspberry Pi hardware.
% The generated executable has the same name as the Simulink model and is
% saved on the Raspberry Pi hardware. To run/stop a Simulink model, you can
% use the runModel and stopModel methods of the raspberrypi object.
%
% 1. To run a Simulink model you previously run on the Raspberry Pi
% hardware, execute the following command on the MATLAB command line:
%
%  runModel(r,'<model name>')
%
% where the string '<model name>' is the name of the Simulink model you
% want to run on the Raspberry Pi hardware. The runModel method launches
% the executable corresponding to the Simulink model you specified.
%
% 2. To stop a Simulink model running on the Raspberry Pi hardware, execute
% the following command on the MATLAB command line:
% 
%  stopModel(r,'<model name>')
%
% This command kills the Linux process with the name '<model name>.elf' on
% the Raspberry Pi hardware. Alternatively, you may execute the following
% command to stop the model:
%
%  system(r,'sudo killall <model name>.elf')


%% Manipulate files
% The raspberrypi object provides basic file manipulation capabilities. To
% transfer a file on Raspberry Pi hardware to your host computer you use
% the getFile() method.
%  
%  getFile(r,'/usr/share/pixmaps/debian-logo.png');
%  
% You can then read the PNG file in MATLAB:
%  
%  img = imread('debian-logo.png');
%  image(img);
%  
% The getFile() method takes an optional second argument that allows you to
% define the file destination. To transfer a file on your host computer to
% Raspberry Pi hardware, you use putFile() method.
%  
%  putFile(r,'debian-logo.png','/home/pi/debian-logo.png.copy');
%  
% Make sure that file is copied.
%  
%  system(r,'ls -l /home/pi/debian-logo.png.copy')
%  
% You can delete files on your Raspberry Pi hardware using the deleteFile()
% command. 
%  
%  deleteFile(r,'/home/pi/debian-logo.png.copy');
%  
% Make sure that file is deleted.
%  
%  system(r,'ls -l /home/pi/debian-logo.png.copy')
%  
% The preceding command should result in an error indicating that the file
% cannot be found.

%% Summary
% This example introduced the workflow for running Linux shell commands on
% your Raspberry Pi Hardware. Using the Raspberry Pi support package,
% you turned the user LED on and off, executed system commands and
% manipulated files on the Raspberry Pi hardware.

displayEndOfDemoMessage(mfilename) 