function rootDir = getRaspiRoot()
%GETRASPIROOT Return root directory

% Copyright 2013 The MathWorks, Inc.

% Get installation folder
rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));

end
