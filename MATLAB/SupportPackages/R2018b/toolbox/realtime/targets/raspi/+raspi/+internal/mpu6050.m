classdef mpu6050 < handle & matlab.mixin.CustomDisplay
    %MPU6050 MPU6050 integrated gyroscope / acceloremeter sensor.
    %
    % mpu6050 = raspi.internal.mpu6050(bus) creates a MPU6050
    % sensor object attached to the specified I2C
    % bus. The I2C address of the MPU6050 sensor defaults to 0x68.
    %
    % [x, y, z] = readAcceleration(lis331) reads the accelaration data from
    % the sensor.  
    %
    % <a href="http://invensense.com/mems/gyro/documents/PS-MPU-6000A-00v3.4.pdf?">Device Datasheet</a>
    % <a href="http://invensense.com/mems/gyro/documents/RM-MPU-6000A.pdf??">Register Map and Descriptions</a>
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = private)
        SampleRate = 1000;
        AcceloremeterSensitivity = '+/-2g';
    end
    
    properties (Constant)
        Address = '0x68';
    end
    
    properties (Hidden)
        Debug = false;
        AvailableAcceloremeterSensitivities = {'+/-2g', '+/-4g', '+/-8g', '+/-16g'};
    end
    
    properties (Dependent, Access = private)
        NumericalAccelSensitivity
    end
    
    properties (Access = private)
        i2cObj
        % Calibration coefficients. Initial values are from the datasheet.
        AccelScale = 16384;
    end
    
    properties (Constant, Access = private)
        % These are from the data sheet
        RA_XG_OFFS_TC   = hex2dec('00'); %[7] PWR_MODE, [6:1] XG_OFFS_TC, [0] OTP_BNK_VLD
        RA_YG_OFFS_TC   = hex2dec('01'); %[7] PWR_MODE, [6:1] YG_OFFS_TC, [0] OTP_BNK_VLD
        RA_ZG_OFFS_TC   = hex2dec('02'); %[7] PWR_MODE, [6:1] ZG_OFFS_TC, [0] OTP_BNK_VLD
        RA_X_FINE_GAIN  = hex2dec('03'); %[7:0] X_FINE_GAIN
        RA_Y_FINE_GAIN  = hex2dec('04'); %[7:0] Y_FINE_GAIN
        RA_Z_FINE_GAIN  = hex2dec('05'); %[7:0] Z_FINE_GAIN
        RA_XA_OFFS_H    = hex2dec('06'); %[15:0] XA_OFFS
        RA_XA_OFFS_L_TC = hex2dec('07');
        RA_YA_OFFS_H    = hex2dec('08'); %[15:0] YA_OFFS
        RA_YA_OFFS_L_TC = hex2dec('09');
        RA_ZA_OFFS_H    = hex2dec('0A'); %[15:0] ZA_OFFS
        RA_ZA_OFFS_L_TC = hex2dec('0B');
        RA_SELF_TEST_X  = hex2dec('0D');
        RA_SELF_TEST_Y  = hex2dec('0E');
        RA_SELF_TEST_Z  = hex2dec('0F');
        RA_SELF_TEST_A  = hex2dec('10');
        RA_XG_OFFS_USRH = hex2dec('13'); %[15:0] XG_OFFS_USR
        RA_XG_OFFS_USRL = hex2dec('14');
        RA_YG_OFFS_USRH = hex2dec('15'); %[15:0] YG_OFFS_USR
        RA_YG_OFFS_USRL = hex2dec('16');
        RA_ZG_OFFS_USRH = hex2dec('17'); %[15:0] ZG_OFFS_USR
        RA_ZG_OFFS_USRL = hex2dec('18');
        RA_SMPLRT_DIV   = hex2dec('19');
        RA_CONFIG       = hex2dec('1A');
        RA_GYRO_CONFIG  = hex2dec('1B');
        RA_ACCEL_CONFIG = hex2dec('1C');
        RA_FF_THR       = hex2dec('1D');
        RA_FF_DUR       = hex2dec('1E');
        RA_MOT_THR      = hex2dec('1F');
        RA_MOT_DUR      = hex2dec('20');
        RA_ZRMOT_THR    = hex2dec('21');
        RA_ZRMOT_DUR    = hex2dec('22');
        RA_FIFO_EN      = hex2dec('23');
        RA_I2C_MST_CTRL = hex2dec('24');
        RA_I2C_SLV0_ADDR = hex2dec('25');
        RA_I2C_SLV0_REG = hex2dec('26');
        RA_I2C_SLV0_CTRL = hex2dec('27');
        RA_I2C_SLV1_ADDR = hex2dec('28');
        RA_I2C_SLV1_REG = hex2dec('29');
        RA_I2C_SLV1_CTRL = hex2dec('2A');
        RA_I2C_SLV2_ADDR = hex2dec('2B');
        RA_I2C_SLV2_REG  = hex2dec('2C');
        RA_I2C_SLV2_CTRL = hex2dec('2D');
        RA_I2C_SLV3_ADDR = hex2dec('2E');
        RA_I2C_SLV3_REG = hex2dec('2F');
        RA_I2C_SLV3_CTRL = hex2dec('30');
        RA_I2C_SLV4_ADDR = hex2dec('31');
        RA_I2C_SLV4_REG = hex2dec('32');
        RA_I2C_SLV4_DO = hex2dec('33');
        RA_I2C_SLV4_CTRL = hex2dec('34');
        RA_I2C_SLV4_DI = hex2dec('35');
        RA_I2C_MST_STATUS = hex2dec('36');
        RA_INT_PIN_CFG = hex2dec('37');
        RA_INT_ENABLE = hex2dec('38');
        RA_DMP_INT_STATUS = hex2dec('39');
        RA_INT_STATUS = hex2dec('3A');
        RA_ACCEL_XOUT_H = hex2dec('3B');
        RA_ACCEL_XOUT_L = hex2dec('3C');
        RA_ACCEL_YOUT_H = hex2dec('3D');
        RA_ACCEL_YOUT_L = hex2dec('3E');
        RA_ACCEL_ZOUT_H = hex2dec('3F');
        RA_ACCEL_ZOUT_L = hex2dec('40');
        RA_TEMP_OUT_H = hex2dec('41');
        RA_TEMP_OUT_L = hex2dec('42');
        RA_GYRO_XOUT_H = hex2dec('43');
        RA_GYRO_XOUT_L = hex2dec('44');
        RA_GYRO_YOUT_H = hex2dec('45');
        RA_GYRO_YOUT_L = hex2dec('46');
        RA_GYRO_ZOUT_H = hex2dec('47');
        RA_GYRO_ZOUT_L = hex2dec('48');
        RA_EXT_SENS_DATA_00 = hex2dec('49');
        RA_EXT_SENS_DATA_01 = hex2dec('4A');
        RA_EXT_SENS_DATA_02 = hex2dec('4B');
        RA_EXT_SENS_DATA_03 = hex2dec('4C');
        RA_EXT_SENS_DATA_04 = hex2dec('4D');
        RA_EXT_SENS_DATA_05 = hex2dec('4E');
        RA_EXT_SENS_DATA_06 = hex2dec('4F');
        RA_EXT_SENS_DATA_07 = hex2dec('50');
        RA_EXT_SENS_DATA_08 = hex2dec('51');
        RA_EXT_SENS_DATA_09 = hex2dec('52');
        RA_EXT_SENS_DATA_10 = hex2dec('53');
        RA_EXT_SENS_DATA_11 = hex2dec('54');
        RA_EXT_SENS_DATA_12 = hex2dec('55');
        RA_EXT_SENS_DATA_13 = hex2dec('56');
        RA_EXT_SENS_DATA_14 = hex2dec('57');
        RA_EXT_SENS_DATA_15 = hex2dec('58');
        RA_EXT_SENS_DATA_16 = hex2dec('59');
        RA_EXT_SENS_DATA_17 = hex2dec('5A');
        RA_EXT_SENS_DATA_18 = hex2dec('5B');
        RA_EXT_SENS_DATA_19 = hex2dec('5C');
        RA_EXT_SENS_DATA_20 = hex2dec('5D');
        RA_EXT_SENS_DATA_21 = hex2dec('5E');
        RA_EXT_SENS_DATA_22 = hex2dec('5F');
        RA_EXT_SENS_DATA_23 = hex2dec('60');
        RA_MOT_DETECT_STATUS = hex2dec('61');
        RA_I2C_SLV0_DO = hex2dec('63');
        RA_I2C_SLV1_DO = hex2dec('64');
        RA_I2C_SLV2_DO = hex2dec('65');
        RA_I2C_SLV3_DO = hex2dec('66');
        RA_I2C_MST_DELAY_CTRL = hex2dec('67');
        RA_SIGNAL_PATH_RESET = hex2dec('68');
        RA_MOT_DETECT_CTRL = hex2dec('69');
        RA_USER_CTRL = hex2dec('6A');
        RA_PWR_MGMT_1 = hex2dec('6B');
        RA_PWR_MGMT_2 = hex2dec('6C');
        RA_BANK_SEL = hex2dec('6D');
        RA_MEM_START_ADDR = hex2dec('6E');
        RA_MEM_R_W = hex2dec('6F');
        RA_DMP_CFG_1 = hex2dec('70');
        RA_DMP_CFG_2 = hex2dec('71');
        RA_FIFO_COUNTH = hex2dec('72');
        RA_FIFO_COUNTL = hex2dec('73');
        RA_FIFO_R_W = hex2dec('74');
        RA_WHO_AM_I = hex2dec('75');
    end
    
    methods
        function obj = mpu6050(raspiObj, bus, debug)
            if nargin > 3
                obj.Debug = debug;
            end
            obj.i2cObj = i2cdev(raspiObj, bus, obj.Address);  
            
            % Set all ports to input initially
            obj.testConnection();
            obj.configureDevice();
            obj.AccelScale = 16384 / (1 + obj.NumericalAccelSensitivity);
        end
        
        function [x, y, z] = readAcceleration(obj)
            x = obj.readInt16(obj.RA_ACCEL_XOUT_H) / obj.AccelScale;
            y = obj.readInt16(obj.RA_ACCEL_YOUT_H) / obj.AccelScale;
            z = obj.readInt16(obj.RA_ACCEL_ZOUT_H) / obj.AccelScale;
        end
    end
    
    methods
        function set.SampleRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan'}, '', 'SampleRate');
            if ~ismember(value, obj.AvailableSampleRates)
                error('raspi:utils:InvalidSampleRate', ...
                    'Invalid SampleRate. Available SampleRates are %d %d.', ...
                    obj.AvailableSampleRates(1), obj.AvailableSampleRates(end));
            end
            obj.SampleRate = value;
        end
        
        function set.AcceloremeterSensitivity(obj, value)
            value = validatestring(value, obj.AcceloremeterSensitivities);
            obj.Resolution = value;
        end
        
        function value = get.NumericalAccelSensitivity(obj)
            [indx] = ismember(obj.AvailableAcceloremeterSensitivities, ...
                obj.AcceloremeterSensitivity);
            tmp = 0:3;
            value = tmp(indx);
        end
    end
    
    methods (Access = private)
        function value = readUint16(obj, REG)
            value = obj.i2cObj.readRegister(REG, 'uint16');
            value = double(swapbytes(value));       
        end
        
        function value = readInt16(obj, REG)
            value = obj.i2cObj.readRegister(REG, 'int16');
            value = double(swapbytes(value));
        end
        
        function configureDevice(obj)
            % Set sampling rate
            obj.i2cObj.writeRegister(obj.RA_SMPLRT_DIV, hex2dec('07'));
            
            % Set clock source to gyro reference with PLL
            obj.i2cObj.writeRegister(obj.RA_PWR_MGMT_1, bin2dec('00000010'));
            
            % Configure GYRO
            obj.i2cObj.writeRegister(obj.RA_GYRO_CONFIG, bin2dec('00001000'));
            
            % Configure acceloremeter
            obj.i2cObj.writeRegister(obj.RA_ACCEL_CONFIG, obj.NumericalAccelSensitivity);
        end 
        
        function testConnection(obj)
            value = obj.i2cObj.readRegister(obj.RA_WHO_AM_I, 'uint8');
            if obj.Debug
                fprintf('RA_WHO_AM_I = %x\n', value);
            end
            if value ~= hex2dec('68')
                error('raspi:utils:MPU6050ReadTestError', 'I2C read test failed.');
            end
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            % Display main options
            fprintf('  AcceloremeterSensitivity: %-15s (+/2g, +/-4g, +/-8g, +/-16g)\n', ...
                obj.AcceloremeterSensitivity);
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end %classdef

