classdef mcp4725 < handle & matlab.mixin.CustomDisplay
    %MCP4725 12-bit DAC.
    %
    % dac = mcp4725(rpi, bus, address) creates a MCP4725 DAC object
    % attached to the specified I2C bus with the specified I2C address. The
    % first parameter, rpi, is a raspi object. If not specified, the I2C
    % address of the MCP4725 defaults to '0x62'.
    %
    % dac = mcp4725(rpi, bus, address, voltageReference) creates a MCP4725
    % DAC object with specified voltage reference. The voltageReference
    % defaults to 3.3V. Set the voltageReference value to the voltage
    % applied to the VDD pin of the MCP4725.
    %
    % writeVoltage(dac, voltage) sets the output voltage of the DAC.
    %
    % enterPowerDownMode(dac, resistor) puts DAC in power down mode. In
    % power down mode, all internal circuits (except for I2C) are disabled
    % and no output voltage is available. The output is tied to VSS
    % (usually ground) pin via a resistor. The resistor value can be 1000
    % Ohm, 100000 Ohm or 500000 Ohm. To exit the power down mode, use
    % writeVoltage method.
    %
    % writeEEPROM(dac, voltage) saves the specified voltage to the internal
    % EEPROM memory of the DAC. When DAC powers up after a reset, it
    % automatically outputs the voltage value written to EEPROM. Note that
    % writing to EEPROM also changes the current output voltage.
    %
    % writeEEPROM(dac, voltage, resistor) saves the specified voltage and
    % resistor value for power downd mode to the internal EEPROM memory of
    % the DAC. When DAC powers up after reset, it automatically enters
    % power down mode.
    %
    % <a href="https://www.sparkfun.com/datasheets/BreakoutBoards/MCP4725.pdf">Device Datasheet</a>
    %
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties (SetAccess = private, GetAccess = public)
        Address = bin2dec('1100010') % Default address 0x62
    end
    
    properties (Access = public)
        VoltageReference = 3.3       % Reference voltage supplied to the VDD pin
    end
    
    properties (Access = private)
        i2cObj
        ConfigReg
    end
    
    properties (Constant, Hidden)
        AvailablePowerDownResistor = [1000, 100000, 500000]
    end
    
    properties (Constant, Access = private)      
        % Bitfield shifts
        CONFIG_FAST_MODE_PD_SHIFT = 4
        CONFIG_EEPROM_C_SHIFT  = 5
        CONFIG_EEPROM_PD_SHIFT = 1
        CONFIG_EEPROM_D_SHIFT  = 4
        
        % 12-bit DAC voltage scale
        DAC_SCALAR = 2^12 - 1
    end
    
    methods
        function obj = mcp4725(raspiObj, bus, address, voltageReference)
            % Set I2C address if not using default
            if nargin > 2
                obj.Address = address;
            end
            if nargin > 3
                obj.VoltageReference = voltageReference;
            end
            
            % Initialize config register value
            obj.ConfigReg = zeros(1, 3, 'uint8');
            
            % Create an i2cdev object to talk to ADS1115
            obj.i2cObj = i2cdev(raspiObj, bus, obj.Address);
        end
        
        function writeVoltage(obj, voltage)
            % voltage = readVoltage(obj, AINp) reads the single-ended input
            % voltage value at channe AINp.
            %
            % voltage = readVoltage(obj, AINp, AINn) reads the input
            % voltage value that is the difference between AINp and AINn.
            validateattributes(voltage, {'numeric'}, ...
                {'scalar', '>=', 0, '<=', obj.VoltageReference}, '', 'voltage');

            % Fast mode
            % Set PD bits for normal mode
            % PD = b00, C2:C1 = 0:0
            % Initialize config register value
            inputCode = getDACInputCode(obj, voltage);
            obj.ConfigReg(1) = bitshift(bitand(inputCode, hex2dec('F00')), -8);
            obj.ConfigReg(2) = bitand(inputCode, hex2dec('FF'));
            write(obj.i2cObj, obj.ConfigReg(1:2)); % Fast-mode requires two bytes
        end
        
        function writeEEPROM(obj, voltage, resistor)
            validateattributes(voltage, {'numeric'}, ...
                {'scalar', '>=', 0, '<=', obj.VoltageReference}, '', 'voltage');
            if nargin > 2
                validateattributes(resistor, {'numeric'}, ...
                    {'scalar', 'nonnan', 'finite'}, '', 'resistor');
                if ~ismember(resistor, obj.AvailablePowerDownResistor)
                    error('raspi:mcp4725:InvalidPowerDownResistor', ...
                    'Resistor must be one of the following: 1000, 100000, 500000');
                end
            else
                resistor = 0;
            end
            
            % Set config register
            % PD = bxx, C2,C1,C0 = 0,1,1
            obj.ConfigReg(1) = bitshift(bin2dec('011'), obj.CONFIG_EEPROM_C_SHIFT);
            obj.ConfigReg(1) = bitor(obj.ConfigReg(1), ...
                bitshift(obj.getPDBits(resistor), obj.CONFIG_EEPROM_PD_SHIFT));
                
            % Add DAC input code
            inputCode = getDACInputCode(obj, voltage);
            obj.ConfigReg(2) = bitshift(inputCode, -4);
            obj.ConfigReg(3) = bitshift(bitand(inputCode, hex2dec('F')), 4);
            write(obj.i2cObj, obj.ConfigReg);
        end
        
        function enterPowerDownMode(obj, resistor)
            validateattributes(resistor, {'numeric'}, ...
                {'scalar', 'nonnan', 'finite'}, '', 'resistor');
            if ~ismember(resistor, obj.AvailablePowerDownResistor)
                error('raspi:mcp4725:InvalidPowerDownResistor', ...
                    'Resistor must be one of the following: 1000, 100000, 500000');
            end
            
            % Set config register
            obj.ConfigReg(1) = bitor(obj.ConfigReg(1), ...
                bitshift(obj.getPDBits(resistor), obj.CONFIG_FAST_MODE_PD_SHIFT));
            write(obj.i2cObj, obj.ConfigReg(1:2)); % Fast-mode requires two bytes
        end
    end
    
    methods
        function set.Address(obj, value)
            if isnumeric(value)
                validateattributes(value, {'numeric'}, ...
                    {'scalar', 'nonnegative'}, '', 'Address');
            else
                validateattributes(value, {'char'}, ...
                    {'nonempty'}, '', 'Address');
                value = obj.hex2dec(value);
            end
            obj.Address = value;
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            % Display main options
            fprintf('               Address: %-15s\n', ['0x' dec2hex(obj.Address)]);
            fprintf('      VoltageReference: %-15.2f\n', obj.VoltageReference);
            fprintf('\n');
            
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
        
        function ret = getDACInputCode(obj, voltage) 
            % Compute input code
            voltage = uint16((voltage / obj.VoltageReference) * obj.DAC_SCALAR);
            ret = bitand(voltage, hex2dec('FFF'));
        end
    end
    
    methods (Static)
        function decvalue = hex2dec(hexvalue)
            decvalue = hex2dec(regexprep(hexvalue, '0x', ''));
        end
        
        function hexvalue = dec2hex(decvalue)
            hexvalue = sprintf('0x%02s', dec2hex(decvalue));
        end
        
        function ret = getPDBits(resistor)
            % Set PD bits 
            switch resistor
                case 0
                    ret = 0; % Normal mode
                case 1000
                    ret = 1; % Power down mode with 1 kOhm reistor to GND
                case 100000
                    ret = 2; % Power down mode with 100 kOhm reistor to GND
                case 500000
                    ret = 3; % Power down mode with 500 kOhm reistor to GND
            end
        end
    end
end

