classdef ServoBlock < raspi.internal.ServoBase ...
        & matlab.System ...
        & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency
    %SERVOBLOCK System object for driving a Servo motor.
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    properties (Nontunable)
        Pin = '4'
    end
    
    methods
        function obj = ServoBlock(varargin)
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
            obj.Hw = [];
        end
    end
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            obj.PinNumber = i_str2int(obj.Pin);
            initServo(obj);
        end
        
        function stepImpl(obj,degrees)
            % Ignore values outside [0,180]. Note that validateInputs method
            % guarantees that degrees is a numeric scalar value
            if (degrees >= 0) && (degrees <= 180)
                writePosition(obj,degrees);
            end
        end
        
        function releaseImpl(obj)
            % Initialize discrete-state properties.
            terminateServo(obj);
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
        
        function validateInputsImpl(~,degrees)
            if isempty(coder.target)
                % Run this always in Simulation
                validateattributes(degrees,{'numeric'},...
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
                'Title', 'Servo', ...
                'Text', 'Set the shaft position of a standard servo motor.', ...
                'ShowSourceLink', false);
        end
    end
    
    methods (Hidden, Static)
        function name = getDescriptiveName()
            name = 'Servo';
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