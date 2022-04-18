classdef lis331 < handle & matlab.mixin.CustomDisplay
    %LIS331 LIS331HH Triple axis accelerometer.
    %
    % lis331 = raspi.internal.lis331(SPIChannel) creates an LIS331HH sensor
    % object attached to the specified SPI channel.
    %
    % [x, y, z] = readAcceleration(lis331) reads the acceleration data from
    % the sensor. 
    %
    % <a href="https://www.sparkfun.com/datasheets/Sensors/Accelerometer/LIS331HH.pdf">Device Datasheet</a> 
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties (SetAccess = private, GetAccess = public);
        ChipSelect
    end
    
    properties(Access = public)
        DataRate = 50;
        AcceloremeterSensitivity = '+/-6g';
    end
    
    properties (Hidden, Access = private)
        raspiObj
        spiObj
        AccelScale;
    end
    
    properties (Hidden)
        Debug = false;
    end
    
    properties (Constant, Hidden)
        AvailableAcceloremeterSensitivities = {'+/-6g', '+/-12g', '+/-24g'};
        AvailableDataRates = [50, 100, 400, 1000];
        %% Device registers
        CTRL_REG1         = hex2dec('20')
        CTRL_REG2         = hex2dec('21')
        CTRL_REG3         = hex2dec('22')
        CTRL_REG4         = hex2dec('23')
        CTRL_REG5         = hex2dec('24')
        HP_FILTER_RESET   = hex2dec('25')
        REFERENCE         = hex2dec('26')
        STATUS_REG        = hex2dec('27')
        OUT_X_L           = hex2dec('28')
        OUT_X_H           = hex2dec('29')
        OUT_Y_L           = hex2dec('2a')
        OUT_Y_H           = hex2dec('2b')
        OUT_Z_L           = hex2dec('2b')
        OUT_Z_H           = hex2dec('2d')
        INT1_CFG          = hex2dec('30')
        INT1_SRC          = hex2dec('31')
        INT1_THS          = hex2dec('32')
        INT1_DURATION     = hex2dec('33')
        INT2_CFG          = hex2dec('34')
        INT2_SRC          = hex2dec('35')
        INT2_THS          = hex2dec('36')
        INT2_DURATION     = hex2dec('37')
    end
    
    methods
        function obj = lis331(raspiObj, chipSelect)
            obj.raspiObj = raspiObj;
            
            % Check that the given channel is available. This is done here
            % instead of the set method since it requires accessing the
            % properties of raspiObj
            obj.ChipSelect = chipSelect;
            if ~ismember(obj.ChipSelect, raspiObj.AvailableSPIChannels)
                error(message('raspi:utils:InvalidSPIChannel', obj.ChipSelect));
            end
            obj.spiObj = spidev(obj.raspiObj, obj.ChipSelect);
            obj.AccelScale = (6 * ismember(obj.AcceloremeterSensitivity, ...
                obj.AvailableAcceloremeterSensitivities)) / 2^15;
            obj.configureDevice();
        end
        
        function [x, y, z] = readAcceleration(obj)
            reg = bitor(hex2dec('c0'), obj.OUT_X_L);
            out = obj.spiObj.writeRead([reg, 0, 0, 0, 0, 0, 0]);
            if obj.Debug
                disp(out);
            end
            dh  = double(typecast(out(3:2:end), 'int8'));
            dl  = double(out(2:2:end));
            x = (dl(1)+ 256 * dh(1)) * obj.AccelScale;
            y = (dl(2)+ 256 * dh(2)) * obj.AccelScale;
            z = (dl(3)+ 256 * dh(3)) * obj.AccelScale;
        end
    end
    
    methods
        function set.ChipSelect(obj, value)
            validateattributes(value, {'char'}, ...
                {'row', 'nonempty'}, '', 'ChipSelect');
            obj.ChipSelect = value;
        end
        
        function set.DataRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan', 'finite'}, '', 'DataRate');
            if ~ismember(value, obj.AvailableDataRates)
                error('raspi:lis331:InvalidDataRate', ...
                    'Data Rate must be one of the following: 50, 100, 400, 1000');
            end
            obj.DataRate = value;
            obj.configureDevice();
        end
        
        function set.AcceloremeterSensitivity(obj, value)
            value = validatestring(value, obj.AvailableAcceloremeterSensitivities);
            obj.AcceloremeterSensitivity = value;
            obj.AccelScale = (6 * ismember(obj.AcceloremeterSensitivity, ...
                obj.AvailableAcceloremeterSensitivities)) / 2^15; %#ok<MCSUP>
            obj.configureDevice();
        end
    end
    
    methods (Access = private)
        function configureDevice(obj)
            % [PM2 PM1 PM0 DR1 DR0 Zen Yen Xen]
            % Normal mode, 400Hz, xyz-enabled
            switch obj.DataRate
                case 50
                    dr = 0;
                case 100
                    dr = 1;
                case 400
                    dr = 2;
                case 1000
                    dr = 3;
            end
            regValue = bitor(bitshift(dr, 3), bin2dec('111'));
            regValue = bitor(regValue, bitshift(bin2dec('001'), 5));
            obj.spiObj.writeRead([obj.CTRL_REG1, regValue]);
            
            % [BOOT HPM1 HPM0 FDS HPen2 HPen1 HPCF1 HPCF0]
            obj.spiObj.writeRead([obj.CTRL_REG2, hex2dec('00')]);
            
            % [BDU BLE FS1 FS0 STsign 0 ST SIM]
            % Block update on
            switch obj.AcceloremeterSensitivity
                case '+/-6g'
                    fs = 0;
                case '+/-12g'
                    fs = 1;
                case '+/-24g'
                    fs = 3;
            end       
            regValue = bitor(bitshift(1, 7), bitshift(fs, 4));
            obj.spiObj.writeRead([obj.CTRL_REG4, regValue]);
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            % Display main options
            fprintf('                ChipSelect: %-15s\n', obj.ChipSelect);
            fprintf('                  DataRate: %-15d (50, 100, 400 or 100 Hz)\n', ...
                obj.DataRate);
            fprintf('  AccelerometerSensitivity: %-15s (+/6, +/-12g, +/-24g)\n', ...
                obj.AcceloremeterSensitivity);
            fprintf('\n');
            
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end


