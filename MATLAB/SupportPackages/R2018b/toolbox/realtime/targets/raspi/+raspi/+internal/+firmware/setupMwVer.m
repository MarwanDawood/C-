function setupMwVer(ssh, scp)
%setupMwVer

%  Copyright 2013-2014 The MathWorks, Inc.

% Connect to ipAddress
raspiRoot = raspi.internal.getRaspiRoot();

disp('.0 Copy mwver.c to /home/pi');
scp.putFile(fullfile(raspiRoot, 'src', 'mwver.c'), '/home/pi/mwver.c');

% Compile versioning file
disp('.1 Compile mwver.c');
cmd = 'gcc -Wall -DMW_STACK_VER="\"2.0\"" /home/pi/mwver.c -o /home/pi/mwver';
msg = ssh.execute(cmd);
disp(msg);

% Move versioning file to bin
disp('.2 move /home/pi/mwver to /usr/sbin');
cmd = 'sudo mv /home/pi/mwver /usr/sbin/mwver';
msg = ssh.execute(cmd);
disp(msg);

% Delete versioning source file
disp('.3 Delete /home/pi/mwver.c');
cmd = 'rm /home/pi/mwver.c';
msg = ssh.execute(cmd);
disp(msg);

% Rehash search path cache
disp('.4 Rehash bash cache');
cmd = 'hash -r';
msg = ssh.execute(cmd);
disp(msg);
