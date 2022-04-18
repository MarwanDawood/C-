function joystickBlockMaskcallback(varargin)
%JOYSTICK Block mask helper function for Joystick block.
%

% Copyright 2016 The MathWorks, Inc.

blk = gcbh;

% Execute "action" callback
action = varargin{1};
switch action
    case 'MaskInitialization'
        updatePortLabels(blk);
    case 'LoadImage'
        imageRoot = fullfile(codertarget.raspi.internal.getSpPkgRootDir,'blocks');
        imagePath = fullfile(imageRoot, 'sensehatJoystick_help.png');
        
        aMaskObj = Simulink.Mask.get(gcb);
        aImageControl = aMaskObj.getDialogControl('sensehatJoystick_help');
        aImageControl.FilePath = imagePath;
    otherwise
        error('raspi:internal:UnknownCallback',...
            'Unknown callback action "%s"',action)
end
end

%--------------------------------------------------------------------------
function updatePortLabels(blk)
% Update port labels
eol = char(10);
platform = realtime.internal.getBlockDisplayText(gcb);

maskDisplayStr = ['image(imread(''sensehatJoystick.png''),[0.32 0.15 0.35 0.55]);', eol];
maskDisplayStr = [maskDisplayStr, 'color(''blue'');', eol, ...
    'text(0.65, 0.90, ''' platform ''', ''horizontalAlignment'', ''right'');', eol ...
    'color(''black'');', eol, ...
    ];
set_param(blk,'MaskDisplay',maskDisplayStr);
end

%[EOF] LINUXGPIOREAD.M
