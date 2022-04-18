function autorotate(obj,img)
% AUTOROTATE

% Copyright 2016 - 2018 The MathWorks, Inc.
%% Read the value of accelerometer
accel = readAcceleration(obj);

%% Set the orientation for the image depending on the acceleration
%
% 0.75g is considered as the threshold for deciding the major axis.
%
% Read the accelerometer value and rotate the image.
%
% if the board is rotated to point upwards, then orientation=0
%
% if the board is rotated to point downwards, then orientation=180
%
% if the board is rotated in the right direction, then orientation=90
%
% if the board is rotated in the left direction, then orientation=270
%
orientation = 0;

if accel(1) > 0.75      %Check if force of gravity is along the +x axis
    orientation = 90;
elseif accel(1) < -0.75 %Check if force of gravity is along the -x axis
    orientation = 270;
elseif accel(2) > 0.75  %Check if force of gravity is along the +y axis
    orientation = 180;
elseif accel(2) < -0.75 %Check if force of gravity is along the -y axis
    orientation = 0;
end

%Display the image on the 8X8 LED matrix with the proper orientation
displayImage(obj,img,orientation);

end