function success = setupMQTTPaho(ssh, ~)
%SETUPMQTTPAHO(ssh) Download MQTT Paho source code from git, build and
%install.

%  Copyright 2018 The MathWorks, Inc.

%check if the required source and include file directories are present
try
    execute(ssh,'sudo stat /usr/local/lib/libpaho-mqtt3as.so');
catch
    % if the above directories are not present, download the files
    % Pull from sources, build and install
    try
        execute(ssh,'cd /tmp ; git clone https://github.com/eclipse/paho.mqtt.c.git ; cd /tmp/paho.mqtt.c ; sudo make install');
    catch
        success = false;
        return
    end
end

%Check if all the required libs are available. If not, execute buildme
requiredLibs = {'libpaho-mqtt3as.so'};
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
        execute(ssh,'cd /tmp/paho.mqtt.c ; sudo make install');
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