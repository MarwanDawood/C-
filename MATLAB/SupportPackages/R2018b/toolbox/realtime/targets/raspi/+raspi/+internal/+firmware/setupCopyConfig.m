function setupCopyConfig(ssh, scp)
%setupCopyConfig

%  Copyright 2013-2014 The MathWorks, Inc.

% Copy source file to rpi
raspiRoot = raspi.internal.getRaspiRoot();
scp.putFile(fullfile(raspiRoot, 'src', 'copy-config'), '/home/pi/');

msg = ssh.execute('sudo mv /home/pi/copy-config /etc/network/if-pre-up.d/');
disp(msg);

msg = ssh.execute('sudo chown root:root /etc/network/if-pre-up.d/copy-config');
disp(msg);

msg = ssh.execute('sudo chmod ugo+x /etc/network/if-pre-up.d/copy-config');
disp(msg);
