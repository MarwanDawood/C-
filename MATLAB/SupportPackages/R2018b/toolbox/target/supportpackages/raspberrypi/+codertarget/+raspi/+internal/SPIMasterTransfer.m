classdef SPIMasterTransfer < matlabshared.svd.SPIMasterBlock ...
        & coder.ExternalDependency
    %SPIMasterTransfer Set the logical value of a digital output pin.
    %
    % Copyright 2016-2018 The MathWorks, Inc.
    %#codegen
    
   
    properties (Nontunable)
        %SPIModule SPI module
        SPIModule = 0;
    end
    methods
        function set.SPIModule(obj,value)
        if ~coder.target('Rtw') && ~coder.target('Sfun')
            if ~isempty(obj.Hw)
                if ~isValidSPIModule(obj.Hw,value)
                    error(message('svd:svd:ModuleNotFound','SPI',value));
                end
            end
        end
        obj.SPIModule = uint32(value);
        end
        
        function ret = get.SPIModule(obj)
        ret = uint32(obj.SPIModule);
        end
    end
    
    properties (Nontunable)
        %BoardProperty Board
        BoardProperty = 'Pi 2 Model B';
        %Pin Slave select pin
        Pin = 'SPI0_CE0';
        %Pin = 0;
    end
       
    properties (Constant, Hidden)
        PinSet = matlab.system.StringSet({'SPI0_CE0','SPI0_CE1'});
        BoardPropertySet = matlab.system.StringSet({'Model B Rev1','Model B Rev2', 'Model B+', 'Pi 2 Model B','Pi 3 Model B', 'Pi 3 Model B+', 'Pi Zero W'});
    end
    
    methods
        function set.Pin(obj,value)
        if ~coder.target('Rtw') && ~coder.target('Sfun')
            if ~isempty(obj.Hw)
                if ~isValidSlaveSelectPin(obj.Hw,obj.SPIModule,value)
                    error(message('svd:svd:PinNotFound',value,'SPI Master Transfer'));
                end
            end
        end
        %obj.Pin = value(end);
       obj.Pin = value;
        end
    end
    
    methods(Access = protected)
        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            flag = isInactivePropertyImpl@matlabshared.svd.SPIMasterBlock(obj, prop);
            switch prop
                case {'SPIModule', 'FirstBitToTransfer'}
                    flag = true;
            end
        end
    end
    
    methods
        function obj = SPIMasterTransfer(varargin)
        coder.allowpcode('plain');
        coder.cinclude('MW_SPI_Helper.h');
        obj.Hw = codertarget.raspi.internal.Hardware;
        obj.Logo = 'RASPBERRYPI';
        obj.BlockFunction = 'Transfer';
        obj.UseCustomSSPin = 'Provided by the SPI peripheral';
        setProperties(obj,nargin,varargin{:});
        end
    end
    
      methods (Access=protected)
          function maskDisplayCmds = getMaskDisplayImpl(obj)
            
            if isequal(obj.BlockFunction,'Transfer')
                BlockFunctionStr = 'Master';
            else
                BlockFunctionStr = 'Register';
            end
            BlockFunctionStr = sprintf('%s %s',BlockFunctionStr,obj.BlockFunction);
            
            maskDisplayCmds = [ ...
                ['color(''white'');', char(10)]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', char(10)]...
                ['plot([0,0,0,0],[0,0,0,0]);', char(10)]...
                ['color(''blue'');', char(10)] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', char(10)] ...
                ['color(''black'');', char(10)] ...
                ['text(50,60,''\fontsize{12}\bfSPI'',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', char(10)], ...
                ['text(50,40,''\fontsize{10}\bf' BlockFunctionStr ''',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', char(10)], ...
                ['text(50,15,''Slave select: ' num2str(obj.Pin) ''' ,''horizontalAlignment'', ''center'');', char(10)], ...%['text(50,15,''SPI: ' num2str(obj.SPIModule) ''' ,''horizontalAlignment'', ''center'');', char(10)], ...
                ];
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
        header = matlab.system.display.Header(mfilename('class'),...
            'ShowSourceLink', false, ...
            'Title','SPI Master Transfer', ...
            'Text', ['Write data to and read data from an SPI slave device.' char(10) char(10) ...
            'The block accepts a 1-D array of data type int8, uint8, int16, uint16, int32, uint32, single or double. The block outputs a 1-D array of the same size and data type as the input values.']);
        end
        
        function [groups, PropertyListMain, SampleTimeProp] = getPropertyGroupsImpl
            [~, PropertyListMainOut] = matlabshared.svd.SPIBlock.getPropertyGroupsImpl;
            % BoardProperty
            BoardProperty = matlab.system.display.internal.Property('BoardProperty', 'Description', 'Board');
            BoardPropertyCell = {BoardProperty};
            PropertyListMainOut = [BoardPropertyCell  PropertyListMainOut];
            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListMainOut);
            groups = Group;
            % Output property list if requested
            if nargout > 1
                PropertyListMain = PropertyListMainOut;
                SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
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
        name = 'SPI Master Transfer';
        end
        
        function b = isSupportedContext(context)
        b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
            % SPI interface
                spkgrootDir = codertarget.raspi.internal.getSpPkgRootDir;
                raspiserverDir = fullfile(raspi.internal.getRaspiRoot, 'server');
                addIncludePaths(buildInfo, raspiserverDir);
                svdDir = matlabshared.svd.internal.getRootDir;
                addIncludePaths(buildInfo, fullfile(spkgrootDir,'include'));
                buildInfo.addIncludeFiles('MW_SPI_Helper.h');
                addIncludePaths(buildInfo,fullfile(svdDir,'include'));
                addSourcePaths(buildInfo, fullfile(spkgrootDir,'src'));
                addSourceFiles(buildInfo,'MW_SPI.c', fullfile(spkgrootDir,'src'), 'BlockModules');
            end
        end
    end
end
%[EOF]
