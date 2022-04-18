classdef PWMBase < handle
    %PWMBase Base class for PWM output.
    
    % Copyright 2015-2018 The MathWorks, Inc.
    
    properties (Constant, Access = protected)
        % Servo requests for simulation
        REQUEST_PWM_INIT      = 2100
        REQUEST_PWM_TERMINATE = 2101
        REQUEST_PWM_DUTYCYLE  = 2102
        REQUEST_PWM_FREQUENCY = 2103
    end
    
    methods (Hidden)
        %% Implicit assumption here is that Hw supports request/response
        %% protocol
        function initPWM(obj,pinNumber,frequency,initialDutyCycle)
            if isa(obj,'raspi.internal.raspiBase')
                sendRequest(obj,...
                    obj.REQUEST_PWM_INIT,...
                    uint32(pinNumber),...
                    uint32(frequency),...
                    double(initialDutyCycle));
                recvResponse(obj);
            end
        end
        
        function terminatePWM(obj,pinNumber)
            % Note that if obj == [], obj.Initialized is never set to
            % true hence the initialization commands will never be executed
            if isa(obj,'raspi.internal.raspiBase')
                sendRequest(obj, ...
                    obj.REQUEST_PWM_TERMINATE, ...
                    uint32(pinNumber));
                recvResponse(obj);
            end
        end
    end
    
    methods
        function setPWMDutyCycle(obj,pinNumber,dutyCycle)
            validateattributes(dutyCycle,{'numeric'},...
                {'scalar','real','>=',0,'<=',1},'','dutyCycle');
            if isa(obj,'raspi.internal.raspiBase')
                sendRequest(obj, ...
                    obj.REQUEST_PWM_DUTYCYLE, ...
                    uint32(pinNumber), ...
                    double(dutyCycle));
                recvResponse(obj);
            end
        end
        
        function setPWMFrequency(obj,pinNumber,frequency)
            validateattributes(frequency,{'numeric'},...
                {'scalar','integer','positive'},'','frequency');
            if isa(obj,'raspi.internal.raspiBase')
                sendRequest(obj, ...
                    obj.REQUEST_PWM_FREQUENCY, ...
                    uint32(pinNumber), ...
                    uint32(frequency));
                recvResponse(obj);
            end
        end
    end
    
    methods (Access = private, Static)
        function name = matlabCodegenRedirect(~)
            name = 'raspi.internal.codegen.PWMBase';
        end
    end
end

