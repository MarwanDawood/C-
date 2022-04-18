function setupUserGroups(ssh, ~)
%setupUserGroups

%  Copyright 2013-2017 The MathWorks, Inc.
% Copy source file to rpi
ssh.execute('sudo adduser pi video');
ssh.execute('sudo adduser pi i2c');
end
%[EOF]
