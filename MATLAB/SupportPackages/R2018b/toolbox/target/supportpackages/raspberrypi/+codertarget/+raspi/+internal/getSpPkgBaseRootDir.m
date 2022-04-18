function baseRoot = getSpPkgBaseRootDir(filePath)
% Return root directory

% Copyright 2014 The MathWorks, Inc.
if nargin < 1
    filePath = fileparts(mfilename('fullpath'));
end

% Get installation folder referencing toolbox directory. Note that we are
% looking for the toolbox at the end of the string.
tmp = regexp(filePath, '(.+)toolbox.+$', 'tokens', 'once'); 
baseRoot = tmp{1};

end
