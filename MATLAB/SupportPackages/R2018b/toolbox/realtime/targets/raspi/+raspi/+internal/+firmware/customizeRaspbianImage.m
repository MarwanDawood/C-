function customizeRaspbianImage(ipAddress, username, password)
%CUSTOMIZERASBIANIMAGE Customizes Raspbian image to be compatible with
%MATLAB / Simulink support package for Raspberry Pi.

%  Copyright 2013-2014 The MathWorks, Inc.

% Push files to raspberry pi
if nargin < 2
    username = 'pi';
end
if nargin < 3
    password = 'raspberry';
end

% Open an SSH session to the board
ssh = matlabshared.internal.ssh2client(ipAddress,username,password);
scp = matlabshared.internal.scpclient(ipAddress,username,password);
puttyRootDir = fullfile(raspi.internal.getRaspiRoot,'resources','putty');
setPuttyRootDir(scp,puttyRootDir);

% Perform required customizations
raspi.internal.firmware.setupLinuxOsRights(ssh,scp);
raspi.internal.firmware.setupLinuxPackages(ssh,scp);
raspi.internal.firmware.setupMwVer(ssh,scp);
raspi.internal.firmware.setupSshDns(ssh,scp);
raspi.internal.firmware.setupI2C(ssh,scp);
raspi.internal.firmware.setupCopyConfig(ssh,scp);
raspi.internal.firmware.setupMailIp(ssh,scp);
raspi.internal.firmware.setupRcLocal(ssh,scp);
raspi.internal.firmware.setupSerialConsole(ssh,scp);
raspi.internal.firmware.setupUserGroups(ssh,scp);
raspi.internal.firmware.setupWiringPi(ssh,scp);
raspi.internal.firmware.setupUserland(ssh,scp);
raspi.internal.firmware.setupCameraModule(ssh,scp);
raspi.internal.firmware.setupPigpio(ssh,scp);
raspi.internal.firmware.setupNanomsg(ssh,scp);
end