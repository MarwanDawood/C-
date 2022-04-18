function raspiAudioFileReadCallback(varargin)
%RASPIAUDIOFILEREADCALLBACK Mask Helper Function for Audio File Read block.
%
% Copyright 2017 The MathWorks, Inc.

blk = gcbh;

% Check on input "action"
action = varargin{1};
switch action
    
    % Browse... button callback
    case 'BrowseFile'
        
        [filename, pathname] = uigetfile(getSpec, 'Pick an audio file');
        
        if ~(isequal(filename,0) || isequal(pathname,0))
            fullname = fullfile(pathname,filename);
            set_param(blk, 'Filename', fullname);
        end
        
    otherwise
        error('tfBlockBuilder:UnknownCallback','Unknown callback action "%s"', action)
end
end

% Construc format spec for uigetfile
function format = getSpec

format = '';

str = '';
for i=1:numel(codertarget.raspi.internal.AudioFileRead.SupportedFileTypes)
    str = [str '*' codertarget.raspi.internal.AudioFileRead.SupportedFileTypes{i}, ';'];
end

format{end+1} = str;
format{end+1} = 'All supported audio file types';
end

