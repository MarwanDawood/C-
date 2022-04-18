%% LED Control from Apple iOS Device
%
% This example shows you how to control Raspberry Pi(R) LED from iPhone or
% iPad.
%

% Copyright 2016-2017 The MathWorks, Inc.


%% Introduction
%
% iPhone and iPad provide wireless access and graphical user
% interface. You can create compelling projects by using an iPhone/iPad
% as a front end to control hardware and peripherals attached to a
% Raspberry Pi board wirelessly. In this example, you will configure and
% run two Simulink models onto Raspberry Pi hardware and iPhone/iPad
% respectively. You will be able to control the LED on/off on Raspberry Pi
% board from iPhone/iPad.
%
% You will learn how to:
%
% * Set up network connection between Raspberry Pi hardware and iPhone/iPad
% * Configure and run a Simulink model for Raspberry Pi hardware to receive
% UDP packets from iPhone/iPad
% * Configure and run a Simulink model for iPhone/iPad to send UDP
% packets to Raspberry Pi hardware

open_system('raspberrypiiosgettingstarted');


%% Prerequisites
%
% * We recommend completing <docid:raspberrypi_ref.example-raspberrypi_gettingstarted Getting
% Started with Raspberry Pi Hardware> example.


%% Required Hardware
%
% To run this example you need the following hardware:
% 
% * Raspberry Pi board
% * iPhone/iPad

%% Task 1 - Install Simulink Support Package for Apple iOS Devices 
%
% You need *Simulink Support Package for Apple iOS Devices* to run Simulink
% model on iPhone/iPad.
%
% *1.* Install *Simulink Support Package for Apple iOS Devices*.
% 
% Click link below to 
%
% <matlab:hwconnectinstaller.launchInstaller('BaseCode','SL_IOS','StartAtStep','SelectPackage') Download and Install Simulink Support Package for Apple iOS Devices>
%
% *2.* (Recommended) Complete the *<https://www.mathworks.com/help/supportpkg/appleios/examples/getting-started-with-apple-ios-devices.html Getting
% Started with Apple iOS Devices>* example in *Simulink Support Package for
% Apple iOS Devices* you just installed.
%

%% Task 2 - Configure Network Connection 
% 
% In this task, you will set up network connection between Raspberry Pi
% board and iPhone/iPad. The communication protocol used in this example
% is UDP.
%  
% *1.* Connect Raspberry Pi board to the network with Ethernet cable
% through Ethernet port.
%
% *2.* Connect iPhone/iPad to the same network through Wi-Fi. Check
% *Settings* -> *Wi-Fi* -> *[Wi-Fi network connected]* to find the IP
% address of your iPhone/iPad.
%
% *3.* Verify the connection between your Raspberry Pi board and iPhone/iPad.
% 
% Execute the following command on the MATLAB command prompt:
%
%   r = raspberrypi
% 
% This command returns an object with IP address info for the Raspberry Pi
% board.
% 
% Run command *system(r, 'sudo ping [iOS_IP_Address] -c 10')* with the
% iPhone/iPad IP address found in step 2 to verify the connection. e.g.
%
%   system(r, 'sudo ping 172.31.205.40 -c 10')
%

%% Task 3 - Run Simulink Models on Raspberry Pi Board and Apple iOS Devices
%
% *1.* Open preconfigured <matlab:open_system('raspberrypiiosgettingstarted.slx')
% Raspberry Pi Model> and configure it with the IP address of your
% Raspberry Pi board. Build and run this model on Raspberry Pi board by
% clicking on the *Deploy to Hardware* button.
%
% *2.* Open preconfigured <matlab:open_system('iosraspberrypigettingstarted.slx') Apple iOS
% Model>. Double-click on the *UDP Receive* block. Open the block mask and
% enter the IP address of your Raspberry Pi board in the *Remote IP
% address* edit box. Click *OK* to save and close the block mask. Build and
% run this model on your iPhone/iPad by clicking on the *Deploy to
% Hardware* button. An iOS app will run on your iPhone/iPad.
%
% *3.* Once the iOS App runs, press the switch button in the iOS
% app and observe the LED on/off.
%
% *Note*: If you are having trouble using UDP to communicate with your computer, antivirus or firewall software might be blocking UDP traffic. If so, configure the software to allow the traffic for the port number specified in the *UDP Receive* block. 

%% Summary
%
% This example showed you how to create Simulink models that allow
% communication between a Raspberry Pi hardware board and iPhone/iPad using
% UDP protocol.

close_system('raspberrypiiosgettingstarted',0); 
