function setupMailIp(ssh, scp)
%setupMailIp

%  Copyright 2013-2014 The MathWorks, Inc.

% Copy source file to rpi
raspiRoot = raspi.internal.getRaspiRoot();
scp.putFile(fullfile(raspiRoot, 'src', 'mailip'), '/home/pi/');

msg = ssh.execute('sudo mv /home/pi/mailip /etc/network/if-up.d/');
disp(msg);

msg = ssh.execute('sudo chown root:root /etc/network/if-up.d/mailip');
disp(msg);

% Do not make it the script executable. User needs to edit the file before
% it can work
msg = ssh.execute('sudo chmod ugo-x /etc/network/if-up.d/mailip');
disp(msg);