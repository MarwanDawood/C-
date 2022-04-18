function setupSerialConsole(ssh, ~)
%setupSerialConsole

%  Copyright 2013-2014 The MathWorks, Inc.

% Make sure serial console is enabled
disp('Enabling serial console...');
msg = ssh.execute('sudo rpi-serial-console enable');
disp(msg);

end
%[EOF]