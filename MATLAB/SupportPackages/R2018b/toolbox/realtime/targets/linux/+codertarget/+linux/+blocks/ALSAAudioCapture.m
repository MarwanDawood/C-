classdef ALSAAudioCapture < matlab.System ...
        & matlab.system.mixin.internal.SampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.internal.CustomIcon

    % Capture sound samples from audio card. 
    
    % Copyright 2017 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % deviceStr Device name
        deviceStr = 'hw:1,0'
        % DataBitDepth Device Bit depth
        DataBitDepth = '16-bit integer'
        % numberOfChannels Number of channels(C)
        numberOfChannels = 2
        % sampleRateEnum Audio sampling frequency (Hz)
        sampleRateEnum = 44100
        % frameSize Samples per frame(N)
        frameSize = 4410
        % QueueDuration Queue duration (seconds)
        QueueDuration = 0.5
        % Block platform
        blockPlatform = 'RASPBERRYPI';
    end
    
    properties (Hidden,Nontunable)
        MW_dataType
    end
    
    properties (Constant, Hidden)
        DataBitDepthSet = matlab.system.StringSet({'8-bit integer', '16-bit integer', '32-bit integer'});
    end
    
    methods
        % Constructor
        function obj = ALSAAudioCapture(varargin) 
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
        end

        function set.deviceStr(obj, value)
            validateattributes(value, ...
                {'char'}, {'nonempty'}, '', 'Device name');
            obj.deviceStr = strrep(value,'''','');
        end

        function set.sampleRateEnum(obj, value)
            validateattributes(value,{'numeric'},...
                {'real','nonzero','positive','scalar','integer','>=',1,'nonnan'},'','Audio sampling frequency');
            obj.sampleRateEnum = value;
        end
        
        function set.frameSize(obj, value)
            validateattributes(value,{'numeric'},...
                {'real','nonzero','positive','scalar','integer','>=',1,'nonnan'},'','Samples per frame');
            obj.frameSize = value;
        end
        
        function set.numberOfChannels(obj, value)
            validateattributes(value,{'numeric'},...
                {'real','nonzero','positive','scalar','integer','>=',1,'<=',16,'nonnan'},'','numberOfChannels');
            obj.numberOfChannels = value;
        end
        
        
        function open(obj)
            coder.ceval('audioCaptureInit',...
                cstr(obj.deviceStr),...
                obj.sampleRateEnum,...
                obj.numberOfChannels,...
                obj.QueueDuration,...
                obj.frameSize,...
                obj.MW_dataType);
        end
        
        function y = readStream(obj)
            switch obj.DataBitDepth
                case '8-bit integer'
                    DataType = 'int8';
                case '16-bit integer'
                    DataType = 'int16';
                case '32-bit integer'
                    DataType = 'int32';
                otherwise
                    DataType = 'int16';
            end
            y = coder.nullcopy(zeros([obj.frameSize,obj.numberOfChannels],DataType));
            coder.ceval('MW_AudioRead',cstr(obj.deviceStr),obj.MW_dataType,coder.wref(y));
        end
        
        function close(obj)
            % Close audio device
            audioDirection = coder.opaque('MW_Audio_Direction_Type','MW_AUDIO_IN','HeaderFile','MW_alsa_audio.h');
            coder.ceval('MW_AudioClose',cstr(obj.deviceStr),audioDirection);
        end
          
    end
    
    methods (Access=protected)
        %% Common functions
        function setupImpl(obj)
            if coder.target('Rtw')
                switch obj.DataBitDepth
                    case '8-bit integer'
                        obj.MW_dataType = coder.opaque('MW_Audio_Data_Type','MW_AUDIO_8','HeaderFile','MW_alsa_audio.h');
                    case '16-bit integer'
                        obj.MW_dataType = coder.opaque('MW_Audio_Data_Type','MW_AUDIO_16','HeaderFile','MW_alsa_audio.h');
                    case '32-bit integer'
                        obj.MW_dataType = coder.opaque('MW_Audio_Data_Type','MW_AUDIO_32','HeaderFile','MW_alsa_audio.h');
                    otherwise
                        obj.MW_dataType = coder.opaque('MW_Audio_Data_Type','MW_AUDIO_16','HeaderFile','MW_alsa_audio.h');
                end
                obj.open;
            end
        end
        
        function y = stepImpl(obj)
            % Implement output.
            if coder.target('Rtw')
                y = readStream(obj);
            else
                y = int16(zeros(obj.frameSize,obj.numberOfChannels));
            end
        end
        
        function releaseImpl(obj)
            if coder.target('Rtw')
                close(obj);
            end
        end
    end
    
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        function num = getNumOutputsImpl(~)
            num = 1;
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(~,~)
            varargout{1} = true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout{1} = false;
        end
        
        function varargout = getOutputSizeImpl(obj)
            varargout{1} = [obj.frameSize,obj.numberOfChannels];
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            switch obj.DataBitDepth
                case '8-bit integer'
                    DataType = 'int8';
                case '16-bit integer'
                    DataType = 'int16';
                case '32-bit integer'
                    DataType = 'int32';
                otherwise
                    DataType = 'int16';
            end
            varargout{1} = DataType;
        end
        
        function st = getSampleTimeImpl(obj)
            st = coder.const(obj.frameSize/obj.sampleRateEnum);
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            %Icon display
            iconstr = ['Device: ',obj.deviceStr];
                 
            maskDisplayCmds = { ...
                ['color(''white'');', newline],...    % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline],... % Drawing mask layout of the block
                ['plot([0,0,0,0],[0,0,0,0]);', newline],...               
                ['color(''black'');', newline] ...
                ['text(50, 12,''' iconstr ''', ''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');',newline]...
                };
            
            labelSample = obj.blockPlatform;
            maskDisplayCmdsTarget = { ...
                ['color(''blue'');', newline],...
                ['text(96, 90, ''' labelSample ''', ''horizontalAlignment'', ''right'');', newline],...
                ['color(''black'');', newline],...
                ['image(''sound_sensor.gif'',''center'');', newline],...
                };
            maskDisplayCmds = [maskDisplayCmds maskDisplayCmdsTarget];
        end
        
    end
        
    methods (Static, Access=protected)
        
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
        function header = getHeaderImpl()
            MaskText = getString(message('linux:blockmask:AudioCaptureMask'));    
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','ALSA Audio Capture', ...
                'Text', MaskText);
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'Audio Capture';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                rootDir = realtime.internal.getLinuxRoot();
                buildInfo.addIncludePaths(fullfile(rootDir,'include'));
                buildInfo.addIncludeFiles('MW_alsa_audio.h');
                
                systemTargetFile = get_param(buildInfo.ModelName,'SystemTargetFile');
                if isequal(systemTargetFile,'ert.tlc')
                    buildInfo.addSourceFiles('MW_alsa_audio.c',fullfile(rootDir,'src'));
                    addLinkFlags(buildInfo,{'-lasound'},'SkipForSil');
                end
            end
        end
    end
end

%% Internal function
function str = cstr(str)
str = [str(:).', char(0)];
end


