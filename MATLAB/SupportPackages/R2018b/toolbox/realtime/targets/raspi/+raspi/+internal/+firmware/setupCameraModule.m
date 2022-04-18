function setupCameraModule(ssh, ~)
%setupCameraModule

%  Copyright 2016 The MathWorks, Inc.

warning('This does not remove black-listed items from /etc/modprobe.d/raspi-blacklist.conf');

% Copy source file to rpi
disp('1. grep ''bcm2835-v4l2'' in /etc/modules');
cmd = 'grep ''bcm2835-v4l2'' /etc/modules';
try
    execute(ssh,cmd);
catch ME %#ok<NASGU>
    disp('Cannot find V4L2 module for camera board.. Setting up..');
    cmd = 'echo -e "\\nbcm2835-v4l2\\ni2c-dev" | sudo tee -a /etc/modules';
    msg = execute(ssh,cmd);
    disp(msg);
    disp('V4L2 camera module will be loaded upon reboot..');
end