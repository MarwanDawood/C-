classdef GPIOCodegen < matlab.System ...
        & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency
    %GPIOCodegen System object representing GPIO operation of Raspi
    
    % Copyright 2018 The MathWorks, Inc.
    %#codegen
    
    properties (Access = private)
        PinNumber = uint32(0)
    end
    
    methods
        function obj = GPIOCodegen(varargin)
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.PinNumber(obj,value)
            obj.PinNumber = uint32(real(value));
        end
    end
    
    methods (Hidden)
        function ret = initGPIO(~,pinNumber,direction)
            ret = int32(0);
            ret = coder.ceval('EXT_GPIO_init',uint32(real(pinNumber)),...
                uint8(real(direction)));
            if ret ~= 0
                %Error in settion GPIO
                coder.ceval('printf',...
                    i_cstr('Unable to configure pin %u \n'),...
                    uint32(real(pinNumber)));
            end
        end
        
        function writeGPIO(~,pinNumber,value)
            ret = int32(0);
            ret = coder.ceval('EXT_GPIO_write',uint32(real(pinNumber)),uint8(value));
            if ret ~= 0
                %Error in settion GPIO
                coder.ceval('printf',...
                    i_cstr('Unable to write pin %u \n'),...
                    uint32(real(pinNumber)));
            end
        end
        
        function value = readGPIO(~,pinNumber)
            value = false;
            numericVal = uint8(0);
            ret = int32(0);
            ret = coder.ceval('EXT_GPIO_read',uint32(real(pinNumber)),coder.wref(numericVal));
            if ret ~= 0
                %Error in settion GPIO
                coder.ceval('printf',...
                    i_cstr('Error in reading pin %u \n'),...
                    uint32(real(pinNumber)));
            end
            
            if numericVal
                value = true;
            end
            
        end
        
        function ret = terminateGPIO(~,pinNumber)
            ret = int32(0);
            ret = coder.ceval('EXT_GPIO_terminate',uint32(real(pinNumber)));
            if ret ~= 0
                % Error is releasing GPIO 
                coder.ceval('printf',...
                    i_cstr('Error in unsetting GPIO pin %u \n'),...
                    uint32(real(pinNumber)));
            end
        end
    end
    
    
    methods (Hidden, Static)
        function name = getDescriptiveName()
            name = 'GPIO';
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
                addIncludeFiles(buildInfo,'GPIO.h',rootDir);
                addIncludeFiles(buildInfo,'devices.h',rootDir);
                addIncludeFiles(buildInfo,'common.h',rootDir);
                addSourceFiles(buildInfo,'devices.c',rootDir);
                addSourceFiles(buildInfo,'GPIO.c',rootDir);
            end
        end
    end
end

%% Internal functions
function str = i_cstr(str)
str = [str char(0)];
end

% LocalWords:  GPIO Raspi settion unsetting fullpath
