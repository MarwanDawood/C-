function baseRoot = getRaspiBaseRoot(filePath)
%GETRASPIROOT Return root directory

% Copyright 2014 The MathWorks, Inc.
if nargin < 1
    filePath = fileparts(mfilename('fullpath'));
end

% Get installation folder
% Lookfor toolbox at the end of the path
tmp = regexp(filePath, '(.+)toolbox.+$', 'tokens', 'once'); 
baseRoot = tmp{1};

end
