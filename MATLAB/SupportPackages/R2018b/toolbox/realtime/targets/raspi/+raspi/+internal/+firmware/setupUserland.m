function success = setupUserland(ssh, ~)
%SETUPUSERLAND(ssh) Download userland source code from git, build and
%install.

%  Copyright 2013-2017 The MathWorks, Inc.

%check if the required source and include file directories are present
try
    execute(ssh,'sudo stat /opt/userland');
    execute(ssh,'sudo stat /opt/userland/host_applications/linux/libs/bcm_host/include');
    execute(ssh,'sudo stat /opt/userland/interface/vcos');
    execute(ssh,'sudo stat /opt/userland/interface/vcos/pthreads');
    execute(ssh,'sudo stat /opt/userland/interface/vmcs_host/linux');
    execute(ssh,'sudo stat /opt/userland/host_applications/linux/apps/raspicam');
catch
    % if the above directories are not present, download the files
    % Pull from sources, build and install
    try
        execute(ssh,'cd /opt; sudo git clone git://github.com/raspberrypi/userland.git');
        execute(ssh,'cd /opt/userland; sudo git pull origin');
    catch
        success = false;
        return
    end
end

%Check if all the required libs are available. If not, execute buildme
requiredLibs = {'libmmal.so','libmmal_core.so','libmmal_util.so',...
    'libmmal_vc_client.so','libvcos.so','libbcm_host.so'};
buildreq = 0;
for i=1:numel(requiredLibs)
    cmd = ['sudo ldconfig -p |grep ' requiredLibs{i}];
    stdout=execute(ssh,cmd);
    if isempty(stdout)
        buildreq = 1;
        break;
    end
end

if buildreq
    try
        execute(ssh,'cd /opt/userland; sudo ./buildme');
        execute(ssh,'sudo ldconfig');
        success = true;
    catch
        success = false;
    end
else
    success = true;
end

end
%[EOF]