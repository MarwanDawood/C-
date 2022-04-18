classdef pushbutton < handle
    %PUSHBUTTON Create a push button object.
    %   
    % obj = raspi.internal.pushbutton(pinNumber) creates an a push button object.
    % The input parameter pinNumber is the digital pin that the push button is
    % connected to.
    %
    % (obj) turns the relay on.
    %
    % off(obj) turns the relay off.
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        PinNumber
        LogicHighWhenPressed = true;
    end
    
    properties (Hidden)
        RaspiObj
    end
    
    methods
        function obj = pushbutton(raspiObj, pinNumber, logicHighWhenPressed)
            obj.RaspiObj = raspiObj;
            obj.PinNumber = pinNumber;
            if (nargin > 2)
                obj.LogicHighWhenPressed = logicHighWhenPressed;
            end
            configurePin(obj.RaspiObj, obj.PinNumber, 'DigitalInput');
        end
        
        function ret = pressed(obj)
            ret = obj.RaspiObj.readDigitalPin(obj.PinNumber);
            if ~obj.LogicHighWhenPressed
                ret = ~ret;
            end
        end
        
        function set.PinNumber(obj, value)
            validateattributes(value, {'numeric'}, {'scalar'}, ...
                '', 'PinNumber');
            obj.PinNumber = value;
        end
        
        function set.LogicHighWhenPressed(obj, value)
            validateattributes(value, {'numeric', 'logical'}, ...
                {'scalar'}, '', 'LogicHighWhenPressed');
            if isnumeric(value) && ~((value == 0) || (value == 1))
                error(message('raspi:utils:ExpectedLogicalValue', 'LogicHighWhenPressed'));
            end
            obj.LogicHighWhenPressed = value;
        end
    end
end

