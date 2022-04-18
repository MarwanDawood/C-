function lps25hBlockMaskcallback(varargin)
%LPS25H Block mask helper function for HTS221 block.
%

% Copyright 2016 The MathWorks, Inc.

blk = gcbh;

% Execute "action" callback
action = varargin{1};
switch action
    case 'Validate'
        validatelps25hblock(blk);
    otherwise
        error('raspi:internal:UnknownCallback',...
            'Unknown callback action "%s"',action)
end
end

%--------------------------------------------------------------------------
function validatelps25hblock(~, varargin)
%Only one block allowed for model.
opts.familyName = 'LPS25H';
opts.parameterName = 'LPS25H_Number';
opts.parameterValue = 'pre4ssure';
opts.parameterCallback = {'allDifferent'};
opts.blockCallback = [];
opts.errorID ={'raspberrypi:utils:LPS25hModuleAlreadyUsed'};
opts.errorArgs = '';
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);
end
%--------------------------------------------------------------------------

%[EOF] LPS25HBLOCKMASKCALLBACK.M
