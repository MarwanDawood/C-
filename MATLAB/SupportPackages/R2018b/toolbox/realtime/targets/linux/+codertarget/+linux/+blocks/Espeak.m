classdef (StrictDefaults)Espeak < matlab.System ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    %
    %Espeak Converts text to speech.
    %
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    properties
        Pitch = 50           % Pitch (0 to 100)
    end
    
    properties (Nontunable)
        Options = ''       % Additional options for Espeak
    end
    
    properties (Access = private,Dependent)
        PitchStr
    end
    
    methods
        % Constructor
        function obj = Espeak(varargin)
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.Pitch(obj,value)
            validateattributes(value,{'numeric'},...
                {'scalar','integer','>=',1,'<=',100},'','Pitch');
            obj.Pitch = value;
        end
        
        function set.Options(obj,value)
            % Empty Options allowed
            if ~isempty(value) 
                validateattributes(value,{'char'},{'row'},'','Options')
            end
            obj.Options = value;
        end
        
        function ret = get.PitchStr(obj)
            if obj.Pitch == 100
                ret = '-p 100';
            else
                a = uint8(obj.Pitch/10);
                if  a > 0
                    ret = ['-p ' char(uint8('0')+a) char(uint8('0')+uint8(obj.Pitch-10*a))];
                else
                    ret = ['-p ' char(uint8('0')+uint8(obj.Pitch))];
                end
            end
        end
    end
    
    methods (Access=protected)        
        function stepImpl(obj,u)
            if ~isempty(coder.target)
                % void MW_ESPEAK_output(const char *text);
                coder.cinclude('MW_espeak.h');
                cmd = cString(['taskset 0xffff espeak --stdout "' u(:).' '" ' ...
                    obj.PitchStr ' ' obj.Options ' | taskset 0xffff aplay -f cd &> /dev/null &']);
                coder.ceval('MW_ESPEAK_output',cmd);
            end
        end
    end
    
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 1;
        end
        
        function num = getNumOutputsImpl(~)
            num = 0;
        end
        
        function icon = getIconImpl(~)
            % Define a string as the icon for the System block in Simulink.
            icon = 'Espeak';
        end    
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function validateInputsImpl(~,u)
            if isempty(coder.target)
                % Actually the input validation should be the following:
                validateattributes(u,{'uint8'},{},'','input');
            end
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
        function header = getHeaderImpl
            header = matlab.system.display.Header('codertarget.linux.blocks.Espeak', ...
                'ShowSourceLink', true, ...
                'Title', 'eSpeak Text to Speech', 'Text', ...
                sprintf(['Converts text to speech using eSpeak speech synthesizer.\n\n',...
                'The synthesized speech is output by the default audio device.\n\n',...
                'The input port accepts a uint8 array containing the ASCII text to be converted.']));
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'Espeak';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                tmp = fileparts(mfilename('fullpath'));
                rootDir = fileparts(fileparts(fileparts(tmp)));
                addIncludePaths(buildInfo,fullfile(rootDir,'include'));
                % Use the following API's to add include files, sources and
                % linker flags
                addIncludeFiles(buildInfo,'MW_espeak.h',...
                    fullfile(rootDir,'include'));
                systemTargetFile = get_param(buildInfo.ModelName,'SystemTargetFile');
                if isequal(systemTargetFile,'ert.tlc')
                    % Add the following when not in rapid-accel simulation
                    addSourceFiles(buildInfo,'MW_espeak.c',...
                    fullfile(rootDir,'src'));
                end
                %% Enable for debugging
                %addCompileFlags(buildInfo,{'-D_DEBUG=1'});
            end
        end
    end
end

function str = cString(str)
str = [str uint8(0)];
end

