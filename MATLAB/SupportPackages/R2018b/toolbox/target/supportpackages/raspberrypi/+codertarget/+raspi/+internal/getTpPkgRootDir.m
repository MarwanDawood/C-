function rootDir = getTpPkgRootDir(name)
%GETTPPKGROOTDIR Return the third party package root directory

%   Copyright 2013-2016 The MathWorks, Inc.

rootDir = matlab.internal.get3pInstallLocation(name);

end

