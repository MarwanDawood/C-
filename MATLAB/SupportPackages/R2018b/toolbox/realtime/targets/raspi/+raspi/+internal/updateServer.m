function updateServer(deviceAddress, username, password, startServer)
% RASPI.UPDATESERVER updates the MATLAB communication server running on
% your Raspberry Pi to the latest version compatible with the raspi
% interface.
%
% RASPI.UPDATESERVER(deviceAddress, username, password) updates MATLAB
% communication server running on the Raspberry Pi with given
% deviceAddress, username, and password.

%  Copyright 2013-2019 The MathWorks, Inc.

narginchk(0,4);
if nargin < 4
    startServer = true;
else
    validateattributes(startServer,{'double'},{'binary','scalar'},...
        'raspi.updateServer','startServer');
end

% Register the error message catalog location
matlab.internal.msgcat.setAdditionalResourceLocation(raspi.internal.getRaspiBaseRoot);

hb = raspi.internal.BoardParameters('Raspberry Pi');
if nargin < 1
    deviceAddress = hb.getParam('hostname');
    if isempty(deviceAddress)
        error(message('raspi:utils:InvalidDeviceAddress'));
    end
end
if nargin < 2
    username = hb.getParam('username');
    if isempty(username)
        error(message('raspi:utils:InvalidUsername'));
    end
end
if nargin < 3
    password = hb.getParam('password');
    if isempty(password)
        error(message('raspi:utils:InvalidPassword'));
    end
end

% Open an SSH session to the board
fprintf('### Updating Raspberry Pi I/O server...\n');
fprintf('### Connecting to board...\n');
hw = raspi.internal.hardware(deviceAddress,username,password);
fprintf('### Connected to %s...\n',deviceAddress);

% Initialize
serverDir = raspi.internal.getServerDir;
serverName = raspi.internal.getServerName;
port = raspi.internal.getServerPort;

% Make sure that userland is installed
if ~isUserlandInstalled(hw)
    if hasInternetConnection(hw)
        fprintf('### Installing userland software (this might take a while)...\n');
        raspi.internal.firmware.setupUserland(hw.Ssh);
    else
        error('raspi:utils:UserlandNotInstalled',...
            ['userland software package (https://github.com/raspberrypi/userland) is not found in /opt/userland/ directory on the Raspberry Pi board. ', ...
            'Raspberry Pi I/O server requires userland GIT reporitory be installed in /opt/userland folder. ',...
            'Follow the instructions below to install userland:\n\n',...
            '1. Make sure that your Raspberry Pi board is connected to Internet\n', ...
            '2. Login to your Raspberry Pi and execute the following commands on a terminal:\n\n',...
            ' $ sudo rm -fr /opt/userland \n',...
            ' $ cd /opt; sudo git clone git://github.com/raspberrypi/userland.git\n',...
            ' $ cd /opt/userland; sudo git pull origin\n',...
            ' $ cd /opt/userland; sudo ./buildme\n',...
            ' $ sudo ldconfig\n']);
    end
end

% Make sure that userland is of latest version
if ~isUserlandupdated(hw)
    if hasInternetConnection(hw)
        fprintf('### Updating userland software (this might take a while)...\n');
        raspi.internal.firmware.updateUserland(hw.Ssh);
    else
        error('raspi:utils:UserlandNotInstalled',...
            ['userland software package (https://github.com/raspberrypi/userland) found in /opt/userland/ directory on the Raspberry Pi board is not the latest version. ', ...
            'Raspberry Pi I/O server requires the latest userland GIT reporitory be installed in /opt/userland folder. ',...
            'Follow the instructions below to install userland:\n\n',...
            '1. Make sure that your Raspberry Pi board is connected to Internet\n', ...
            '2. Login to your Raspberry Pi and execute the following commands on a terminal:\n\n',...
            ' $ sudo rm -fr /opt/userland \n',...
            ' $ cd /opt; sudo git clone git://github.com/raspberrypi/userland.git\n',...
            ' $ cd /opt/userland; sudo git pull origin\n',...
            ' $ cd /opt/userland; sudo ./buildme\n',...
            ' $ sudo ldconfig\n']);
    end
end


if ~isNanomsgInstalled(hw)
    
    if hasInternetConnection(hw)
        fprintf('### Installing nanomsg Library (this might take a while)...\n');
        raspi.internal.firmware.setupNanomsg(hw.Ssh);
    else
        error('raspi:utils:Nanomsg',...
            ['Nanomsg library software package (https://github.com/nanomsg/nanomsg/archive/1.0.0.zip) is not found on the Raspberry Pi board. ', ...
            'Raspberry Pi I/O server requires nanomsg GIT reporitory be installed in /tmp/nanomsg-1.0.0  folder. ',...
            'Follow the instructions below to install nanomsg:\n\n',...
            '1. Make sure that your Raspberry Pi board is connected to Internet\n', ...
            '2. Login to your Raspberry Pi and execute the following commands on a terminal:\n\n',...
            ' $ sudo rm -fr /tmp/nanomsg-1.0.0 \n',...
            ' $ wget https://github.com/nanomsg/nanomsg/archive/1.0.0.zip  \n',...
            ' $ sudo unzip 1.0.0.zip -d /tmp \n ',...
            ' $ cd /tmp/nanomsg-1.0.0 ; mkdir build ; \n',...
            ' $ cmake ..  ;  \n',...
            ' $ cmake --build .   \n',...
            ' $ sudo cmake --build . --target install  \n',...
            ' $ sudo ldconfig\n']);
    end
    
end

% Check if we have the MATLAB/server folder
fprintf('### Creating server folder...\n');
execute(hw.Ssh,['sudo rm -fr ' serverDir],false);
system(hw,['sudo mkdir -p ' serverDir]);
system(hw,['sudo chown ' username ' ' serverDir]);

% Transfer server files to remote target
fprintf('### Transferring source files...\n');
rootDir = fullfile(raspi.internal.getRaspiRoot, 'server');
putFile(hw,fullfile(rootDir,'*.c'), [serverDir '/.']);
putFile(hw,fullfile(rootDir,'*.h'), [serverDir '/.']);
putFile(hw,fullfile(rootDir,'Makefile'), [serverDir '/.']);
putFile(hw,fullfile(rootDir,'Makefile_udpip'), [serverDir '/.']);

% Build server
fprintf('### Building MATLAB I/O server...\n');
system(hw,['make -C ' serverDir ' -f Makefile']);
system(hw,['make -C ' serverDir ' -f Makefile_udpip']);
system(hw,['sudo chown root ' serverDir]);

% Kill running server
execute(hw.Ssh,['sudo killall ' serverName],false);
execute(hw.Ssh,'sudo killall udp_ip',false);

% Restart server
if startServer
    fprintf('### Launching MATLAB I/O server...\n');
    system(hw,['sudo ' serverDir '/' serverName ' ' num2str(port) ' &> /dev/null &']);
    system(hw,[serverDir '/udp_ip /boot/iflist.txt &> /dev/null &']);
end

% Update MATLAB I/O server daemon
txt = [...
    '#!/bin/bash\n',...
    '\n',...
    'SERVER_DIR=%s\n',...
    'SERVER_EXE=%s\n',...
    'SERVER_PORT=%d\n',...
    'PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin\n',...
    '\n',...
    'if [ \"$METHOD\" = loopback ]; then\n',...
    '    exit 0\n',...
    'fi\n',...
    '\n',...
    '# Start UDP IP server\n',...
    'if pgrep udp_ip\n',...
    'then\n',...
    '  echo UDP server is already running\n',...
    'else\n',...
    '  $SERVER_DIR/udp_ip /boot/iflist.txt &>/dev/null &\n',...
    'fi\n',...
    '\n',...
    'exit 0\n'];
fileName = tempname;
fid = fopen(fileName,'w');
if fid < 0
    error('raspi:utils:UpdateServer','Error while creating a temporary file trying to update the server');
end
fprintf(fid,txt,serverDir,serverName,port);
fclose(fid);

% Transfer the new udp_daemon start-up script to Raspberry Pi
putFile(hw,fileName,'~/udp_daemon');
system(hw,'sudo mv udp_daemon /etc/network/if-up.d/udp_daemon');
system(hw,'sudo chmod uog+x /etc/network/if-up.d/udp_daemon');
end

%% Internal functions
function ret = isUserlandInstalled(hw)
[~,~,status] = execute(hw.Ssh,'stat /opt/userland/host_applications/linux/libs/bcm_host/include',false);
ret = status == 0;
end

function ret = isUserlandupdated(hw)
[~,~,status] = execute(hw.Ssh,'stat /opt/userland/host_applications/linux/apps/raspicam/RaspiHelpers.c',false);
ret = status == 0;
end

%% Internal functions
function ret = isNanomsgInstalled(hw)
[~,~,status] = execute(hw.Ssh,'sudo stat /usr/local/lib/libnanomsg.so.5.0.0 ',false);
ret = status == 0;
end

function ret = hasInternetConnection(hw)
% Tests if board has Internet connection
try
    cmd = 'ping -W 1 -c 1 8.8.8.8';
    output = system(hw,cmd);
    if ~isempty(regexpi(output, '\sTTL='))
        ret = true;
    else
        ret = false;
    end
catch
    ret = false;
end
end
%[EOF]

% LocalWords:  RASPI raspi utils userland github raspberrypi reporitory sudo
% LocalWords:  buildme ldconfig nanomsg tmp wget cmake chown udpip killall ip
% LocalWords:  dev iflist sbin usr pgrep uog linux bcm raspicam libnanomsg TTL
