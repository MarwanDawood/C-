%% Build a Motion Sensor Camera
%
% This example shows you how to build a motion sensor camera using
% MATLAB(R) Support Package for Raspberry Pi(R) Hardware.
 
% Copyright 2013 The MathWorks, Inc.
 

%% Introduction
%
% In this example you combine a passive infrared (PIR) sensor with a
% Raspberry Pi Camera Board to build a motion sensor camera. A PIR sensor
% measures infrared light radiating from objects. The sensor detects the
% change in the infrared radiation and triggers an alarm if the gradient of
% the change is higher than a predefined value. You connect the PIR sensor
% to one of the digital input pins of the Raspberry Pi hardware and monitor
% the output of the PIR sensor. When PIR sensor detects motion it outputs a
% logic high value. When you detect a logic high value on the digital input
% pin, you take a picture and save it on the host computer.


%% Prerequisites
%
% It is helpful to complete the following examples
% 
% * <raspi_gettingstarted.html Getting Started with MATLAB Support Package for Raspberry Pi Hardware> example.
% 
% * <raspi_gettingstarted_with_hardware.html Getting Started with Raspberry Pi Hardware> example.
%
% * <raspi_working_with_camera_board.html Working with Raspberry Pi Camera Board> example.


%% Required Hardware
% 
% To run this example you need the following hardware:
% 
% * Raspberry Pi hardware
% * A power supply with at least 1A output
% * Breadboard and jumper cables
% * A Raspberry Pi Camera Board
% * A PIR sensor 


%% Connect PIR Motion Sensors
% 
% A PIR sensor has three pins: VCC, GND, and OUT. You connect the VCC pin
% to +3.3 Volt voltage rail and the GND pin to the ground. The OUT pin is
% the logic signal indicating motion. This pin will be connected to a GPIO
% pin on the Raspberry Pi hardware as shown in the following circuit
% diagram.
% 
% <<motion_sensor_connection_diagram.png>>
%
% If you do not have a motion sensor available, you can substitute a push
% button instead. See <raspi_gettingstarted_with_hardware.html Getting Started with Raspberry Pi Hardware> example for details. 


%% Test Motion Sensor
% 
%  When motion sensor detects movement, an LED on the sensor board turns
%  on. Move your hand in front of the PIR motion sensor and make sure the
%  sensor responds by turning on an LED. Then, execute the following at the
%  MATLAB prompt.
%
%   clear rpi
%   rpi = raspi();
%   motionDetected = readDigitalPin(rpi, 23);
%   disp(motionDetected);
%
% The displayed value of the variable *motionDetected* should be one. The
% PIR motion detector holds the value of the OUT pin at logic high for
% approximately 5 seconds. Wait until the PIR sensor LED goes off and
% execute the preceding MATLAB code again. This time, you should observe a
% value of zero for the displayed value of *motionDetected*.


%% Test Camera Board
%
% Create a camera board object by executing the following command on the
% MATLAB prompt.
%
%   cam = cameraboard(rpi);
%
% The cam is a handle to a cameraboard object. Display an image captured
% from Camera Board in MATLAB.
% 
%   img = snapshot(cam);
%   imagesc(img);
%


%% Motion Sensor Camera
% Run the motion sensor camera code by executing the following MATLAB
% commands.
% 
%   N = 100;
%   delay = 0.1;
%   frameNo = 0;
%   for i = 1:N
%       motionDetected = readDigitalPin(rpi, 23);
%       if motionDetected
%          fprintf('Motion detected on %s\n', datestr(now)); 
%          for i = 1:3
%              % Clear image buffer
%              snapshot(cam);
%          end
%          img = snapshot(cam);
%          image(img);
%          drawnow;
%          imwrite(img, sprintf('image%d.jpg', frameNo));
%          % Wait until the motion detector output goes low
%          pause(5);
%       end
%       pause(delay);
%   end


%% Summary
%
% This example showed how to use a PIR motion sensor and a Raspberry Pi
% Camera Board to build a motion sensor camera.

displayEndOfDemoMessage(mfilename) 
 