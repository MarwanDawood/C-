%% Getting Started with MATLAB Support Package for Raspberry Pi Hardware
%
% This example shows you how to use the MATLAB(R) Support Package for
% Raspberry Pi(R) Hardware to perform basic operations on the hardware such
% as executing shell commands, turning an on-board LED on or off and
% manipulating files.
 
% Copyright 2013 The MathWorks, Inc.
 

%% Introduction
%
% The MATLAB Support Package for Raspberry Pi Hardware enables you to
% communicate with Raspberry Pi hardware remotely from a computer running
% MATLAB. The support package includes a MATLAB command line interface for
% accessing Raspberry Pi hardware's I/O peripherals and communication
% interfaces. Using this command line interface, you can collect data from
% sensors connected to Raspberry Pi hardware and actuate devices attached
% to Raspberry Pi hardware.
%
% In this example you learn how to create a *raspi* object to connect to 
% Raspberry Pi hardware from within MATLAB. You examine the properties
% and methods of this object to learn about the status of basic peripherals 
% such as digital I/O pins (also known as GPIO), SPI, I2C, and Serial.
% Using this object, you execute shell commands on your Raspberry Pi
% hardware and manipulate files on the Raspberry Pi hardware.


%% Prerequisites
%
% * If you are new to MATLAB, it is helpful to  
% read the Getting Started section of the <matlab:doc('MATLAB') MATLAB documentation>
% and running <matlab:web('http://www.mathworks.com/videos/getting-started-with-matlab-101684.html','-browser') Getting Started with MATLAB example>.
%
% * You must complete the firmware update for Raspberry Pi hardware to be
% able to use the MATLAB interface for Raspberry Pi hardware. MATLAB
% communicates with the Raspberry Pi hardware by connecting to a server
% running on Raspberry Pi. This server is built into the firmware shipped
% with the support package. If you did not use Support Package Installer to
% update the Raspberry Pi firmware, enter *targetupdater* in the MATLAB
% Command Window and follow the on-screen instructions.


%% Required hardware
% 
% To run this example you need the following hardware:
% 
% * Raspberry Pi hardware
% * A power supply with at least 1A output
 

%% Create a raspi object
%
% Create a *raspi* object.
%
%   rpi = raspi();
%
% The rpi is a handle to a raspi object. While creating the rpi object, the
% MATLAB connects to a server running on the Raspberry Pi hardware
% through TCP/IP. If you have any issues with creating a raspi object,
% see the troubleshooting guide to diagnose connection issues. 
% 
% The properties of the raspi object show information about your Raspberry
% Pi hardware and the status of some of the hardware peripherals available.
% Either the numeric IP address or the hostname of your Raspberry Pi
% hardware and the port used for TCP/IP communication are displayed in the
% DeviceAddress and Port properties. The raspi object detects the model and
% version number of your board and displays it in the BoardName property.
% The GPIO pin-outs and available peripherals change with the model and
% version of your Raspberry Pi hardware.
%
% The AvailableLEDs property of the raspi object lists user controllable
% LEDs. You can turn a user LED on or off using the writeLED method.
%
% AvailableDigitalPins, AvailableI2CBuses, and AvailableSPIChannels
% properties of the raspi object indicate the pins that you can use for
% digital I/O, I2C buses, and SPI channels that can be used to communicate
% with sensors and actuators supporting the I2C and SPI communication
% protocols. It is not an issue if nothing is listed for
% AvailableSPIChannels. The Raspbian Linux image shipped with MATLAB does
% not enable the SPI peripheral to provide you with more general purpose
% digital I/O pins. You can enable and disable I2C and SPI peripherals to
% suit your needs by loading and unloading Linux(R) kernel modules
% responsible for these peripherals.

%% Turn an LED on and off
% There is a user LED on Raspberry Pi hardware that you can turn on and
% off. Execute the following command at the MATLAB prompt to turn the LED
% off and then turn it on again.
%
%   led = rpi.AvailableLEDs{1};
%   writeLED(rpi, led, 0);
%   writeLED(rpi, led, 1);
%
% While executing the preceding commands, observe the 'ACT' (or 'OK') LED
% on the Raspberry Pi hardware and visually confirm the LED operation. If
% you are unsure where the user LED is located, execute the following
% command.
%
%   showLEDs(rpi);
%
% You can make the LED "blink: in a loop with a period of 1 second.
%
%   for i = 1:10
%       writeLED(rpi, led, 0);
%       pause(0.5);
%       writeLED(rpi, led, 1);
%       pause(0.5);
%   end

%% Execute system commands
% The raspi object has a number of methods that allow you to execute system
% commands on Raspberry Pi hardware from within MATLAB. You can accomplish
% quite a lot by executing system commands on your Raspberry Pi hardware.
% The system function is limited in MATLAB(R) Online(TM).
% 
% Try taking a directory listing.
%
%   system(rpi, 'ls -al /home/pi')
%
% This statement executes a Linux directory listing command and returns the
% resulting text output at the MATLAB command prompt. You can store the
% result in a MATLAB variable to perform further processing. Establish who
% is the owner of the .profile file under /home/pi.
%
%   output = system(rpi,'ls -al /home/pi');
%   ret = regexp(output, '\s+[\w-]+\s+\d\s+(\w+)\s+.+\.profile\s+', 'tokens');
%   ret{1}
%  
% You can also achieve the same result using a single shell command.
%
%   system(rpi, 'stat --format="%U" /home/pi/.profile')
%  
% Perform the LED exercise this time using system commands.
%  
%   system(rpi, 'echo "none" | sudo tee /sys/class/leds/led0/trigger');
%   system(rpi, 'echo 0 | sudo tee /sys/class/leds/led0/brightness');
%   system(rpi, 'echo 1 | sudo tee /sys/class/leds/led0/brightness');
%  
% These commands are equivalent to the writeLED method with arguments 0 and
% 1 for the LED state. The user LED is, by default, wired to trigger off of
% SD card activity. The LED is re-wired to not have a trigger, enabling
% setting the LED state manually. You can return the LED back to its
% original state.
%  
%   system(rpi, 'echo "mmc0" | sudo tee /sys/class/leds/led0/trigger');
%  
% You cannot execute interactive system commands using the system() method. 
% To execute interactive commands on the Raspberry Pi hardware, you must
% open a terminal session.
%  
%   openShell(rpi)
%  
% This command opens a PuTTY terminal. Log in with your user name and
% password. The default user name is 'pi' and the default password is
% 'raspberry'. After logging in, you can execute interactive shell commands
% like 'top'.
% 
% The openShell function is not supported in MATLAB Online. Access the 
% command shell remotely via SSH with PuTTY, as described in 
% <matlab:web('https://www.raspberrypi.org/documentation/remote-access/','-browser')
% Remote Access>. 


%% Manipulate files
% The raspi object provides the basic file manipulation capabilities. To
% transfer a file on Raspberry Pi hardware to your host computer you use
% the getFile() method.
%  
%   getFile(rpi,'/usr/share/pixmaps/debian-logo.png');
%  
% You can then read the PNG file in MATLAB:
%  
%   img = imread('debian-logo.png');
%   image(img);
%  
% The getFile() method takes an optional second argument that allows you to
% define the file destination. To transfer a file on your host computer to
% Raspberry Pi hardware, you use putFile() method. This method is not
% supported in MATLAB Online.
%  
%   putFile(rpi, 'debian-logo.png', '/home/pi/debian-logo.png.copy');
%  
% Make sure that file is copied.
%  
%   system(rpi, 'ls -l /home/pi/debian-logo.png.copy')
%  
% You can delete files on your Raspberry Pi hardware using the deleteFile()
% command. 
%  
%   deleteFile(rpi, '/home/pi/debian-logo.png.copy');
%  
% Make sure that file is deleted.
%  
%   system(rpi, 'ls -l /home/pi/debian-logo.png.copy')
%  
% The preceding command should result in an error indicating that the file
% cannot be found.

%% Summary
% This example introduced the workflow for using the MATLAB Support Package
% for Raspberry Pi Hardware. Using the Raspberry Pi support package,
% you turned the user LED on and off, executed system commands and
% manipulated files on Raspberry Pi hardware.
 
 
