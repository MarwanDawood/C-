function ret = getUdpIpPort(sel)
%GETUDPIPPORT Returns the UDP port used for IP address discovery. 

%  Copyright 2015-2017 The MathWorks, Inc.

sel = validatestring(sel,{'discover','find'});
if isequal(sel,'discover')
    ret = 18734;
else
    ret = 18726;
end
end
%[EOF]