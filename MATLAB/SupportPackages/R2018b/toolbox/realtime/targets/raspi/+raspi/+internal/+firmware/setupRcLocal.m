function setupRcLocal(ssh, scp)
%setupRcLocal

%  Copyright 2013-2014 The MathWorks, Inc.

% Copy source file to rpi
raspiRoot = raspi.internal.getRaspiRoot();
scp.putFile(fullfile(raspiRoot, 'src', 'rc.local'), '/home/pi/');

% Save original rc.local
msg = ssh.execute('sudo mv /etc/rc.local /etc/rc.local.original');
disp(msg);

% Copy over new rc.local
msg = ssh.execute('sudo mv /home/pi/rc.local /etc/rc.local');
disp(msg);
msg = ssh.execute('sudo chown root:root /etc/rc.local');
disp(msg);
msg = ssh.execute('sudo chmod ugo+x /etc/rc.local');
disp(msg);