function rootDir = getRootDir()
%GETSPPKGROOTDIR Return the root directory of this support package

%   Copyright 2016 The MathWorks, Inc.
rootDir = fileparts(strtok(mfilename('fullpath'), '+'));

end

