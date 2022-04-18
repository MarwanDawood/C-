classdef (StrictDefaults)DigitalRead < realtime.internal.SourceSampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    %
    % Read the logical state of a digital input pin.
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        PinNumber = 4  
    end
    
    methods
        % Constructor
        function obj = DigitalRead(varargin) 
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
        %% Common functions
        function setupImpl(obj)
            % Does nothing in code generation
            if ~isempty(coder.target)
                coder.cinclude('MW_gpio.h');
                % void MW_gpioInit(const uint32_T pin, const boolean_T direction)
                coder.ceval('MW_gpioInit',uint32(obj.PinNumber),false);
            end
        end
        
        function y = stepImpl(obj)
            % Implement output.
            y = false;
            if ~isempty(coder.target)
                % boolean_T MW_gpioRead(const uint32_T pin)
                y = coder.ceval('MW_gpioRead',uint32(obj.PinNumber));
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
        
        function varargout = getOutputSizeImpl(~)
            varargout{1} = [1,1];
        end
        
        function varargout = getOutputDataTypeImpl(~)
            varargout{1} = 'logical';
        end
        
        function icon = getIconImpl(~)
            % Define a string as the icon for the System block in Simulink.
            icon = 'Digital Read';
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
            name = 'Digital Read';
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

