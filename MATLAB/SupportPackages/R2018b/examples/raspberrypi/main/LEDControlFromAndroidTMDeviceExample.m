%% LED Control from Android(TM) Device
%
% This example shows you how to control Raspberry Pi(R) LED from an Android
% device.
%

% Copyright 2016-2017 The MathWorks, Inc.

%% Introduction
%
% Android phones and tablets provide wireless access and graphical user
% interface. You can create compelling projects by using an Android device
% as a front end to control hardware and peripherals attached to a
% Raspberry Pi board wirelessly. In this example, you will configure and
% run two Simulink models onto Raspberry Pi hardware and Android device
% respectively. You will be able to control the LED on/off on Raspberry Pi
% board from Android device.
%
% You will learn how to:
%
% * Set up network connection between Raspberry Pi hardware and Android
% device
% * Configure and run a Simulink model for Raspberry Pi hardware to receive
% UDP packets from Android device
% * Configure and run a Simulink model for Android device to send UDP
% packets to Raspberry Pi hardware

open_system('raspberrypiandroidgettingstarted');

%% Prerequisites
%
% * We recommend completing <docid:raspberrypi_ref.example-raspberrypi_gettingstarted Getting
% Started with Raspberry Pi Hardware> example.


%% Required Hardware
%
% To run this example you need the following hardware:
% 
% * Raspberry Pi board
% * Android phone or tablet

%% Task 1 - Install Simulink Support Package for Android Devices 
%
% You need *Simulink Support Package for Android Devices* to run Simulink
% model on Android devices.
%
% *1.* Install *Simulink Support Package for Android Devices*.
% 
% Click link below to 
%
% <matlab:hwconnectinstaller.launchInstaller('BaseCode','ANDROID','StartAtStep','SelectPackage') Download and Install Simulink Support Package for Android Devices>
%
% *2.* (Recommended) Complete the *<https://www.mathworks.com/help/supportpkg/android/examples/getting-started-with-android-devices.html Getting
% Started with Android Devices>* example in *Simulink Support Package for
% Android Devices* you just installed.
%

%% Task 2 - Configure Network Connection 
% 
% In this task, you will set up network connection between Raspberry Pi
% board and Android device. The communication protocol used in this example
% is UDP.
%  
% *1.* Connect Raspberry Pi board to the network with Ethernet cable
% through Ethernet port.
%
% *2.* Connect Android device to the same network through Wi-Fi. Check
% *Settings* -> *Wi-Fi* -> *[Wi-Fi network connected]* to find the IP
% address of your Android device.
%
% *3.* Verify the connection between your Raspberry Pi board and Android device.
% 
% Execute the following command on the MATLAB command prompt:
%
%   r = raspberrypi
% 
% This command returns an object with IP address info for the Raspberry Pi
% board.
% 
% Run command *system(r, 'sudo ping [Android_IP_Address] -c 10')* with the
% Android device IP address found in step 2 to verify the connection. e.g.
%
%   system(r, 'sudo ping 172.31.205.40 -c 10')
%

%% Task 3 - Run Simulink Models on Raspberry Pi Board and Android Device 
%
% *1.* Open preconfigured <matlab:open_system('raspberrypiandroidgettingstarted.slx')
% Raspberry Pi Model> and configure it with the IP address of your
% Raspberry Pi board. Build and run this model on Raspberry Pi board by
% clicking on the *Deploy to Hardware* button.
%
% *2.* Open preconfigured <matlab:open_system('androidraspberrypigettingstarted.slx') Android
% Model>. Double-click on the *UDP Send* block. Open the block mask and
% enter the IP address of your Raspberry Pi board in the *Remote IP
% address* edit box. Click *OK* to save and close the block mask. Build and
% run this model on your Android device by clicking on the *Deploy to
% Hardware* button. An Android app will run on your Android device.
%
%
% *3.* Once the Android app runs, press the switch button in the Android
% app and observe the LED on/off.
%

%% Summary
%
% This example showed you how to create Simulink models that allow
% communication between a Raspberry Pi hardware board and Android device using
% UDP protocol.

close_system('raspberrypiandroidgettingstarted',0); 
 
