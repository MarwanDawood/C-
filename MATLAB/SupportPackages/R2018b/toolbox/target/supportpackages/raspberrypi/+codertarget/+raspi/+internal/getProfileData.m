function [sectionIds, timerValues, coreNums] = getProfileData(modelName)
%GETPROFILEDATA Get the profile data from the target hardware

%   Copyright 2015 The MathWorks, Inc.


% ASSUMPTIONS:
% 1) Profiling data file <modelName>.txt must exist on target hardware
% 2) The target used to generate the profiling data must be registered
% 3) The model <modelName> must be on MATLAB path 
% 4) Current folder must be writable.

[~, name, ~] = fileparts(modelName);
filename = [name '.txt'];
r = raspberrypi;
getFile(r, filename);

% Parse profiling data
d = importdata(filename);
sectionIds = uint32(d(:,1));
timerValues = uint32(d(:,2));
[~, w] = size(d);
if (w>2)
    coreNums = uint32(d(:,3));
else
    coreNums = [];
end
end
