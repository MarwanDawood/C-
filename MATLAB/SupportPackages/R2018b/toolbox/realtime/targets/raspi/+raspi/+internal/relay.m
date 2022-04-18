classdef relay < handle
    %RELAY Create a relay object.
    %   
    % relayObj = raspi.internal.relay(pinNumber) creates a relay object.
    % The input parameter pinNumber is the digital pin that the relay is
    % connected to.
    %
    % on(relayObj) turns the relay on.
    %
    % off(relayObj) turns the relay off.
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        PinNumber
    end
    
    properties (Hidden)
        RaspiObj
    end
    
    methods
        function obj = relay(raspiObj, pinNumber)
            obj.RaspiObj = raspiObj; 
            obj.PinNumber = pinNumber;
            configurePin(obj.RaspiObj, obj.PinNumber, 'DigitalOutput');
        end
        
        function on(obj)
            obj.RaspiObj.writeDigitalPin(obj.PinNumber, 0);
        end
        
        function off(obj)
            obj.RaspiObj.writeDigitalPin(obj.PinNumber, 1);
        end
        
        function set.PinNumber(obj, value)
            validateattributes(value, {'numeric'}, {'scalar'}, ...
                '', 'PinNumber');
            obj.PinNumber = value;
        end
    end
end

