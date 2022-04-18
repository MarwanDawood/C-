function success = updateUserland(ssh,~)
%UPDATEUSERLAND(ssh) Updates userland source code from git, build and
%install.

% Copyright 2019 The MathWorks, Inc.

%check if the userland is of latest version( the latest version has
%RaspiHelpers.c and RaspiCommonSettings.c

try
    execute(ssh,' sudo stat /opt/userland/host_applications/linux/apps/raspicam/RaspiHelpers.c');
    execute(ssh,' sudo stat /opt/userland/host_applications/linux/apps/raspicam/RaspiCommonSettings.c');
    success = true;
    return    
catch
    try
        execute(ssh, 'sudo rm -rf /opt/userland');
        execute(ssh,'cd /opt; sudo git clone git://github.com/raspberrypi/userland.git');
        execute(ssh,'cd /opt/userland; sudo git pull origin');
    catch
        success = false;
        return
    end
end

%rebuild all the libraries
try
    execute(ssh,'cd /opt/userland; sudo ./buildme');
    execute(ssh,'sudo ldconfig');
    success = true;
catch
    success = false;
end
end

%[EOF]

% LocalWords:  userland Raspi sudo linux raspicam github raspberrypi buildme
% LocalWords:  ldconfig
