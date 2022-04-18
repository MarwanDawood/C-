function setupLinuxOsRights(ssh, scp)
%setupLinuxOsRights

%  Copyright 2013-2014 The MathWorks, Inc.

% Copy source file to rpi
raspiRoot = raspi.internal.getRaspiRoot();
scp.putFile(fullfile(raspiRoot, 'resources', 'Linux_OS_rights.txt'), '/home/pi/');

% Move to /
msg = ssh.execute('sudo mv /home/pi/Linux_OS_rights.txt /Linux_OS_rights.txt');
disp(msg);

% Change ownership to root
msg = ssh.execute('sudo chown root:root /Linux_OS_rights.txt');
disp(msg);

% Make it read only
msg = ssh.execute('sudo chmod ugo-w /Linux_OS_rights.txt');
disp(msg);