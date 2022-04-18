function output = getDocMap()
% This function returns the raspberrypiio map full path

%   Copyright 2018 The MathWorks, Inc.

output = matlabshared.supportpkg.getSupportPackageRoot;

output = fullfile(output, 'help', 'supportpkg','raspberrypiio', 'helptargets.map');

end