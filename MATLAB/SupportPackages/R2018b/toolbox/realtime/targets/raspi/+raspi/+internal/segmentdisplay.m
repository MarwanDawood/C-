classdef segmentdisplay < handle
    %SEGMENTDISPLAY Create segment display object.
    %   
    % sd = raspi.internal.segmentdisplay(bus) creates a segment display object.
    %
    % print(sd, str) prints the contents of the str on the segment display.
    % The input, str, must contains hexadecimal characters: a-f, 0-9. The
    % size of the str should be smaller than or equal to 4 characters.
    % Otherwise part of the string will be cut off.
    %
    % clr(sd) clears the display.
    %
    % setBrightness(sd, brightness) sets the brightness of the segment
    % display. The brightness must be an integer between 0 and 255.
    
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = private)
        Address
        Brightness = 255;
    end
    
    properties (Hidden, Access = private)
        i2cObj
        LastStr = '    ';
    end
    
    properties (Hidden, Constant)
        % I2C Commands for segmented display
        CLR_DISPLAY    = hex2dec('76');
        DEC_CONTROL    = hex2dec('77');
        SET_CURSOR     = hex2dec('79');
        SET_BRIGHTNESS = hex2dec('7A');
        SET_DIGIT_1    = hex2dec('7B');
        SET_DIGIT_2    = hex2dec('7C');
        SET_DIGIT_3    = hex2dec('7D');
        SET_DIGIT_4    = hex2dec('7E');
        BAUD_RATE      = hex2dec('7F');
        SET_I2C_ADDR   = hex2dec('80');
        FACTORY_RESET  = hex2dec('81');
        CLEAR_DIGIT    = bin2dec('00010000');
    end
    
    methods
        function obj = segmentdisplay(raspiObj, bus, address)
            if (nargin < 3)
                address = '0x71';
            end
            obj.Address = address;
            obj.i2cObj = i2cdev(raspiObj, bus, obj.Address);
            obj.clr;
        end
        
        function clr(obj)
            try
                obj.i2cObj.write(obj.CLR_DISPLAY);
            catch
                obj.i2cObj.write(obj.CLR_DISPLAY);
            end
            obj.LastStr = '    ';
        end
        
        function setBrightness(obj, brightness)
            validateattributes(brightness, {'numeric'}, ...
                {'scalar', '>=', 0, '<', 256}, '', 'brightness');
            try
                obj.i2cObj.writeRegister(obj.SET_BRIGHTNESS, brightness);
            catch
                obj.i2cObj.writeRegister(obj.SET_BRIGHTNESS, brightness);
            end
            obj.Brightness = brightness;
        end
        
        function setCursor(obj, position)
            try
                obj.i2cObj.write(uint8([obj.SET_CURSOR, position]));
            catch
                obj.i2cObj.write(uint8([obj.SET_CURSOR, position]));
            end
        end
        
        function print(obj, str)
            validateattributes(str, {'char'}, ...
                {'row'}, '', 'str');
            if numel(str) > 0
                str = sprintf('%4s', str);
                str = str(1:4);
                for i = 1:4;
                    if str(i) == obj.LastStr(i)
                        continue;
                    end
                    if str(i) == ' '
                        val = obj.CLEAR_DIGIT;
                    else
                        val = obj.hex2dec(str(i));
                    end
                    obj.setCursor(i-1);
                    try
                        obj.i2cObj.write(val);
                    catch
                        obj.i2cObj.write(val);
                    end
                end
                obj.LastStr = str;
            else
                obj.clr;
            end
        end
    end
    
    methods
        function set.Address(obj, address)
                validateattributes(address, {'char'}, ...
                    {'nonempty'}, '', 'address');
            obj.Address  = address;
        end
    end
    
    methods (Hidden, Static)
        function decvalue = hex2dec(hexvalue)
            decvalue = hex2dec(regexprep(hexvalue, '0x', ''));
        end
        
        function hexvalue = dec2hex(decvalue)
            hexvalue = ['0x' dec2hex(decvalue)];
        end
    end
end

