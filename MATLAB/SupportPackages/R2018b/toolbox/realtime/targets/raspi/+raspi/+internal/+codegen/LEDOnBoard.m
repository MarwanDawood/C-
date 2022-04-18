classdef LEDOnBoard < matlab.System ...
        & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency
    %LEDOnBoard System object to control on board led of raspberry pi
    
    % Copyright 2018 The MathWorks, Inc.
    %#codegen
    
    properties
        led = uint32(0);
    end
    
    methods
        function obj = LEDOnBoard(varargin)
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.led(obj,value)
            validateattributes(value,{'char','string'},...
                {'row','nonempty'},'','led');
            switch value
                case 'led0'
                    obj.led = uint32(0);
                case 'led1'
                    obj.led = uint32(1);
                otherwise 
                    obj.led = uint32(0);
            end
        end
    end
    
    methods (Hidden)
        function configureLED(obj,trigger)
            % TODO
            % Check if validation of input params are required.
            coder.ceval('EXT_LED_setTrigger',obj.led,i_cstr(trigger));
        end
        
        function writeLED(obj, value)
            validateattributes(value,{'numeric','logical'}, ...
                {'scalar'},'','led value');
            
            if isnumeric(value) && ~((value == 0) || (value == 1))
                coder.ceval('perror','Invalid LED value. LED value must be a logical value (true or false).');
            end
            
            % Make sure that led trigger is set to none.
            trigger = 'none';
            configureLED(obj,trigger);
            
            % Write led value.
            coder.ceval('EXT_LED_write',obj.led, uint8(value));
        end

    end
    
    
    methods (Hidden, Static)
        function name = getDescriptiveName()
            name = 'LEDOnBoard';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Digital I/O interface
                rootDir = fileparts(strtok(mfilename('fullpath'), '+'));
                srcDir = fullfile(rootDir,'server');
                addIncludePaths(buildInfo,srcDir);
                addIncludeFiles(buildInfo,'LED.h',srcDir);
                addIncludeFiles(buildInfo,'devices.h',srcDir);
                addIncludeFiles(buildInfo,'common.h',srcDir);
                addSourceFiles(buildInfo,'devices.c',srcDir);
                addSourceFiles(buildInfo,'LED.c',srcDir);
            end
        end
    end
end

%% Internal functions
function str = i_cstr(str)
str = [str char(0)];
end

% LocalWords:  perror fullpath
