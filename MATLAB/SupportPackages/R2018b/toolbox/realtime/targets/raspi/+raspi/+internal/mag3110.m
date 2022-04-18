classdef mag3110 < handle & matlab.mixin.CustomDisplay
    %MAG3110 Three axis, digital magnetometer.
    %
    % mag = mag3110(rpi, bus) creates a MAG3110 object attached to the
    % specified I2C bus. The first parameter, rpi, is a raspi object. The
    % I2C address of the MAG3110 defaults to '0x0E.
    %
    % [x, y, z] = readMagnetiField(mag) reads the X, Y and Z components of
    % the magnetic field.
    %
    % temp = readTemperature(mag) reads the DIE temprature of the MAG3110
    % sensor.
    %
    % The DataRate and OversamplingRatio properties of the MAG3110 object
    % determines the measurements taken per second and the accuracy of the
    % measured data. The read-only property SamplesPerSecond indicates
    % number of measurements per second and is a function of the DataRate
    % and the OversamplingRatio parameters.
    %
    % <a href="http://cache.freescale.com/files/sensors/doc/data_sheet/MAG3110.pdf">Device Datasheet</a>
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties (Constant)
        Address = '0x0E' % Default address of 0x0E
        OperatingMode = 'Continuous'
    end
    
    properties (Access=public)
        DataRate = 80
        OversamplingRatio = 16
    end
    
    properties (Dependent)
        SamplesPerSecond
    end
    
    properties (Dependent, Access=private)
        DR_BITS
        OS_BITS
        CTRL_REG1_BITS
    end
    
    properties (Hidden)
        Debug = false
        TempOffset = 29.5
    end
    
    properties (Hidden, Constant)
        AvailableDataRate = [0.63, 1.25, 2.50, 5.0, 10, 20, 40, 80]
        AvailableOversamplingRatio = [16, 32, 64, 128]
    end
    
    properties (Access = private)
        i2cObj
        CTRL_REG1_BITS_CACHE
        Initialized = false
    end
    
    properties (Constant, Access = private)
        % Register addresses
        DR_STATUS_REG = 0
        OUT_X_MSB_REG = 1
        OUT_X_LSB_REG = 2
        OUT_Y_MSB_REG = 3
        OUT_Y_LSB_REG = 4
        OUT_Z_MSB_REG = 5
        OUT_Z_LSB_REG = 6
        WHO_AM_I_REG  = 7
        SYSMOD_REG    = 8
        OFF_X_MSB_REF = 9
        OFF_X_LSB_REG = 10
        OFF_Y_MSB_REF = 11
        OFF_Y_LSB_REG = 12
        OFF_Z_MSB_REF = 13
        OFF_Z_LSB_REG = 14
        DIE_TEMP_REG  = 15
        CTRL_REG1 = 16
        CTRL_REG2 = 17
    end
    
    methods
        function obj = mag3110(raspiObj, bus, dataRate, oversamplingRatio)
            if nargin > 2
                obj.DataRate = dataRate;
            end
            if nargin > 3
                obj.OversamplingRatio = oversamplingRatio;
            end
            
            % Create an i2cdev object to talk to ADS1115
            obj.i2cObj = i2cdev(raspiObj, bus, obj.Address);
            testDevice(obj);
            initializeDevice(obj);
        end
        
        function temp = readTemperature(obj)
            val = readRegister(obj.i2cObj, obj.DIE_TEMP_REG, 'int8');
            temp = double(val) + obj.TempOffset;
        end
        
        function [x, y, z] = readMagneticField(obj)
            x = readInt16(obj, obj.OUT_X_MSB_REG);
            y = readInt16(obj, obj.OUT_Y_MSB_REG);
            z = readInt16(obj, obj.OUT_Z_MSB_REG);
        end
    end
    
    
    methods
        function set.DataRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'DataRate');
            if ~ismember(value, obj.AvailableDataRate)
                error('raspi:utils:InvalidDataRate', ...
                    'Invalid DataRate. Available DataRates are %s.', ...
                    sprintf('%0.2f ', obj.AvailableDataRate));
            end
            obj.DataRate = value;
            updateDeviceConfiguration(obj);
        end
        
        function set.OversamplingRatio(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'OversamplingRatio');
            if ~ismember(value, obj.AvailableOversamplingRatio)
                error('raspi:utils:InvalidOversamplingRatio', ...
                    'Invalid OversamplingRatio. Available OversamplingRatios are: %s.', ...
                    sprintf('%d ', obj.AvailableOversamplingRatio));
            end
            obj.OversamplingRatio = value;
            updateDeviceConfiguration(obj);
        end
        
        function value = get.SamplesPerSecond(obj)
            value = 16 * obj.DataRate / obj.OversamplingRatio;
        end
        
        function value = get.DR_BITS(obj)
            switch (obj.DataRate)
                case 80
                    value = 0;
                case 40
                    value = 1;
                case 20
                    value = 2;
                case 10
                    value = 3;
                case 5
                    value = 4;
                case 2.5
                    value = 5;
                case 1.25
                    value = 6;
                case 0.63
                    value = 7;
            end
        end
        
        function value = get.OS_BITS(obj)
            switch (obj.OversamplingRatio)
                case 16
                    value = 0;
                case 32
                    value = 1;
                case 64
                    value = 2;
                case 128
                    value = 3;
            end
        end
        
        function value = get.CTRL_REG1_BITS(obj)
            value = bitor(bitshift(obj.DR_BITS, 5), bitshift(obj.OS_BITS, 3));
            value = bitor(value, 1);   % Set AC = 1
        end
    end
    
    methods (Access = private)
        function testDevice(obj)
            value = readRegister(obj.i2cObj, obj.WHO_AM_I_REG, 'uint8');
            if obj.Debug
                fprintf('RA_WHO_AM_I = %x\n', value);
            end
            if value ~= hex2dec('C4')
                error('raspi:utils:MAG3110DeviceTestError', ...
                    ['Error communicating with the MAG3110 sensor. ', ...
                    'The value read from RA_WHO_AM_I register does not ', ...
                    'match expected value of 0xC4.']);
            end
        end
        
        function value = readInt16(obj, REG)
            value = obj.i2cObj.readRegister(REG, 'int16');
            value = double(swapbytes(value));
        end
        
        function initializeDevice(obj)
            % Configure device
            CTRL_REG1_BITS = obj.CTRL_REG1_BITS;
            configureDevice(obj, CTRL_REG1_BITS);
            obj.CTRL_REG1_BITS_CACHE = CTRL_REG1_BITS; % Update CTRL_REG1 cache
            obj.Initialized = true;
        end
        
        function configureDevice(obj, CTRL_REG1_BITS)
            writeRegister(obj.i2cObj, obj.CTRL_REG1, 0); % Enter STANDBY mode
            while readRegister(obj.i2cObj, obj.SYSMOD_REG) ~= 0 % Wait until device enters STANDBY mode
            end
            writeRegister(obj.i2cObj, obj.CTRL_REG2, hex2dec('A0'));   % Auto reset + RAW mode
            writeRegister(obj.i2cObj, obj.CTRL_REG1, CTRL_REG1_BITS);  % 80 Hz continuous mode
            if obj.Debug
                reg = readRegister(obj.i2cObj, obj.CTRL_REG1);
                fprintf('CTRL_REG1 = %x', reg);
            end
        end
        
        function updateDeviceConfiguration(obj)
            if obj.Initialized
                CTRL_REG1_BITS = obj.CTRL_REG1_BITS;
                if obj.CTRL_REG1_BITS_CACHE ~= CTRL_REG1_BITS
                    configureDevice(obj, CTRL_REG1_BITS);
                    obj.CTRL_REG1_BITS_CACHE = CTRL_REG1_BITS;
                end
            end
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            % Display main options
            fprintf('                Address: ''%s''\n', obj.Address);
            fprintf('          OperatingMode: ''%s''\n', obj.OperatingMode);
            fprintf('       SamplesPerSecond: %-10.2f\n', obj.SamplesPerSecond);
            fprintf('               DataRate: %-10.2f (0.63, 1.25, 2.50, 5.0, 10, 20, 40, or 80)\n', ...
                obj.DataRate);
            fprintf('      OversamplingRatio: %-10d (16, 32, 64, or 128)\n', ...
                obj.OversamplingRatio);
            fprintf('\n');
            
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
    
    methods (Static, Access = private)
        function decvalue = hex2dec(hexvalue)
            decvalue = hex2dec(regexprep(hexvalue, '0x', ''));
        end
        
        function hexvalue = dec2hex(decvalue)
            hexvalue = sprintf('0x%02s', dec2hex(decvalue));
        end
    end
end

