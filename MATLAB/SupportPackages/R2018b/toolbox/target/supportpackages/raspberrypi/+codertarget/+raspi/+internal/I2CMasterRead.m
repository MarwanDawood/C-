classdef I2CMasterRead < matlabshared.svd.I2CMasterRead ...
        & coder.ExternalDependency
    %I2CMasterRead Read data from an I2C slave device or an I2C slave device register.
    %
    %The block outputs the values received as an 1-D uint8 array.
    %
    % Copyright 2016-2018 The MathWorks, Inc.
    %#codegen
    properties(Nontunable)
        %BoardProperty Board
        BoardProperty = 'Pi 2 Model B';
    end
    
    properties (Dependent,Nontunable, Hidden)
        %I2CModule I2C module
        I2CModule = '1';
    end
    
    properties (Constant, Hidden)
        I2CModuleSet = matlab.system.StringSet({'0','1'});
        BoardPropertySet = matlab.system.StringSet({'Model B Rev1','Model B Rev2', 'Model B+', 'Pi 2 Model B','Pi 3 Model B', 'Pi 3 Model B+', 'Pi Zero W'});
    end
    
    methods
        function ret = get.I2CModule(obj)
            if isequal(obj.BoardProperty,'Model B Rev1')
                ret = '0';
            else
                ret = '1';
            end
        end
    end
    
    methods
        function obj = I2CMasterRead(varargin)
        coder.allowpcode('plain');
        obj.Hw = codertarget.raspi.internal.Hardware;
        obj.Logo = 'RASPBERRYPI';
        setProperties(obj,nargin,varargin{:});
        end
    end
       
    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.svd.I2CBlock.getPropertyGroupsImpl;
            
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
             % BoardProperty
            BoardProperty = matlab.system.display.internal.Property('BoardProperty', 'Description', 'Board');
           
            % Add to property list
            PropertyListOut{end+1} = SampleTimeProp;
            % Replace I2C Module with BoardProperty
            PropertyListOut{1} = BoardProperty;

            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            % Output property list if requested
            if nargout > 1
                PropertyList = PropertyListOut;
            end
            viewPinMapAction = matlab.system.display.Action(@codertarget.raspi.blocks.openPinMap, ...
            'Alignment', 'right', ...
            'Placement','BoardProperty',...
            'Label', 'View pin map');
        matlab.system.display.internal.setCallbacks(viewPinMapAction, ...
            'SystemDeletedFcn', @codertarget.raspi.blocks.closePinMap);
        groups(1).Actions = viewPinMapAction;
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
        name = 'I2C Master Read';
        end
        
        function b = isSupportedContext(context)
        b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
        if context.isCodeGenTarget('rtw')
            % I2C interface
            spkgrootDir = codertarget.raspi.internal.getSpPkgRootDir;
            raspiserverDir = fullfile(raspi.internal.getRaspiRoot, 'server');
            svdDir = matlabshared.svd.internal.getRootDir;
            addIncludePaths(buildInfo, fullfile(svdDir,'include'));
            addIncludeFiles(buildInfo,'MW_I2C.h');
            addSourcePaths(buildInfo, fullfile(spkgrootDir,'src'));
            addSourceFiles(buildInfo,'MW_I2C.c', fullfile(spkgrootDir,'src'), 'BlockModules');
            addIncludePaths(buildInfo, raspiserverDir);
            addIncludeFiles(buildInfo,'I2C.h');
            addSourcePaths(buildInfo, raspiserverDir);
            addSourceFiles(buildInfo,'devices.c',raspiserverDir,'BlockModules');
        end
        end
    end
end
%[EOF]
