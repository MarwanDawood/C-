classdef mcp300x < handle
    %MCP300X Base class for MCP3004/MCP3008.
    %   
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties 
        VoltageReference = 3.3
        ChipSelect           % Chip select
        Speed = 500000;      % SPI bus speed\
        NumAdcChannels
    end
    
    properties (Hidden, Access = private)
        raspiObj
        spiObj
    end
    
    properties (Constant, Hidden)
        Lsb2 = bin2dec('00000011');
    end
    
    methods
        function obj = mcp300x(raspiObj, chipSelect, speed, vref)
            obj.raspiObj = raspiObj;
            
            % Check that the given channel is available. This is done here
            % instead of the set method since it requires accessing the
            % properties of raspiObj
            obj.ChipSelect = chipSelect;
            if ~ismember(obj.ChipSelect, raspiObj.AvailableSPIChannels)
                error(message('raspi:utils:InvalidSPIChannel', obj.ChipSelect));
            end
            if nargin > 2
                obj.Speed = speed;
            end
            if  nargin > 3
                obj.VoltageReference = vref;
            end
            obj.spiObj = spidev(obj.raspiObj, obj.ChipSelect);
        end
        
        function voltage = readVoltage(obj, adcChannel)
            validateattributes(adcChannel, {'numeric'}, ...
                {'scalar', '>=', 0, '<=', obj.NumAdcChannels-1}, '', 'adcChannel');
            adc = obj.getAdcChannelSelect(adcChannel);
            data = uint16(obj.spiObj.writeRead([1, adc, 0])); 
            highbits = bitand(data(2), obj.Lsb2);
            voltage = double(bitor(bitshift(highbits, 8), data(3)));
            voltage = (obj.VoltageReference/1024) * voltage;
        end
    end
    
    methods
        function set.ChipSelect(obj, value)
            validateattributes(value, {'char'}, ...
                {'row', 'nonempty'}, '', 'ChipSelect');
            obj.ChipSelect = value;
        end
        
        function set.Speed(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar'}, '', 'Speed');
            obj.Speed = value;
        end
    end
    
    methods (Static, Hidden)
        function ret = getAdcChannelSelect(adcChannel)
            adcChannel = bitand(uint8(adcChannel), hex2dec('7'));
            SGL_DIF = uint8(bin2dec('10000000'));
            ret = bitor(SGL_DIF, bitshift(adcChannel, 4));
        end
    end
end

