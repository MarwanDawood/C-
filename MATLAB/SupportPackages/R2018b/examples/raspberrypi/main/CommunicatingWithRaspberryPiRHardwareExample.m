%% Communicating with Raspberry Pi(R) Hardware
%
% This example shows you how to send data using the UDP Ethernet protocol from
% a Simulink(R) model running on Raspberry Pi(R) hardware to another model
% running on the host computer
 
% Copyright 2012-2014 The MathWorks, Inc.

%% Introduction
%
% In this example you will learn how to create and run a simple Simulink model
% on Raspberry Pi hardware that sends data to the host computer using 
% <matlab:web('http://en.wikipedia.org/wiki/User_Datagram_Protocol','-browser') User Datagram Protocol (UDP)>.
% A companion model running on the host computer will receive UDP data
% packets coming from Raspberry Pi hardware.

%% Prerequisites
%
% * We recommend completing
% <raspberrypi_gettingstarted.html Getting Started with Raspberry Pi(R) Hardware> example. 


%% Required Hardware
% 
% To run this example you will need the following hardware:
% 
% * Raspberry Pi hardware

%% Target Hardware Model
open_system('raspberrypi_communication');


%% Host Model
open_system('raspberrypi_host_communication');
 

%% Task 1 - Review Raspberry Pi Block Library
%
% Simulink Support Package for Raspberry Pi Hardware provides I/O
% peripheral blocks for Raspberry Pi hardware for easy integration with
% algorithms designed in Simulink.
%
% *1.* Enter <matlab:simulink simulink> at the MATLAB(R) prompt to open
% the Simulink Library Browser.
%
% *2.* In the Simulink Library Browser, navigate to *Simulink Support
% Package for Raspberry Pi Hardware*.
%
% *3.* Double-click the *UDP Send* or *UDP Receive* blocks. This opens the
% block mask, which contains a description of the block and parameters for
% configuring for UDP-based communications.

open_system('raspberrypilib');


%% Task 2 - Run UDP Communication Model on Raspberry Pi Hardware
%
% In this task, you will configure and run a simple model that sends UDP
% packets to the host computer.
%
% *1.* Open the <matlab:raspberrypi_communication |target hardware model|>. 
%
% *2.* Double-click on the *UDP Send* block. Open the block mask and enter
% the <matlab:realtime.internal.displayHostIPAddress |IP address of your host computer|>
% in the *Remote IP address* edit box. For example, if the IP address of
% your host computer is 10.10.10.1, enter '10.10.10.1' in the block mask. Do not
% change the *Remote IP port* parameter. Click OK to save and close the
% block mask.
%
% *3.* In your Simulink model, click the *Deploy To Hardware* button on 
% the toolbar.
%
% *4.* The model running on Raspberry Pi hardware will start sending UDP
% packets to port 25000 of your host computer.
 

%% Task 3 - Run UDP Communication Model on the Host Computer
%
% In this task, you will run the host model that receives the UDP packets
% sent by the model running on Raspberry Pi hardware.
%
% *1.* Open the <matlab:raspberrypi_host_communication |host model|>. This model has a
% UDP Receive block that is configured to receive UDP packets sent by the
% model running on Raspberry Pi hardware. Double-click on the *UDP Receive*
% block mask. Note that the Local IP port is set to 25000, and the output
% data type is set to "double".
%
% *2.* Click the Play button to start simulation. 
%
% *3.* Double-click on the *Scope* block to see the sine wave sent by the
% model that is running on Raspberry Pi hardware. The *Display* block
% in the model shows the number of UDP packets received from the
% Raspberry Pi hardware since the start of simulation of the host model.


%% Task 4 - Stop the Model Running on Raspberry Pi Hardware
%
% *1.* On MATLAB command line, execute the following
%
%  r = raspberrypi;
%  stopModel(r,'raspberrypi_communication');


%% Other Things to Try:
% 
% * Modify the <matlab:raspberrypi_host_communication |host model|> so that the *Scope*
% block displays data only when Size port of the *UDP Receive* block
% outputs a positive number.


%% Summary
% 
% This example showed how to send data from a model running on Raspberry Pi
% hardware to the host computer using UDP protocol, and also described how
% the data may be received by another model running on the host computer.


close_system('raspberrypilib', 0);
close_system('raspberrypi_host_communication', 0); 
close_system('raspberrypi_communication', 0); 
 