classdef PWMBlock < raspi.internal.PWMBase ...
        & matlab.System ...
        & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency
    %PWMBLOCK System object representing PWM block.
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    properties (Nontunable)
        Pin = '4'
        Frequency = '500'
    end
    
    properties (Access = private)
        PinNumber = uint32(0)
    end
    
    properties (Constant, Hidden)
        % This is a string representation of raspi.AVAILABLE_PWM_FREQUENCY
        FrequencySet = matlab.system.StringSet({'8000','4000','2000',...
            '1600','1000','800','500','400','320',...
            '250','200','160','100','80','50','40','20','10'});
    end
    
    methods
        function obj = PWMBlock(varargin)
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.PinNumber(obj,value)
            obj.PinNumber = uint32(real(value));
        end
    end
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            obj.PinNumber = i_str2int(obj.Pin);
            initPWM(obj,obj.PinNumber,i_str2int(obj.Frequency),0);
        end
        
        function stepImpl(obj,dutyCycle)
            % Ignore values outside [0,1]. Note that validateInputs method
            % guarantees that dutyCycle is a numeric scalar value
            if (dutyCycle >= 0) && (dutyCycle <= 1.0)
                setPWMDutyCycle(obj,obj.PinNumber,dutyCycle);
            end
        end
        
        function releaseImpl(obj)
            % Initialize discrete-state properties.
            terminatePWM(obj,obj.PinNumber);
        end
        
        function N = getNumInputsImpl(~)
            % Specify number of System inputs
            N = 1;
        end
        
        function N = getNumOutputsImpl(~)
            % Specify number of System outputs
            N = 0;
        end
    end
    
    %% Input properties for Simulink codegen
    methods (Access=protected)
        function flag = isInputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputFixedSizeImpl(~,~)
            varargout{1} = true;
        end
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputComplexImpl(~)
            varargout{1} = false;
        end
        
        function validateInputsImpl(~,dutyCyle)
            if isempty(coder.target)
                % Run this always in Simulation
                validateattributes(dutyCyle,{'numeric'},...
                    {'scalar','finite'},'','input');
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
    end
    
    methods(Static, Access = protected)
        % Note that this is ignored for the mask-on-mask
        function header = getHeaderImpl
            %getHeaderImpl Create mask header
            %   This only has an effect on the base mask.
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', 'PWM', ...
                'Text', 'Generate square waveform on the specified output pin.', ...
                'ShowSourceLink', false);
        end
    end
    
    methods (Hidden, Static)
       function name = getDescriptiveName()
            name = 'PWM';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Digital I/O interface
                curDir = fileparts(mfilename('fullpath'));
                serverDir = fileparts(fileparts(curDir));
                rootDir = fullfile(serverDir,'server');
                addIncludePaths(buildInfo,rootDir);
                addIncludeFiles(buildInfo,'MW_pigs.h',rootDir);
                addIncludeFiles(buildInfo,'system.h',rootDir);
                addIncludeFiles(buildInfo,'common.h',rootDir);
                addSourceFiles(buildInfo,'MW_pigs.c',rootDir);
                addSourceFiles(buildInfo,'system.c',rootDir);
            end
        end
    end
end

function num = i_str2int(str)
num = uint32(0);
zero = uint32('0');
for k = 1:numel(str)
    num = 10 * num + uint32(str(k))-zero;
end
end