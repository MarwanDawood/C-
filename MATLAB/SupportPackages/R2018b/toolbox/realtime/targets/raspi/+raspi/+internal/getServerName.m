function ret = getServerName
%GETSERVERNAME Returns the MATLAB I/O server name. 

%  Copyright 2015-2018 The MathWorks, Inc.

s = settings;
if ~s.matlab.hardware.raspi.IsOnline.ActiveValue
    ret = 'matlabIOserver';
else
    ret = 'mwioserver';
end
end
%[EOF]