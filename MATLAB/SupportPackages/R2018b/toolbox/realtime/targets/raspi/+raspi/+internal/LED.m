classdef LED < handle
    %LED Create an LED object.
    %   
    % obj = raspi.internal.LED(pinNumber) creates an LED object.
    % The input parameter pinNumber is the digital pin that the LED is
    % connected to.
    %
    % on(obj) turns the relay on.
    %
    % off(obj) turns the relay off.
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        PinNumber
    end
    
    properties (Hidden)
        RaspiObj
    end
    
    methods
        function obj = LED(raspiObj, pinNumber)
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

