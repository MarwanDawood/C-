function setupI2C(ssh, ~)
%setupI2C

%  Copyright 2013-2014 The MathWorks, Inc.

warning('This does not remove black-listed items from /etc/modprobe.d/raspi-blacklist.conf');

% Copy source file to rpi
disp('1. grep ''i2c-bcm2708'' in /etc/modules');
cmd = 'grep ''i2c-bcm2708'' /etc/modules';
try
    ssh.execute(cmd);
catch ME %#ok<NASGU>
    disp('Cannot find I2C modules.. Setting up..');
    cmd = 'echo -e "\\ni2c-bcm2708\\ni2c-dev" | sudo tee -a /etc/modules';
    msg = ssh.execute(cmd);
    disp(msg);
    disp('I2C modules will be loaded upon reboot..');
end