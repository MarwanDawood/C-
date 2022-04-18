function blkStruct = slblocks
% SLBLOCKS Defines the block library for Raspberry Pi

%   Copyright 2012 The MathWorks, Inc.

blkStruct.Name = sprintf('Raspberry Pi');
blkStruct.OpenFcn = 'raspberrypilib';
blkStruct.MaskInitialization = '';
blkStruct.MaskDisplay = 'disp(''Raspberry Pi'')';

Browser(1).Library = 'raspberrypilib';
Browser(1).Name    = sprintf('Simulink Support Package for Raspberry Pi Hardware');
Browser(1).IsFlat  = 0; % Is this library "flat" (i.e. no subsystems)?

blkStruct.Browser = Browser;  

% Define information for model updater
blkStruct.ModelUpdaterMethods.fhSeparatedChecks = @ecblksUpdateModel;
 
