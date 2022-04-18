classdef ServoBase < handle
    %ServoBase Codegen base class for servo devices.
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    properties (Hidden)
        PinNumber = uint32(0)
    end
    
    properties
        % Minimum pulse duration
        MinPulseDuration = 1000e-6  
        % Maximum pulse duration
        MaxPulseDuration = 2000e-6 
    end
    
    properties (Access = protected)
        Hw
        Initialized = false
    end
    
    methods (Hidden)
        %% Implicit assumption here is that Hw supports request/response 
        %% protocol
        function initServo(obj)
            coder.cinclude('MW_pigs.h');
            ret = int32(0);
            ret = coder.ceval('EXT_SERVO_init',obj.PinNumber);
            if ret == int32(0)
                obj.Initialized = true;
            else
                coder.ceval('printf',...
                    i_cstr('Unable to configure pin %u for servo pulse output.\n'),...
                    obj.PinNumber);
            end
        end
        
        function terminateServo(obj)
            % Note that if obj.Hw == [], obj.Initialized is never set to
            % true hence the initialization commands will never be executed
            if obj.Initialized
                coder.ceval('EXT_SERVO_terminate',uint32(real(obj.PinNumber)));
            end
        end
    end
    
    methods
        %% Implicit assumption here is that Hw supports request/response
        %% protocol
        function set.PinNumber(obj,value)
            obj.PinNumber = uint32(real(value));
        end
        
        function writePosition(obj,degrees)
            %writePosition Set servo position.
            %
            validateattributes(degrees,{'numeric'},...
                {'scalar','>=',0,'<=',180},'','degrees');
            if ~obj.Initialized
                initServo(obj);
            end
            coder.ceval('EXT_SERVO_write',uint32(real(obj.PinNumber)),...
                real(degrees),...
                real(1e6 * obj.MinPulseDuration),...
                real(1e6 * obj.MaxPulseDuration));
        end
    end
end

%% Internal functions
function str = i_cstr(str)
str = [str char(0)];
end
