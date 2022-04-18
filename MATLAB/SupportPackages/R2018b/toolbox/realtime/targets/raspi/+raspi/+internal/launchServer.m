function launchServer(addr,username,password)
%LAUNCHSERVER Utility function that launches the correct version of server
%if it is not already running. 

% Copyright 2018 The MathWorks, Inc.

hw = raspi.internal.hardware(addr,username,password);
ssh = hw.Ssh;

% Desktop attempts to install V4l2 package if not exist
raspi.internal.installV4l2(ssh);

serverDir = raspi.internal.getServerDir;
serverName = raspi.internal.getServerName;
port = raspi.internal.getServerPort;

if isServerRunning
    pid = strip(execute(ssh, ['pgrep ' serverName],false));
    loc = strip(execute(ssh, ['sudo readlink -f /proc/' pid '/exe'],false));
    if ~isequal(loc,[serverDir '/' serverName])
        execute(ssh,['sudo killall ' serverName],false);
    else
        % No need to relaunch the server.
        return;
    end
end
if ~isServerAvailable
    raspi.internal.updateServer(addr,username,password);
else
    startServerApp;
end
ts = tic;
while (toc(ts) < 5) && ~isServerRunning
    pause(0.1);
end
if ~isServerRunning
    error(message('raspi:utils:UnableToConnect',addr));
end
            
%% LOCAL FUNCTION 
% BEGIN %
    function ret = isServerRunning
        cmd = ['pgrep ' serverName];
        [~,~,status] = execute(ssh,cmd,false);
        ret = status == 0;
    end

    function ret = isServerAvailable
        cmd = ['stat ' serverDir '/' serverName];
        [~,~,status] = execute(ssh,cmd,false);
        ret = status == 0;
    end

    function startServerApp
        % Kill running server. Do not throw exception when executing
        % this command.
        serverExe = [serverDir '/' serverName];
        cmd = ['sudo ' serverExe ' ' num2str(port) ' &> /dev/null &'];
        execute(ssh,cmd);
    end
% END %
end

