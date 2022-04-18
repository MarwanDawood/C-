classdef ServoBase < handle
    %ServoBase Base class for servo devices.
    
    % Copyright 2015 The MathWorks, Inc.

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
    
    properties (Constant, Access = private)
        % Servo requests for simulation
        REQUEST_SERVO_INIT      = 2104
        REQUEST_SERVO_WRITE     = 2105
        REQUEST_SERVO_TERMINATE = 2106
    end
    
    methods (Hidden)
        %% Implicit assumption here is that Hw supports request/response 
        %% protocol
        function initServo(obj)
            if ~isempty(obj.Hw)
                sendRequest(obj.Hw, ...
                    obj.REQUEST_SERVO_INIT, ...
                    uint32(obj.PinNumber));
                recvResponse(obj.Hw);
                % recvResponse throws an error if initialization commands
                % fail
                obj.Initialized = true;
            end
        end
        
        function terminateServo(obj)
            % Note that if obj.Hw == [], obj.Initialized is never set to
            % true hence the initialization commands will never be executed
            if obj.Initialized
                sendRequest(obj.Hw, ...
                    obj.REQUEST_SERVO_TERMINATE, ...
                    uint32(obj.PinNumber));
                recvResponse(obj.Hw);
            end
        end
    end
    
    methods
        function writePosition(obj,degrees)
            %writePosition Set servo position.
            %
            validateattributes(degrees,{'numeric'},...
                {'scalar','>=',0,'<=',180},'','degrees');
            if ~isempty(obj.Hw)
                if ~obj.Initialized
                    initServo(obj);
                end
                sendRequest(obj.Hw, ...
                    obj.REQUEST_SERVO_WRITE, ...
                    uint32(obj.PinNumber), ...
                    degrees, ...
                    1e6 * obj.MinPulseDuration, ...
                    1e6 * obj.MaxPulseDuration);
                recvResponse(obj.Hw);
            end
        end
        
        function set.PinNumber(obj,value)
            validateattributes(value,{'numeric'},...
                {'scalar','nonnegative','integer'},'','PinNumber');
            obj.PinNumber = uint32(value);
        end
        
        function set.MinPulseDuration(obj,value)
            validateattributes(value,{'numeric'},...
                {'scalar','>=',500e-6,'<',1500e-6},'','MinPulseDuration');
            obj.MinPulseDuration = value;
        end
        
        function set.MaxPulseDuration(obj,value)
            validateattributes(value,{'numeric'},...
                {'scalar','>',1500e-6,'<=',2500e-6'},'','MaxPulseDuration');
            obj.MaxPulseDuration = value;
        end
    end
    
    methods (Access = private, Static)
        function name = matlabCodegenRedirect(~)
            name = 'raspi.internal.codegen.ServoBase';
        end
    end
end

