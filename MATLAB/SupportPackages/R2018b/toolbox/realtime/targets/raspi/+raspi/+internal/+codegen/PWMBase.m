classdef PWMBase < handle
    %PWMBase Codegen base class for PWM output.
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    
    methods (Hidden)
        %% Implicit assumption here is that Hw supports request/response
        %% protocol
        function ret = initPWM(~,pinNumber,frequency,initialDutyCycle)
            coder.cinclude('MW_pigs.h');
            ret = int32(0);
            ret = coder.ceval('EXT_PWM_init',uint32(real(pinNumber)),...
                uint32(real(frequency)),double(real(initialDutyCycle)));
            if ret ~= 0
                % transition to fprintf
                coder.ceval('printf',...
                    i_cstr('Unable to configure pin %u for PWM output.\n'),...
                    uint32(real(pinNumber)));
            end
        end
        
        function ret = terminatePWM(~,pinNumber)
            % Note that if obj == [], obj.Initialized is never set to
            % true hence the initialization commands will never be executed
            ret = int32(0);
            ret = coder.ceval('EXT_PWM_terminate',uint32(real(pinNumber)));
        end
    end
    
    methods
        function setPWMDutyCycle(~,pinNumber,dutyCycle)
            validateattributes(dutyCycle,{'numeric'},...
                {'scalar','>=',0,'<=',1},'','dutyCycle');
            coder.ceval('EXT_PWM_setDutyCycle',uint32(real(pinNumber)),...
                double(real(dutyCycle)));
        end
        
        function setPWMFrequency(~,pinNumber,frequency)
            validateattributes(frequency,{'numeric'},...
                {'scalar','positive'},'','frequency');
            coder.ceval('EXT_PWM_setFrequency',uint32(real(pinNumber)),...
                uint32(real(frequency)));
        end
    end
end

%% Internal functions
function str = i_cstr(str)
str = [str char(0)];
end

