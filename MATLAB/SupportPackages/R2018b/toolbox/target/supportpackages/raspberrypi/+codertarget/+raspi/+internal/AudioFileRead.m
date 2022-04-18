classdef AudioFileRead < matlab.System ...
        & matlab.system.mixin.internal.SampleTime ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.internal.CustomIcon ...
        & coder.ExternalDependency
    
    % AudioFileRead System object that outputs audio data from an audio
    % file.
    
    % Copyright 2017-2018 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
     
    % Mask parameters
    properties (Nontunable)
        %Samples per audio channel(N)
        SamplesPerFrame = 4410;   
        % Number of times to play file
        PlayCount = Inf;        
        %File name
        FileName = 'guitartune.wav';         
    end
    
    properties (Nontunable,Logical)
        %Output end of file indicator
        OutputEOFIndicator = false;
    end    
    
    properties (Nontunable, Hidden)
        BlockPlatform = 'RaspberryPi';
    end
    
    % Info properties
    properties (Access = private, Nontunable)
        NumChannels = uint32(1);
        SampleRate = uint32(44100);
        BitsPerSample = uint32(16);
        ReadCount = 1*4410;
        SampleTime = 0.1; %Derived from the audio file (SamplesPerFrame/SampleRate)
        Afr
    end
    
    % Private variables
    properties (Access = private)
        SoxFileHandle
        SoxInitialized = false;
        LoopCount = 0;
    end
    
    % Constant
    properties (Constant, Hidden)
        SupportedFileTypes = {'.wav', '.mp3', '.aiff', '.aif', '.aifc', '.au','.ogg'};
    end
    
    methods
        % Constructor
        function obj = AudioFileRead(varargin)
            %This would allow the code generation to proceed with the
            %p-files in the installed location of the support package.
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:});
        end 
        
        % FileName Setter - update object properties
        function set.FileName(obj, name)
            coder.extrinsic('audioinfo');
            coder.extrinsic('codertarget.raspi.internal.resolveFile');
            if isempty(coder.target)
                validateattributes(name,{'char'},{'row','nonempty'},'','FileName');
                [~,~,fExt] = fileparts(name);
                if ~ismember(fExt,obj.SupportedFileTypes)
                    error('raspi:utils:InvalidAudioFile',...
                        'Audio file format not supported. Supported audio file types are %s',obj.SupportedFileTypes);
                end
            end
            obj.FileName = name;

            % Set derived parameters
            rf = coder.const(codertarget.raspi.internal.resolveFile(obj.FileName));
            info = coder.const(feval('audioinfo',rf));
            obj.NumChannels = info.NumChannels;
            obj.SampleRate = info.SampleRate;
            obj.SampleTime = coder.const(obj.SamplesPerFrame/info.SampleRate);
        end
        
        function set.SamplesPerFrame(obj,value)
            validateattributes(value,{'numeric'},...
                {'scalar','integer','>=',1,'nonnan'},'','SamplesPerFrame');
            obj.SamplesPerFrame = value;
        end
        
        function set.PlayCount(obj,value)
            if ~isinf(value)
                validateattributes(value,{'numeric'},...
                    {'scalar','integer','>=',1,'nonnan'},'','PlayCount');
            end
            obj.PlayCount = value;
        end     
    end
    
    methods(Access = protected)
        %% Common functions
        function setupImpl(obj)
            obj.ReadCount = obj.SamplesPerFrame * obj.NumChannels;
            if isinf(obj.PlayCount)
                obj.LoopCount = 0;
            else
                obj.LoopCount = obj.PlayCount;
            end      
            
            % Resolve the full path name of the audio file
            rf = coder.const(feval('codertarget.raspi.internal.resolveFile',obj.FileName));
            if coder.target('Rtw')
                coder.updateBuildInfo('addNonBuildFiles',rf);
                % This is the full path name of the audio file on remote file
                remoteFileName = coder.const(loc_getRemoteFileName(rf));
                obj.SoxFileHandle = coder.opaque('sox_format_t *','NULL','HeaderFile','MW_sox_audio_reader.h');
                nulHandle = obj.SoxFileHandle;
                obj.SoxFileHandle = coder.ceval('MW_sox_init',cString(remoteFileName));
                if obj.SoxFileHandle ~= nulHandle
                    obj.SoxInitialized = true;
                end
            else
                % If DST license, use dsp.AudioFileReader to simulate
                if license('test', 'Signal_Blocks')
                    obj.Afr = dsp.AudioFileReader(rf);
                    obj.Afr.OutputDataType = 'int16';
                    obj.Afr.PlayCount = obj.PlayCount;
                    obj.Afr.SamplesPerFrame = obj.SamplesPerFrame;
                end
            end
        end
        
        function [y, eoa] = stepImpl(obj)
            y = coder.nullcopy(...
                zeros([obj.SamplesPerFrame,obj.NumChannels],'int16'));
            eoa = true;
            playFlag = isinf(obj.PlayCount) || (obj.LoopCount > 0);
            if coder.target('Rtw')         
                if obj.SoxInitialized && playFlag
                    buf = coder.nullcopy(...
                        zeros([1, obj.ReadCount],'int32'));  
                    hsox = obj.SoxFileHandle;
                    eoa = coder.ceval('MW_sox_read',...
                        coder.ref(hsox),...
                        coder.wref(buf),...
                        obj.ReadCount);
                    if eoa
                        %eoa logic
                        obj.SoxFileHandle = hsox;
                        obj.LoopCount = obj.LoopCount - 1;
                    end
                    bufTmp = cast(bitshift(buf, -16),'int16');
                    y = reshape(bufTmp,[obj.NumChannels obj.SamplesPerFrame])';
                else
                    y = zeros([obj.SamplesPerFrame,obj.NumChannels],'int16');
                end             
            else
                % If DST license, use dsp.AudioFileReader to simulate
                if license('test', 'Signal_Blocks') && playFlag
                    [y, eoa] = step(obj.Afr);
                    if eoa
                       obj.LoopCount = obj.LoopCount - 1;
                    end
                end
            end
        end        
        
        function releaseImpl(obj)
            if coder.target('Rtw')
                coder.ceval('MW_sox_terminate',obj.SoxFileHandle);
            else
                % If DST license, use dsp.AudioFileReader to simulate
                if license('test', 'Signal_Blocks')
                     release(obj.Afr);
                end
            end
        end
        
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            %Icon display
            resolvedFileName = coder.const(codertarget.raspi.internal.resolveFile(obj.FileName));
            [~, fName, fExt] = fileparts(resolvedFileName);
            info = audioinfo(resolvedFileName);
            obj.NumChannels = info.NumChannels;
            obj.SampleRate = info.SampleRate;            
            if obj.NumChannels == 1
                iconstr = [sprintf('%s',[fName,fExt]),'\n', sprintf('%d Hz, ',obj.SampleRate), sprintf('mono')];
            elseif obj.NumChannels == 2               
                iconstr = [sprintf('%s',[fName,fExt]),'\n', sprintf('%d Hz, ',obj.SampleRate), sprintf('stereo')];
            else              
                iconstr = [sprintf('%s',[fName,fExt]),'\n', sprintf('%d Hz, ',obj.SampleRate), sprintf('%d Channels',obj.NumChannels)];
            end
                 
            maskDisplayCmds = { ...
                ['color(''white'');', newline],...    % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline],... % Drawing mask layout of the block
                ['plot([0,0,0,0],[0,0,0,0]);', newline],...               
                ['color(''black'');', newline] ...
                ['text(50, 50,''' iconstr ''', ''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');',newline]...
                };
            
            if obj.OutputEOFIndicator
                portLabels = { ...
                    ['port_label(''output'',1,''Audio'');', newline],...
                    ['port_label(''output'',2,''EOF'');', newline]...
                    };
                maskDisplayCmds = [maskDisplayCmds,portLabels];
            end

            
            labelSample = 'RASPBERRYPI';
            maskDisplayCmdsTarget = { ...
                ['color(''blue'');', newline],...
                ['text(96, 90, ''' labelSample ''', ''horizontalAlignment'', ''right'');', newline],...
                };
            maskDisplayCmds = [maskDisplayCmds maskDisplayCmdsTarget];
        end
        
        function num = getNumOutputsImpl(obj)
            if obj.OutputEOFIndicator
                num = 2;
            else
                num = 1;
            end
        end
        
        function out = getNumInputsImpl(~)
            out = 0;
        end
        
        function varargout = getOutputNamesImpl(obj)
            varargout{1} = ' ';
            if obj.OutputEOFIndicator
                varargout{1} = 'Audio';
                varargout{2} = 'EOF';
            end
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(obj,~)
            varargout{1} = true;
            if obj.OutputEOFIndicator
                varargout{2} = true;
            end
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(obj)
            varargout{1} = false;
            if obj.OutputEOFIndicator
                varargout{2} = false;
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            varargout{1} = double([obj.SamplesPerFrame,obj.NumChannels]);
            if obj.OutputEOFIndicator
                varargout{2} = [1,1];
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            varargout{1} = 'int16';
            if obj.OutputEOFIndicator
                varargout{2} = 'logical';
            end
        end
        
        function st = getSampleTimeImpl(obj)
            st = obj.SampleTime;
        end
    end
    
    methods(Static, Access = protected)
        %% Simulink customization functions
        function header = getHeaderImpl
            % Define header panel for System block dialog
            titleDisp = getString(message('raspberrypi:blockmask:AudioFileReadMaskTitle'));
            textDisp = getString(message('raspberrypi:blockmask:AudioFileReadMaskDescription'));
            header = matlab.system.display.Header(...
                'Title',titleDisp,...
                'Text', textDisp,...
                'ShowSourceLink', false);
        end
        
        function simMode = getSimulateUsingImpl
            % Return only allowed simulation mode in System block dialog
            simMode = 'Interpreted execution';
        end
        
        function flag = showSimulateUsingImpl
            % Return false if simulation mode hidden in System block dialog
            flag = false;
        end
    end
    
    methods (Static)s
        function name = getDescriptiveName()
            name = 'Audio File Read';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                spkgRootDir = codertarget.raspi.internal.getSpPkgRootDir;
                addIncludePaths(buildInfo, fullfile(spkgRootDir, 'include'));
                addIncludeFiles(buildInfo, 'MW_sox_audio_reader.h');
                systemTargetFile = get_param(buildInfo.ModelName,'SystemTargetFile');
                if isequal(systemTargetFile,'ert.tlc')
                    addSourcePaths(buildInfo, fullfile(spkgRootDir, 'src'));
                    addSourceFiles(buildInfo, 'MW_sox_audio_reader.c', fullfile(spkgRootDir, 'src'), 'BlockModules');
                    addLinkFlags(buildInfo,'-lsox');
                end                
            end
        end  
    end
end

% Local functions
function str = cString(str)
str = [str uint8(0)];
end

function ret = loc_getRemoteFileName(resolvedFileName)
targetWorkspaceDir = coder.const(feval('codertarget.raspi.getRemoteBuildDir'));
ret = coder.const(feval('codertarget.raspi.internal.fullLnxFile',targetWorkspaceDir,resolvedFileName));
ret = coder.const(feval('codertarget.raspi.internal.w2l',ret));
end


