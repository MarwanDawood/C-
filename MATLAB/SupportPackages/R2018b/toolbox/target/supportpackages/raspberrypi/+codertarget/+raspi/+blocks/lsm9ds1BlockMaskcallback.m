function lsm9ds1BlockMaskcallback(varargin)
%LPS25H Block mask helper function for LPS25H block.
%

% Copyright 2016 The MathWorks, Inc.

blk = gcbh;

% Execute "action" callback
action = varargin{1};
switch action
    case 'MaskInitialization'
        sensor = get_param(blk, 'ActiveSensors_');
        set_param(blk, 'ActiveSensors', sensor);
        updatePortLabels(blk);
    case 'ActiveSensors'
        sensor = get_param(blk, 'ActiveSensors_');
        set_param(blk, 'ActiveSensors', sensor);
    case 'Advanced'
        activeSensor = get_param(blk, 'ActiveSensors_');
        aMaskObj = Simulink.Mask.get(gcb);
        aGyro = aMaskObj.getDialogControl('GyroTab');
        aAccel = aMaskObj.getDialogControl('AccelTab');
        aMag = aMaskObj.getDialogControl('MagTab');
        switch (activeSensor)
            case 'Accelerometer, Gyroscope and Magnetometer'
                aGyro.Enabled='on';
                aAccel.Enabled='on';
                aMag.Enabled='on';
            case 'Accelerometer and Gyroscope'
                aGyro.Enabled='on';
                aAccel.Enabled='on';
                aMag.Expand='off';
                aMag.Enabled='off';
            case 'Accelerometer and Magnetometer'
                aGyro.Expand='off';
                aGyro.Enabled='off';
                aAccel.Enabled='on';
                aMag.Enabled='on';
            case 'Gyroscope and Magnetometer'
                aGyro.Enabled='on';
                aAccel.Expand='off';
                aAccel.Enabled='off';
                aMag.Enabled='on';
            case 'Accelerometer'
                aGyro.Expand='off';
                aGyro.Enabled='off';
                aAccel.Enabled='on';
                aMag.Expand='off';
                aMag.Enabled='off';
            case 'Gyroscope'
                aGyro.Enabled='on';
                aAccel.Expand='off';
                aAccel.Enabled='off';
                aMag.Expand='off';
                aMag.Enabled='off';
            case 'Magnetometer'
                aGyro.Expand='off';
                aGyro.Enabled='off';
                aAccel.Expand='off';
                aAccel.Enabled='off';
                aMag.Enabled='on';
        end
        
    case 'GyroHPF'
        maskVisibilities = get_param(blk, 'MaskVisibilities');
        gyroHPF  = get_param(gcb, 'GyroscopeHighPassFilterEnabled');
        if strcmp(gyroHPF,'on')
            [maskVisibilities{11}] = deal('on');
        else
            [maskVisibilities{11}] = deal('off');
        end
        set_param(blk, 'MaskVisibilities', maskVisibilities);
        
    case 'Validate'
        validatelsm9ds1block(blk);
    otherwise
        error('raspi:internal:UnknownCallback',...
            'Unknown callback action "%s"',action)
end
end

%--------------------------------------------------------------------------
function updatePortLabels(blk)
% Update port labels
eol = newline;
platform = realtime.internal.getBlockDisplayText(gcb);

maskDisplayStr = ['image(imread(''sensehat_lsm9ds1.png''),[0.30 0.20 0.35 0.55]);', eol];
maskDisplayStr = [maskDisplayStr, 'color(''blue'');', eol, ...
    'text(0.65, 0.90, ''' platform ''', ''horizontalAlignment'', ''right'');', eol ...
    'color(''black'');', eol, ...
    'activesensors = get_param(gcb, ''ActiveSensors_'');',eol,...
    'switch(activesensors)',eol,...
    'case(''Accelerometer, Gyroscope and Magnetometer'')',eol,...
    'port_label(''output'', 1, ''AngVelocity'');', eol, ...
    'port_label(''output'', 2, ''Accel'');', eol, ...
    'port_label(''output'', 3, ''MagField'');', eol, ...
    'case(''Accelerometer and Gyroscope'')',eol,...
    'port_label(''output'', 1, ''AngVelocity'');', eol, ...
    'port_label(''output'', 2, ''Accel'');', eol, ...
    'case(''Gyroscope and Magnetometer'')',eol,...
    'port_label(''output'', 1, ''AngVelocity'');', eol, ...
    'port_label(''output'', 2, ''MagField'');', eol, ...
    'case(''Accelerometer and Magnetometer'')',eol,...
    'port_label(''output'', 1, ''Accel'');', eol, ...
    'port_label(''output'', 2, ''MagField'');', eol, ...
    'case(''Accelerometer'')',eol,...
    'port_label(''output'', 1, ''Accel'');', eol, ...
    'case(''Gyroscope'')',eol,...
    'port_label(''output'', 1, ''AngVelocity'');', eol, ...
    'case(''Magnetometer'')',eol,...
    'port_label(''output'', 1, ''MagField'');', eol, ...
    'end',eol,...
    ];
set_param(blk,'MaskDisplay',maskDisplayStr);
end
%--------------------------------------------------------------------------
function validatelsm9ds1block(~, varargin)
%Only one block allowed for model.
opts.familyName = 'LSM9DS1';
opts.parameterName = 'LSM9DS1_Number';
opts.parameterValue = 'IMU';
opts.parameterCallback = {'allDifferent'};
opts.blockCallback = [];
opts.errorID ={'raspberrypi:utils:LSM9ds1ModuleAlreadyUsed'};
opts.errorArgs = '';
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);
end
%--------------------------------------------------------------------------

%[EOF] LSM9DS1BLOCKMASKCALLBACK.M
