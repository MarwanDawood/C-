function rootDir = getRootDir()
%GETROOTDIR Return the root directory of asyncioplugins component

%   Copyright 2015 The MathWorks, Inc.

rootDir = fileparts(strtok(mfilename('fullpath'), '+'));

end