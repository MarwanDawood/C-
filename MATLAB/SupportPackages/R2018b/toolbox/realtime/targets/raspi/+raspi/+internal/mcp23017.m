classdef mcp23017 < handle
    %MCP23017 Base class for MCP23017 I/O expander.
    %   
    % mcp = raspi.internal.mcp23017(bus, address) creates an MCP23017
    % object. All digital I/O ports are configured as inputs initially.
    %
    % readDigitalPin(mcp, pin) reads the logical value of a pin. If the pin
    % was previously configured as 'output', you must re-configure the pin
    % as 'input' before you read from the pin.
    %
    % writeDigitalPin(mcp, pin, value) writes the logical value to a pin.
    % If the pin was previously configured as 'input', you must
    % re-configure the pin as 'output' before you write to the pin.
    %
    % configurePin(mcp, pin, pinMode) configures pin as either
    % 'input' or 'output'.
    
    % Copyright 2013-2016 The MathWorks, Inc.
    
    properties 
        AvailableDigitalPins = 0:15;
    end
    
    properties (Access = private)
        i2cObj
        DigitalPin
    end
    
    properties (Constant, Hidden)
        % These are from the data sheet
        % http://ww1.microchip.com/downloads/en/devicedoc/21952b.pdf
        IODIRA = hex2dec('00');
        IODIRB = hex2dec('01');
        GPPUA  = hex2dec('0C');
        GPPUB  = hex2dec('0D');
        GPIOA  = hex2dec('12');
        GPIOB  = hex2dec('13');
        OLATA  = hex2dec('14');
        OLATB  = hex2dec('15');
        
        %% Direction
        GPIO_OUTPUT = 0;
        GPIO_INPUT  = 1;
        GPIO_PULLUP = 3;
    end
    
    methods
        function obj = mcp23017(raspiObj, bus, address)
            obj.i2cObj = i2cdev(raspiObj, bus, address);
            
            % Set all ports to input initially
            obj.i2cObj.writeRegister(obj.IODIRA, hex2dec('FF'));
            obj.i2cObj.writeRegister(obj.IODIRB, hex2dec('FF'));
            
            % Set pull-ups to none
            obj.i2cObj.writeRegister(obj.GPPUA, hex2dec('00'));
            obj.i2cObj.writeRegister(obj.GPPUB, hex2dec('00'));
            
            % Cache pin direction
            for pin = obj.AvailableDigitalPins
                pinName = obj.getPinName(pin);
                obj.DigitalPin.(pinName).Opened    = false;
                obj.DigitalPin.(pinName).Direction = obj.GPIO_INPUT;
            end
        end
        
        function configurePin(obj, pin, pinMode)
            checkDigitalPin(obj, pin);
            
            % Configure pin for input / output
            pinName = obj.getPinName(pin);
            if pin < 8
                iodirReg = obj.IODIRA;
            else
                iodirReg = obj.IODIRB;
                pin = pin - 8;
            end
            direction = obj.i2cObj.readRegister(iodirReg);
            if isequal(pinMode, 'input')
                direction = bitset(direction, pin+1, 1);
            else
                direction = bitset(direction, pin+1, 0);
            end
            obj.i2cObj.writeRegister(iodirReg, direction);
            
            % Cache pin state
            obj.DigitalPin.(pinName).Opened = true;
            if isequal(pinMode, 'input')
                obj.DigitalPin.(pinName).Direction = obj.GPIO_INPUT;
            else
                obj.DigitalPin.(pinName).Direction = obj.GPIO_OUTPUT;
            end
        end
        
        function writeDigitalPin(obj, pin, value)
            checkDigitalPin(obj, pin);
            pinName = obj.getPinName(pin);
            if ~obj.DigitalPin.(pinName).Opened
                configurePin(obj, pin, 'output');
            end
            if obj.DigitalPin.(pinName).Direction ~= obj.GPIO_OUTPUT
                error(message('raspi:utils:InvalidDigitalWrite',...
                    pin,'input'));
            end
            
            % Write to specified pin
            if pin < 8
                ioReg = obj.GPIOA;
            else
                ioReg = obj.GPIOB;
                pin = pin - 8;
            end
            output = obj.i2cObj.readRegister(ioReg);
            output = bitset(output, pin+1, value);
            obj.i2cObj.writeRegister(ioReg, output);
        end
        
        function value = readDigitalPin(obj, pin)
            checkDigitalPin(obj, pin);
            pinName = obj.getPinName(pin);
            if ~obj.DigitalPin.(pinName).Opened
                configurePin(obj, pin, 'input');
            end
            if obj.DigitalPin.(pinName).Direction ~= obj.GPIO_INPUT
                 error(message('raspi:utils:InvalidDigitalRead',...
                     pin,'output'));
            end
            
            % Read from specified pin
            if pin < 8
                ioReg = obj.GPIOA;
            else
                ioReg = obj.GPIOB;
                pin = pin - 8;
            end
            output = obj.i2cObj.readRegister(ioReg);
            value = bitget(output, pin+1);
        end
    end
    
    methods (Hidden)
        function configureDigitalPin(obj, pin, pinMode)
            configurePin(obj,pin,pinMode);
        end
    end
    
    methods (Access = private)
        function checkDigitalPin(obj, pinNumber)
            validateattributes(pinNumber, {'numeric'}, {'scalar'}, ...
                '', 'pinNumber');
            if ~any(obj.AvailableDigitalPins == pinNumber)
                error(message('raspi:utils:UnexpectedDigitalPinNumber'));
            end
        end
    end
    
    methods (Static, Access = private)
        function pinName = getPinName(pinNumber)
            pinName = ['gpio' int2str(pinNumber)];
        end
    end
end %classdef

