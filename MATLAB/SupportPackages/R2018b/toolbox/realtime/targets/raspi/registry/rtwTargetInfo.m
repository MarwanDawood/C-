function rtwTargetInfo(tr)
%RTWTARGETINFO Register toolchain and target
 
% Copyright 2015-2018 The MathWorks, Inc.
tr.registerTargetInfo(@loc_createToolchain);
tr.registerTargetInfo(@loc_createPILConfig);
codertarget.TargetRegistry.addToTargetRegistry(@loc_registerThisTarget);
codertarget.TargetBoardRegistry.addToTargetBoardRegistry(@loc_registerBoardsForThisTarget);

% Register message catalog
baseRoot = raspi.internal.getRaspiBaseRoot;
if isfolder(fullfile(baseRoot,'resources'))
    matlab.internal.msgcat.setAdditionalResourceLocation(baseRoot);
end
end

% -------------------------------------------------------------------------
function config = loc_createToolchain
rootDir = fileparts(mfilename('fullpath'));
config = coder.make.ToolchainInfoRegistry; % initialize
archName = computer('arch');

% GNU GCC Raspberry Pi
config(end+1).Name             = 'GNU GCC Raspberry Pi';
config(end).Alias              = ['GNU_GCC_RASPBERRY_PI_', upper(archName)];
config(end).TargetHWDeviceType = {'*'};
config(end).FileName           = fullfile(rootDir, ['gnu_gcc_raspberrypi_toolchain_gmake_' archName '_v1.0.mat']);
config(end).Platform           = {archName};
end

function ret = loc_registerThisTarget()
ret.Name = 'raspberrypi';
ret.ShortName = 'raspberrypi';
[targetFilePath, ~, ~] = fileparts(fileparts(mfilename('fullpath')));
ret.TargetFolder = targetFilePath;
ret.TargetType = 1; % 0 = EC, 1 = SL, 2 = SL-C
end

% -------------------------------------------------------------------------
function boardInfo = loc_registerBoardsForThisTarget()
target = 'raspberrypi';
[targetFolder, ~, ~] = fileparts(fileparts(mfilename('fullpath')));
boardFolder = codertarget.target.getTargetHardwareRegistryFolder(targetFolder);
boardInfo = codertarget.target.getTargetHardwareInfo(targetFolder,boardFolder,target,true);
% Do not display 'Raspberry Pi - Robot Operating System (ROS)' hardware if
% Robotics System Toolbox is not installed. This target has many
% dependencies to robotics toolbox in the codertarget registration.
if isempty(ver('robotics'))
    for k = 1:numel(boardInfo)
        if isequal(boardInfo(k).Name,'Raspberry Pi - Robot Operating System (ROS)')
            boardInfo(k) = [];
            break;
        end
    end
end
end

%% ------------------------------------------------------------------------
function config = loc_createPILConfig
config(1) = rtw.connectivity.ConfigRegistry;
config(1).ConfigName = 'Raspberry Pi';
config(1).ConfigClass = 'codertarget.raspi.pil.ConnectivityConfig';
config(1).isConfigSetCompatibleFcn = @i_isConfigSetCompatible;
end

%% ------------------------------------------------------------------------
function isConfigSetCompatible = i_isConfigSetCompatible(configSet)
isConfigSetCompatible = false;
if configSet.isValidParam('CoderTargetData')
    data = configSet.getParam('CoderTargetData');
    isConfigSetCompatible = isequal(data.TargetHardware, ...
        'Raspberry Pi');
elseif isa(configSet,'coder.connectivity.MATLABConfig')
    hObj = configSet.getConfig;
    targetHardware = codertarget.target.getHardwareName(hObj);
    isConfigSetCompatible = ~isempty(targetHardware) && isequal(targetHardware, ...
        'Raspberry Pi');
end
end
% [EOF]

% LocalWords:  toolchain fullpath raspberrypi gmake codertarget raspi pil
