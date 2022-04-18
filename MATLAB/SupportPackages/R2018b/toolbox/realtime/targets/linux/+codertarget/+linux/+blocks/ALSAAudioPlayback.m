classdef ALSAAudioPlayback <  matlab.System & ...
        matlab.system.mixin.internal.CustomIcon & ...
        coder.ExternalDependency &...
        matlab.system.mixin.Propagates 
    
    %AUDIOPLAYBACK Playback sound through an audio card.
    
    % Copyright 2016-2017 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    properties (Nontunable)
        % deviceStr Device name
        deviceStr = 'hw:0,0';
        
        % sampleRateEnum Audio sampling frequency (Hz)
        sampleRateEnum = 44100
        % queueDuration Queue duration (seconds)
        queueDuration = 0.5
        % Block platform
        blockPlatform = 'RASPBERRYPI';
    end
    
    properties (Hidden,Nontunable)
        % Datatype Device Bit depth
        DataType = '16-bit integer';
        MW_dataType
    end
    
    properties (Constant, Hidden)
        DataTypeSet = matlab.system.StringSet({'8-bit integer', '16-bit integer', '32-bit integer'});
    end
    
    methods
        % Constructor
        function obj = AudioPlayback(varargin)
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
                {'real','positive','scalar','integer','>=',1,'nonnan'},'','Audio sampling frequency');
            obj.sampleRateEnum = value;
        end

        function open(obj,samplesPerFrame,numberOfChannels)
            %% Open audio device
            %
            coder.cinclude('MW_alsa_audio.h');
            coder.ceval('audioPlaybackInit',...
                cstr(obj.deviceStr),...
                obj.sampleRateEnum,...
                numberOfChannels,...
                obj.queueDuration,...
                samplesPerFrame,...
                obj.MW_dataType);
        end
        
        function writeStream(obj,u)
            %void MW_audio_write(const uint8_T *device, void *u)
            coder.ceval('MW_AudioWrite',cstr(obj.deviceStr),obj.MW_dataType,coder.rref(u));
        end
        
        function close(obj)
            % Close audio device 
            audioDirection = coder.opaque('MW_Audio_Direction_Type','MW_AUDIO_OUT','HeaderFile','MW_alsa_audio.h');
            coder.ceval('MW_AudioClose',cstr(obj.deviceStr),audioDirection);
        end
        
    end
    
    methods (Access = protected)
        
        function setupImpl(obj,varargin)
            samplesPerFrame = size(varargin{1},1);
            numberOfChannels = size(varargin{1},2);
            inputDataType = class(varargin{1});
            switch inputDataType
                case 'int8'
                    obj.MW_dataType = coder.opaque('MW_Audio_Data_Type','MW_AUDIO_8','HeaderFile','MW_alsa_audio.h');
                case 'int16'
                    obj.MW_dataType = coder.opaque('MW_Audio_Data_Type','MW_AUDIO_16','HeaderFile','MW_alsa_audio.h');
                case 'int32'
                    obj.MW_dataType = coder.opaque('MW_Audio_Data_Type','MW_AUDIO_32','HeaderFile','MW_alsa_audio.h');
                otherwise
                    obj.MW_dataType = coder.opaque('MW_Audio_Data_Type','MW_AUDIO_16','HeaderFile','MW_alsa_audio.h');
            end
            if coder.target('Rtw')
                open(obj,samplesPerFrame,numberOfChannels);
            end
        end
        
        function stepImpl(obj,varargin)
            if coder.target('Rtw')
                %codgen
                writeStream(obj,varargin{1});
            end
        end
        
        function releaseImpl(obj)
            if coder.target('Rtw')
                close(obj);
            end
        end
    end
    
    methods (Access = protected)   
        function num = getNumInputsImpl(~)
            num = 1;
        end
        
        function num = getNumOutputsImpl(~)
            num = 0;
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
                ['image(''speaker.gif'',''center'');', newline],...
                };
            maskDisplayCmds = [maskDisplayCmds maskDisplayCmdsTarget];
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputComplexImpl(~)
            varargout{1} = false;
        end
        
        function validateInputsImpl(~,varargin)
            coder.extrinsic('ver');
            if ~isempty(coder.target)
                % Audio playback only
                validateattributes(varargin{1},{'int8','int16','int32'},{'2d'},'',...
                    'signal input');
            else
                numChannels = size(varargin{1},2);
                if numChannels > 2
                    installedProducts = ver;
                    productNames = {installedProducts.Name};
                    result = ismember('Audio System Toolbox', productNames);
                    if result
                        % Check AST license
                        result = builtin('license', 'checkout', 'Audio_System_Toolbox');
                    end
                    if ~result
                        error(message('linux:utils:ASTLicenseCheckFailed'));
                    end
                end
            end
        end
    end
    
    methods(Static, Access = protected)
        
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
        function header = getHeaderImpl()
            MaskText = getString(message('linux:blockmask:AudioPlaybackMask'));
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','ALSA Audio Playback', ...
                'Text',MaskText); 
        end
        
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'Audio Playback';
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
%[EOF]