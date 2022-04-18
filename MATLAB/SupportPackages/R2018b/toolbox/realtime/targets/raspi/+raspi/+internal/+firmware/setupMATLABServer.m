function setupMATLABServer(deviceAddress, username, password)
%setupMATLABServer Push files to raspberry pi

%  Copyright 2013-2014 The MathWorks, Inc.

raspi.updateServer(deviceAddress,username,password);
end
%[EOF]