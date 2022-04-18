function list = raspilist(varargin)
%   List available Raspberry Pi hardware boards for MATLAB Online connection
%
%   Syntax:
%   list = raspilist
%
%   Description:
%   Returns a list of Raspberry Pi boards that you can connect to in MATLAB Online.
%
%   Example:
%       list = raspilist;
%
%   Output Arguments:
%   list - A table that lists available Raspberry Pi boards
%
%   See also raspi

% Copyright 2018 The MathWorks, Inc.
try
    s = settings;
    if s.matlab.hardware.raspi.IsOnline.ActiveValue
        % hidden PV pair
        % accept only when it is specified full case and with correct value
        p = inputParser;
        p.PartialMatching = false;
        p.CaseSensitive = true;
        addParameter(p,'Timeout',10,@isnumeric);
        try
            parse(p, varargin{:});
        catch 
            error(message('raspi:online:InvalidRaspiParams'));
        end
            
        channel = raspi.internal.pubsubChannel.getInstance();
        if nargin == 0
            output = scan(channel);
        else
            output = scan(channel,p.Results.Timeout);
        end
        if isempty(output)
            list = [];
            raspi.internal.localizedWarning('raspi:online:NoRaspiFound');
            return;
        end
        numPis = length(output);
        template = strings(numPis,1);
        list = table(template,template,template,template);
        list.Properties.Description = 'Raspberry Pi Connection Status';
        list.Properties.VariableNames = {'Name', 'SerialNumber', 'PackageVersion', 'Status'};
        for index = 1:numPis
            dev = strsplit(output{index},'&');
            list.SerialNumber(index) = string(dev{1});
            list.Name(index) = string(dev{2});
            list.PackageVersion(index) = string(dev{3});
            if strcmp(dev{4}, message('raspi:online:StatusUpgrade').getString)
                list.Status(index) = message('raspi:online:StatusUpgradeLink').string;
            elseif strcmp(dev{4}, message('raspi:online:StatusLogin').getString)
                list.Status(index) = message('raspi:online:StatusLoginLink').string;
            else
                list.Status(index) = string(dev{4});
            end
        end
    else
        raspi.internal.localizedWarning('raspi:utils:UnsupportedInterface');
    end
catch e
    throwAsCaller(e);
end
end