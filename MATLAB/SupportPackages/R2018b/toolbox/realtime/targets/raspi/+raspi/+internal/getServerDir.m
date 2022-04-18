function serverDir = getServerDir
%GETSERVERDIR Returns MATLAB server installation directory. 

%  Copyright 2015 The MathWorks, Inc.

version = raspi.internal.getServerVersion;
serverDir = ['/opt/MATLAB/server_v', ...
    num2str(version(1)) '.', ...
    num2str(version(2)) '.', ...
    num2str(version(3))];
end
%[EOF]