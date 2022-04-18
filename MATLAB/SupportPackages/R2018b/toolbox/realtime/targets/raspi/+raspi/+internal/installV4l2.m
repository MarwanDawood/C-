function installV4l2(ssh)
% Install V4l2 package if the hardware does not already have it and it has
% Internet connection

%   Copyright 2018 The MathWorks, Inc.

if ~isV4l2Installed(ssh) && hasInternetAccess(ssh)
    
    try
        disp('First time use setup ...');
        execute(ssh,'sudo apt-get install v4l-utils');
    catch
        error(message('raspi:utils:v4l2InstallFailed'));
    end
    
end

%% Helper functions
    function result = isV4l2Installed(Ssh)
        try
            execute(Ssh,'v4l2-ctl');
            result = true;
        catch
            result = false;
        end
    end

    function result = hasInternetAccess(Ssh)
        try
            execute(Ssh,'ping -c 2 www.google.com');
            result = true;
        catch
            result = false;
        end
    end
end

