classdef ThingSpeakRead < matlab.System ...
        & matlab.system.mixin.internal.SampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.internal.CustomIcon

    % Read data from online service ThingSpeak.
    
    % Copyright 2017 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % ChannelID Channel ID
        ChannelID = 12345;
        % FieldNumber Field Number
        FieldNumber = '1';
        % ChannelAccess Channel Access
        ChannelAccess = 'Public';
        % ReadAPIKey Read API Key
        ReadAPIKey = 'ABCDEFGHIJK';
        % SampleTime Sample time
        SampleTime = 60;
    end
    
    properties (Nontunable, Logical)
        % PrintDiagnosticMessages Print diagnostic messages
        PrintDiagnosticMessages = false;
    end
    
    properties (Nontunable, Logical, Hidden)
        Debug = false;
    end
    
    properties (Hidden, Access=private)
        LastUpdateTime
        TSHandle
        TSHandleInitialized
    end
    
    properties (Hidden,Nontunable)
        % Block platform
        blockPlatform = 'RASPBERRYPI';
    end
    
    properties (Constant, Hidden)
        ChannelAccessSet = matlab.system.StringSet({'Public', 'Private'});
        FieldNumberSet = matlab.system.StringSet({'1', '2', '3', '4', '5', '6', '7', '8'});
    end
    
    methods
        % Constructor
        function obj = ThingSpeakRead(varargin) 
            %This would allow the code generation to proceed with the
            %p-files in the installed location of the support package.
            coder.allowpcode('plain');
            
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.ChannelID(obj, val)
            validateattributes(val, {'single', 'double'}, ...
                {'scalar', 'real', 'positive', 'nonnan', 'finite','integer'}, '', 'ChannelID');
            obj.ChannelID = val;
        end
        
        function set.FieldNumber(obj, val)
            validateattributes(val, ...
                {'char'}, {'nonempty'}, '', 'FieldNumber');
            obj.FieldNumber = strtrim(val);
        end
        
        function set.ReadAPIKey(obj, val)
            validateattributes(val, ...
                {'char'}, {'nonempty'}, '', 'ReadAPIKey');
            obj.ReadAPIKey = strtrim(val);
        end
        
        function set.SampleTime(obj,sampleTime)
            coder.extrinsic('error');
            coder.extrinsic('message');
            
            validateattributes(sampleTime,{'numeric'},...
                {'nonnan', 'finite'},...
                '','''Sample time''');
            
            % Sample time must be a real scalar value or 2 element array.
            if ~isreal(sampleTime(1)) || numel(sampleTime) > 2
                error(message('linux:utils:InvalidSampleTimeNeedScalar'));
            end
            if numel(sampleTime) == 2 && sampleTime(1) > 0.0 && sampleTime(2) >= sampleTime(1)
                error(message('linux:utils:InvalidSampleTimeNeedSmallerOffset'));
            end
            if numel(sampleTime) == 2 && sampleTime(1) == -1.0 && sampleTime(2) ~= 0.0
                error(message('linux:utils:InvalidSampleTimeNeedZeroOffset'));
            end
            if numel(sampleTime) == 2 && sampleTime(1) == 0.0 && sampleTime(2) ~= 1.0
                error(message('linux:utils:InvalidSampleTimeNeedOffsetOne'));
            end
            if numel(sampleTime) ==1 && sampleTime(1) < 1 && sampleTime(1) ~= -1.0
                error(message('linux:utils:InvalidSampleTimeNeedPositive'));
            end
            obj.SampleTime = sampleTime;
        end
        
        function TSReadUrl = getTSReadUrl(obj)
            len = max(ceil(log10(abs(obj.ChannelID))),1);
            channelID = int32(obj.ChannelID);
            channelIdstr = char(48*ones(1,len));
            coder.ceval('MW_int2string',channelID,coder.wref(channelIdstr));
            if strcmp(obj.ChannelAccess,'Public')
                url = ['https://api.thingspeak.com/channels/',channelIdstr,'/fields/',obj.FieldNumber,'/last.txt'];
            else
                url = ['https://api.thingspeak.com/channels/',channelIdstr,'/fields/',obj.FieldNumber,'/last.txt?api_key=',obj.ReadAPIKey];
            end
            TSReadUrl = strtrim(url);
        end
          
    end
    
    methods (Access=protected)
        %% Common functions
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            
            if coder.target('Rtw')
                % Create URL from channelID and field number
                % TO DO:
                % Add ReadAPI to URL for private channels
                if obj.SampleTime > 2
                    readTime = obj.SampleTime;
                else
                    readTime = 2;
                end
                
                obj.TSHandleInitialized = false;
				
                TSReadUrl = obj.getTSReadUrl();
                obj.TSHandle = coder.opaque('TSReadData_t *','NULL','HeaderFile','MW_thingspeak.h');
                nullHandle = obj.TSHandle;
                obj.TSHandle = coder.ceval('MW_TSRead_init',...
                    cString(TSReadUrl),readTime);
                if obj.TSHandle ~= nullHandle
                    obj.TSHandleInitialized = true;
                end
                if obj.PrintDiagnosticMessages
                    coder.updateBuildInfo('addDefines','PRINT_DEBUG_MESSAGES');
                end
            end
        end
        
        function [data, status] = stepImpl(obj)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            data = single(0);
            status = int16(-1);
            if coder.target('Rtw')
                if obj.TSHandleInitialized
                    coder.ceval('MW_TSRead_step',obj.TSHandle, coder.wref(data),coder.wref(status));
                end
            else
                % Add simulation 
                data = single(0);
                status = int16(0);
            end
        end
        
        function releaseImpl(obj)
            if coder.target('Rtw')
                coder.ceval('MW_TS_terminate',obj.TSHandle);
            end
        end
        
        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            flag = false;
            if strcmp(prop,'ReadAPIKey')
                flag = strcmp(obj.ChannelAccess,'Public');
            end
        end
        
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        function num = getNumOutputsImpl(~)
            num = 2;
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(~,~)
            varargout{1} = true;
            varargout{2} = true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout{1} = false;
            varargout{2} = false;
        end
        
        function varargout = getOutputSizeImpl(~)
            varargout{1} = [1,1];
            varargout{2} = [1,1];
        end
        
        function varargout = getOutputDataTypeImpl(~)
            % Return data type for each output port
            varargout{1} = 'single';
            varargout{2} = 'int16';
        end
        
        function st = getSampleTimeImpl(obj)
            st = obj.SampleTime;
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            %Icon display
            iconstr = ['Channel:',num2str(obj.ChannelID)];
            port1Label = ['port_label(''output'',1,''Field',obj.FieldNumber,''');'];
            
            maskDisplayCmds = { ...
                ['color(''white'');', newline],...    % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline],... % Drawing mask layout of the block
                ['plot([0,0,0,0],[0,0,0,0]);', newline],...
                ['color(''black'');', newline] ...
                [port1Label, newline],...
                ['port_label(''output'',2,''Status'');', newline],...
                ['text(50, 12,''' iconstr ''', ''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');',newline]...
                };
            
            labelSample = obj.blockPlatform;
            maskDisplayCmdsTarget = { ...
                ['color(''blue'');', newline],...
                ['text(96, 90, ''' labelSample ''', ''horizontalAlignment'', ''right'');', newline],...
                ['color(''black'');', newline],...
                ['image(''cloudread_linux.png'',''center'');', newline],...
                };
            maskDisplayCmds = [maskDisplayCmds maskDisplayCmdsTarget];
        end
        
        
    end
        
    methods (Static, Access=protected)
        
        function groups = getPropertyGroupsImpl(~)
            % Define section for properties in System block dialog box.
            requiredGroup = matlab.system.display.Section(...
                'Title', 'Parameters',...
                'PropertyList', {'ChannelID', 'ChannelAccess', 'ReadAPIKey', 'FieldNumber', ...
                'PrintDiagnosticMessages', 'SampleTime'});
            groups = requiredGroup;
        end
        
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
        function header = getHeaderImpl()
            textDisp1 = getString(message('linux:blockmask:ThingSpeakReadLine1'));
            textDisp2 = getString(message('linux:blockmask:ThingSpeakReadLine2'));
            textDisp3 = getString(message('linux:blockmask:ThingSpeakReadLine3'));
            MaskText = [textDisp1,...
                newline,newline,...
                textDisp2,...
                newline,newline,...
                textDisp3];
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','ThingSpeak Read', ...
                'Text', MaskText);
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'ThingSpeak Read';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                rootDir = realtime.internal.getLinuxRoot();
                buildInfo.addIncludePaths(fullfile(rootDir,'include'));
                buildInfo.addIncludeFiles('MW_thingspeak.h');
                
                systemTargetFile = get_param(buildInfo.ModelName,'SystemTargetFile');
                if isequal(systemTargetFile,'ert.tlc')
                    buildInfo.addSourceFiles('MW_thingspeak.c',fullfile(rootDir,'src'));
                    addLinkFlags(buildInfo,'-lcurl');
                end
            end
        end
    end
end

%% Internal function
function str = cString(str)
str = [str uint8(0)];
end



