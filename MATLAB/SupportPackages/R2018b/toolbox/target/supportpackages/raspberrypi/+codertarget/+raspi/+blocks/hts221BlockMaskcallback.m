function hts221BlockMaskcallback(varargin)
%HTS221 Block mask helper function for HTS221 block.
%

% Copyright 2016 The MathWorks, Inc.

blk = gcbh;

% Execute "action" callback
action = varargin{1};
switch action
    case 'Validate'
        validatehts221block(blk);
    otherwise
        error('raspi:internal:UnknownCallback',...
            'Unknown callback action "%s"',action)
end
end

%--------------------------------------------------------------------------
function validatehts221block(~, varargin)
%Only one block allowed for model.
opts.familyName = 'HTS2211';
opts.parameterName = 'HTS2211_Number';
opts.parameterValue = 'Humidty';
opts.parameterCallback = {'allDifferent'};
opts.blockCallback = [];
opts.errorID ={'raspberrypi:utils:HTS221ModuleAlreadyUsed'};
opts.errorArgs = '';
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);
end
%--------------------------------------------------------------------------
%[EOF] HTS221BLOCKMASKCALLBACK.M
