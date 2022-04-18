classdef bmp180 < handle & matlab.mixin.CustomDisplay
    %BMP180 BMP180 temperature / pressure sensor.
    %
    % bmp180 = raspi.internal.bmp180(bus) creates a BMP180
    % temperature / pressure sensor object attached to the specified I2C
    % bus. The I2C address of the BMP180 sensor defaults to '0x77'.
    %
    % readTemperature(bmp180) reads the temperature value from the BMP180
    % sensor. The default unit of temperature is Celsius.
    %
    % readPressure(bmp180) reads the pressure value from the BMP180. The
    % default unit of pressure is hPa.
    %
    % The Mode property of the bmp180 object determines power consumption,
    % speed and accuracy. 
    %
    % Mode | Oversampling rate | Conversion time | Avg. Current
    % ---------------------------------------------------------------------
    %   0  |         1         |      4.5ms      |   3 microAmps
    %   1  |         2         |      7.5ms      |   5 microAmps
    %   2  |         4         |     13.5ms      |   7 microAmps
    %   3  |         8         |     25.5ms      |  12 microAmps
    %
    % <a href="http://ae-bst.resource.bosch.com/media/products/dokumente/bmp180/BST-BMP180-DS000-09.pdf">Device Datasheet</a>
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        Mode = 0;
        TemperatureUnit = 'Celsius';
        PressureUnit = 'hPa';
    end
    
    properties (Constant)
        Address = '0x77';
    end
    
    properties (Hidden)
        Debug = false;
    end
    
    properties (Access = private)
        i2cObj
        % Calibration coefficients. Initial values are from the datasheet.
        AC1 = 408;
        AC2 = -72;
        AC3 = -14383;
        AC4 = 32741;
        AC5 = 32757;
        AC6 = 23153;
        B1  = 6190;
        B2  = 4;
        MB  = -32768;
        MC  = -8711;
        MD  = 2868;
    end
    
    properties (Constant, Access = private)
        % These are from the data sheet
        REG_ADDR_AC1 = hex2dec('AA');
        REG_ADDR_AC2 = hex2dec('AC');
        REG_ADDR_AC3 = hex2dec('AE');
        REG_ADDR_AC4 = hex2dec('B0');
        REG_ADDR_AC5 = hex2dec('B2');
        REG_ADDR_AC6 = hex2dec('B4');
        REG_ADDR_B1  = hex2dec('B6');
        REG_ADDR_B2  = hex2dec('B8');
        REG_ADDR_MB  = hex2dec('BA');
        REG_ADDR_MC  = hex2dec('BC');
        REG_ADDR_MD  = hex2dec('BE');
        REG_ADDR_CONTROL = hex2dec('F4');
        REG_ADDR_DATA = hex2dec('F6');
        READ_TEMP_CMD = hex2dec('2E');
        READ_PRESSURE_CMD = hex2dec('34');
        AvailableTemperatureUnits = {'Celsius', 'Fahrenheit', 'Kelvin'};
        AvailablePressureUnits = {'hPa', 'Pa'};
        AvailableModes = [0, 1, 2, 3];
    end
    
    methods
        function obj = bmp180(raspiObj, bus, debug)
            if nargin > 3
                obj.Debug = debug;
            end
            obj.i2cObj = i2cdev(raspiObj, bus, obj.Address);
            
            
            % Set all ports to input initially
            obj.readCalibrationCoeff();
        end
        
        function T = readTemperature(obj)
            UT = readRawTemp(obj);
            X1 = ((UT - obj.AC6) * obj.AC5) / 2^15;
            X2 = (obj.MC * 2^11) / (X1 + obj.MD);
            B5 = X1 + X2;
            T = ((B5 + 8)/2^4) / 10;
            if isequal(obj.TemperatureUnit, 'Fahrenheit')
                T = 32 + T * 1.8;
            elseif isequal(obj.TemperatureUnit, 'Kelvin')
                T = T + 273;
            end
            if obj.Debug
                fprintf('UT=%d, X1=%d, X2=%d, B5=%d, T=%f\n', ...
                    UT, X1, X2, B5, T);
            end
        end
        
        function p = readPressure(obj)
            UT = readRawTemp(obj);
            UP = readRawPressure(obj);
            
            % Temperature calculation
            X1 = ((UT - obj.AC6) * obj.AC5) / 2^15;
            X2 = (obj.MC * 2^11) / (X1 + obj.MD);
            B5 = X1 + X2;
            
            % Pressure calculation
            B6 = B5 - 4000;
            X1 = (obj.B2 * (B6 * B6 / 2^12)) / 2^11;
            X2 = obj.AC2 * B6 / 2^11;
            X3 = X1 + X2;
            B3 = ((obj.AC1*4 + X3) * 2^obj.Mode + 2)/4;
            X1 = obj.AC3 * B6 / 2^13;
            X2 = (obj.B1 * (B6 * B6 / 2^12)) / 2^16;
            X3 = ((X1 + X2) + 2) / 2^2;
            B4 = obj.AC4 * (X3 + 32768) / 2 ^15;
            B7 = (UP - B3) * bitshift(50000, obj.Mode);
            if B7 < hex2dec('80000000')
                p = (B7 * 2) / B4;
            else
                p = (B7 / B4) * 2;
            end
            X1 = (p / 2^8) * (p / 2^8);
            X1 = (X1 * 3038) / 2^16;
            X2 = (-7357 * p) / 2^16;
            p = p + (X1 + X2 + 3791) / 2^4;
            if isequal(obj.PressureUnit, 'hPa')
                p = p / 100; % Return pressure in hPa
            end
        end
    end
    
    methods
        function set.TemperatureUnit(obj, value)
            value = validatestring(value, obj.AvailableTemperatureUnits, ...
                    '', 'TemperatureUnit');
            obj.TemperatureUnit = value;    
        end
        
        function set.PressureUnit(obj, value)
            value = validatestring(value, obj.AvailablePressureUnits, ...
                    '', 'PressureUnit');
            obj.PressureUnit = value; 
        end
        
        function set.Debug(obj, value)
            validateattributes(value, {'logical'}, ...
                {}, '', 'Debug');
            obj.Debug = value;
        end
        
        function set.Mode(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Mode');
            if ~ismember(value, obj.AvailableModes)
                error('raspi:utils:BMP180InvalidMode', ...
                'Invalid Mode. Mode must 0, 1, 2 or 3.');
            end
            obj.Contrast = value;
        end
    end
    
    methods (Access = private)
        function UT = readRawTemp(obj)
            obj.i2cObj.writeRegister(obj.REG_ADDR_CONTROL, obj.READ_TEMP_CMD);
            pause(5e-3);
            UT = obj.readUint16(obj.REG_ADDR_DATA);
        end
        
        function UP = readRawPressure(obj)
            obj.i2cObj.writeRegister(obj.REG_ADDR_CONTROL, ...
                obj.READ_PRESSURE_CMD + bitshift(obj.Mode, 6));
            switch obj.Mode
                case 0
                    pause(5e-3);
                case 1
                    pause(14e-3);
                case 2 
                    pause(26e-3);
                case 3
                    pause(80e-3);
            end
            msb  = double(obj.i2cObj.readRegister(obj.REG_ADDR_DATA));
            lsb  = double(obj.i2cObj.readRegister(obj.REG_ADDR_DATA+1));
            xlsb = double(obj.i2cObj.readRegister(obj.REG_ADDR_DATA+2));
            UP = bitshift(msb, 16) + bitshift(lsb, 8) + xlsb;
            UP = bitshift(UP, obj.Mode - 8);
        end
        
        function value = readUint16(obj, REG)
            value = obj.i2cObj.readRegister(REG, 'uint16');
            value = double(swapbytes(value));       
        end
        
        function value = readInt16(obj, REG)
            value = obj.i2cObj.readRegister(REG, 'int16');
            value = double(swapbytes(value));
        end
        
        function readCalibrationCoeff(obj)
            obj.AC1 = obj.readInt16(obj.REG_ADDR_AC1);
            obj.AC2 = obj.readInt16(obj.REG_ADDR_AC2);
            obj.AC3 = obj.readInt16(obj.REG_ADDR_AC3);
            obj.AC4 = obj.readUint16(obj.REG_ADDR_AC4);
            obj.AC5 = obj.readUint16(obj.REG_ADDR_AC5);
            obj.AC6 = obj.readUint16(obj.REG_ADDR_AC6);
            obj.B1  = obj.readInt16(obj.REG_ADDR_B1);
            obj.B2  = obj.readInt16(obj.REG_ADDR_B2);
            obj.MB  = obj.readInt16(obj.REG_ADDR_MB);
            obj.MC  = obj.readInt16(obj.REG_ADDR_MC);
            obj.MD  = obj.readInt16(obj.REG_ADDR_MD);
            if obj.Debug
                fprintf('AC1=%d, AC2=%d, AC3=%d, AC4=%d, AC5=%d, AC6=%d\n', ...
                    obj.AC1, obj.AC2, obj.AC3, obj.AC4, obj.AC5, obj.AC6);
                fprintf('B1=%d, B2=%d\n', obj.B1, obj.B2);
                fprintf('MB=%d, MC=%d, MD=%d\n', obj.MB, obj.MC, obj.MD);
            end
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            % Display main options
            fprintf('                 Address: %-15s\n', obj.Address);
            fprintf('                    Mode: %-15d (0, 1, 2 or 3)\n', obj.Mode);
            fprintf('        TemperatureUnit : %-15s (%s)\n', ...
                obj.TemperatureUnit, i_printAvailableValues(obj.AvailableTemperatureUnits));  
            fprintf('           PressureUnit : %-15s (%s)\n', ...
                obj.PressureUnit, i_printAvailableValues(obj.AvailablePressureUnits));
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
    
    methods (Static, Access = public)
        function altitude = calculateAltitude(pressureInhPa)
            % altitude = calculateAltitude(obj, pressure)
            altitude = 44330 * (1 - (pressureInhPa / 1013.25)^(1/5.255));
        end
    end
end %classdef


function str = i_printAvailableValues(values)
str = '';
for i = 1:length(values)
    str = [str, '''' values{i}, '''']; %#ok<AGROW>
    if i ~= length(values)
        str = [str, ', ']; %#ok<AGROW>
    end
end
end
