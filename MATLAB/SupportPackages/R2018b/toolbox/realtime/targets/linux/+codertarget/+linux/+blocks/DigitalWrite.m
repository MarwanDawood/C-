classdef (StrictDefaults)DigitalWrite < matlab.System ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    %
    % Set the logical state of a digital output pin.
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        PinNumber = 17
    end
    
    methods
        % Constructor
        function obj = DigitalWrite(varargin)
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.PinNumber(obj,value)
            % https://www.kernel.org/doc/Documentation/gpio/gpio-legacy.txt
            validateattributes(value,...
                {'numeric'},...
                {'real','nonnegative','integer','scalar'},...
                '', ...
                'PinNumber');
            obj.PinNumber = value;
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj)
            % Does nothing in code generation
            if ~isempty(coder.target)
                coder.cinclude('MW_gpio.h');
                % void MW_gpioInit(const uint32_T pin, const boolean_T direction)
                coder.ceval('MW_gpioInit',uint32(obj.PinNumber),true);
            end
        end
        
        function stepImpl(obj,u)
            if ~isempty(coder.target)
                % void MW_gpioWrite(const uint32_T pin, const boolean_T value)
                coder.ceval('MW_gpioWrite',uint32(obj.PinNumber),uint8(u));
            end
        end
        
        function releaseImpl(obj)
            if ~isempty(coder.target)
                % void MW_gpioTerminate(const uint32_T pin)
                coder.ceval('MW_gpioTerminate',uint32(obj.PinNumber));
            end
        end
    end
    
    methods (Access=protected)
        %% Define input properties
        function num = getNumInputsImpl(~)
            num = 1;
        end
        
        function num = getNumOutputsImpl(~)
            num = 0;
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputFixedSizeImpl(~,~)
            varargout{1} = true;
        end
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function validateInputsImpl(~, u)
            if isempty(coder.target)
                % Actually the input validation should be the following:
                validateattributes(u,{'numeric','logical'},{'scalar','binary'},'','u');
            end
        end
        
        function icon = getIconImpl(~)
            % Define a string as the icon for the System block in Simulink.
            icon = 'Digital Write';
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
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'Digital Write';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                tmp = fileparts(mfilename('fullpath'));
                rootDir = fileparts(fileparts(fileparts(tmp)));
                buildInfo.addIncludePaths(fullfile(rootDir,'include'));
                buildInfo.addIncludeFiles('MW_gpio.h',...
                    fullfile(rootDir,'include'));
                systemTargetFile = get_param(buildInfo.ModelName,'SystemTargetFile');
                if isequal(systemTargetFile,'ert.tlc')
                    % Add the following when not in rapid-accel simulation
                    buildInfo.addSourceFiles('MW_gpio.c',...
                    fullfile(rootDir,'src'));
                end
            end
        end
    end
end
