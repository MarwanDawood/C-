classdef lsm9ds1Block < matlab.System & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency & matlab.system.mixin.internal.SampleTime
    %LSM9DS1 9 DOF IMU sensor.
    %
    % <a href="http://www.st.com/resource/en/datasheet/lsm9ds1.pdf">Device Datasheet</a>
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    
    
    properties(Nontunable, Logical)
        GyroscopeHighPassFilterEnabled = true;
    end
    
    properties(Nontunable)
        GyroscopeOutputDataRate = '119 Hz';
        GyroscopeFullScaleRange = '245 dps';
        GyroscopeBandwidthMode = '0';
        GyroscopeHighPassFilterMode = '0';
        AccelerometerOutputDataRate = '119 Hz';
        AccelerometerFullScaleRange = '+/- 2g';
        AccelerometerBandwidth = '50 Hz';
        MagnetometerOutputDataRate = '40 Hz';
        MagnetometerFullScaleRange = '+/- 4 gauss';
        ActiveSensors = 'Accelerometer, Gyroscope and Magnetometer';
        BoardProperty_sh = 'Pi 2 Model B';
        SampleTime = 0.1;
    end
    
    
    properties (Dependent,Hidden)
        GyroOutputDataRateEnum
        GyroFullScaleEnum
        GyroFullScaleValueEnum
        GyroBandwidthModeEnum
        GyroscopeHPFModeEnum
        AccelOutputDataRateEnum
        AccelFullScaleEnum
        AccelFullScaleValueEnum
        AccelBandWidthEnum
        MagOutputDataRateEnum
        MagFullScaleEnum
        MagFullScaleValueEnum
        EnableGyro
        EnableAccel
        EnableMag
    end
    
    properties(Hidden)
        CalGyroA = [1 0 0;0 1 0;0 0 1];
        CalGyroB = [0 0 0];
        
        CalAccelA = [1 0 0;0 1 0;0 0 1];
        CalAccelB = [0 0 0];
        
        CalMagA = [1 0 0;0 1 0;0 0 1];
        CalMagB = [0 0 0];
    end
    
    properties(Access=private,Nontunable)
        GyroandAccelAddress = hex2dec('6A');
        MagnetometerAddress = hex2dec('1C');
    end
    
    properties(Constant, Hidden)
        ActiveSensorsSet = matlab.system.StringSet({'Accelerometer, Gyroscope and Magnetometer','Accelerometer and Gyroscope','Accelerometer and Magnetometer','Gyroscope and Magnetometer','Accelerometer','Gyroscope','Magnetometer'});
        GyroscopeOutputDataRateSet = matlab.system.StringSet({'14.9 Hz','59.5 Hz','119 Hz','238 Hz','476 Hz','952 Hz'});
        GyroscopeFullScaleRangeSet = matlab.system.StringSet({'245 dps','500 dps','2000 dps'});
        GyroscopeBandwidthModeSet = matlab.system.StringSet({'0','1','2','3'});
        GyroscopeHighPassFilterModeSet = matlab.system.StringSet({'0','1','2','3','4','5','6','7','8','9'});
        AccelerometerOutputDataRateSet = matlab.system.StringSet({'10 Hz','50 Hz','119 Hz','238 Hz','476 Hz','952 Hz'});
        AccelerometerFullScaleRangeSet = matlab.system.StringSet({'+/- 2g','+/- 4g','+/- 8g','+/- 16g'});
        AccelerometerBandwidthSet = matlab.system.StringSet({'50 Hz','105 Hz','211 Hz','408 Hz'});
        MagnetometerOutputDataRateSet = matlab.system.StringSet({'0.625 Hz','1.25 Hz','2.5 Hz','5 Hz','10 Hz','20 Hz','40 Hz','80 hz'});
        MagnetometerFullScaleRangeSet = matlab.system.StringSet({'+/- 4 gauss','+/- 8 gauss','+/- 12 gauss','+/- 16 gauss'});
        BoardProperty_shSet = matlab.system.StringSet({'Model B Rev1','Model B Rev2', 'Model B+', 'Pi 2 Model B','Pi 3 Model B'});
        
        
        CTRL_REG1_G_Value = bin2dec('00100000');
        CTRL_REG5_XL_Value = bin2dec('00100000');
        
        %% Registers
        ACT_THS	        =hex2dec('04'); % default = 00000000
        ACT_DUR	        =hex2dec('05'); % default = 00000000
        INT_GEN_CFG_XL	=hex2dec('06'); % default = 00000000
        INT_GEN_THS_X_X	=hex2dec('07'); % default = 00000000
        INT_GEN_THS_Y_X	=hex2dec('08'); % default = 00000000
        INT_GEN_THS_Z_X	=hex2dec('09'); % default = 00000000
        INT_GEN_DUR_XL	=hex2dec('0A'); % default = 00000000
        REFERENCE_G	    =hex2dec('0B'); % default = 00000000
        INT1_CTRL	    =hex2dec('0C'); % default = 00000000
        INT2_CTRL	    =hex2dec('0D'); % default = 00000000
        WHO_AM_I	    =hex2dec('0F'); % default = 01101000
        CTRL_REG1_G	    =hex2dec('10'); % default = 00000000
        CTRL_REG2_G	    =hex2dec('11'); % default = 00000000
        CTRL_REG3_G	    =hex2dec('12'); % default = 00000000
        ORIENT_CFG_G	=hex2dec('13'); % default = 00000000
        INT_GEN_SRC_G	=hex2dec('14'); % default = output
        OUT_TEMP_L	    =hex2dec('15'); % default = output
        OUT_TEMP_H	    =hex2dec('16'); % default = output
        GSTATUS_REG	    =hex2dec('17'); % default = output
        OUT_X_L_G	    =hex2dec('18'); % default = output
        OUT_X_H_G	    =hex2dec('19'); % default = output
        OUT_Y_L_G	    =hex2dec('1A'); % default = output
        OUT_Y_H_G	    =hex2dec('1B'); % default = output
        OUT_Z_L_G	    =hex2dec('1C'); % default = output
        OUT_Z_H_G	    =hex2dec('1D'); % default = output
        CTRL_REG4	    =hex2dec('1E'); % default = 00111000
        CTRL_REG5_XL	=hex2dec('1F'); % default = 00111000
        CTRL_REG6_XL	=hex2dec('20'); % default = 00000000
        CTRL_REG7_XL	=hex2dec('21'); % default = 00000000
        CTRL_REG8	    =hex2dec('22'); % default = 00000100
        CTRL_REG9	    =hex2dec('23'); % default = 00000000
        CTRL_REG10	    =hex2dec('24'); % default = 00000000
        INT_GEN_SRC_XL	=hex2dec('26'); % default = output
        
        ASTATUS_REG	    =hex2dec('27'); % default = output
        OUT_X_L_XL	    =hex2dec('28'); % default = output
        OUT_X_H_XL      =hex2dec('29'); % default = output
        OUT_Y_L_XL      =hex2dec('2A'); % default = output
        OUT_Y_H_XL      =hex2dec('2B'); % default = output
        OUT_Z_L_XL      =hex2dec('2C'); % default = output
        OUT_Z_H_XL      =hex2dec('2D'); % default = output
        FIFO_CTRL       =hex2dec('2E'); % default = 00000000
        FIFO_SRC        =hex2dec('2F'); % default = output
        INT_GEN_CFG_G	=hex2dec('30'); % default = 00000000
        INT_GEN_THS_XH_G=hex2dec('31'); % default = 00000000
        INT_GEN_THS_XL_G=hex2dec('32'); % default = 00000000
        INT_GEN_THS_YH_G=hex2dec('33'); % default = 00000000
        INT_GEN_THS_YL_G=hex2dec('34'); % default = 00000000
        INT_GEN_THS_ZH_G=hex2dec('35'); % default = 00000000
        INT_GEN_THS_ZL_G=hex2dec('36'); % default = 00000000
        INT_GEN_DUR_G	=hex2dec('37'); % default = 00000000
        
        OFFSET_X_REG_L_M=hex2dec('05');% default = 00000000
        OFFSET_X_REG_H_M=hex2dec('06');% default = 00000000
        OFFSET_Y_REG_L_M=hex2dec('07');% default = 00000000
        OFFSET_Y_REG_H_M=hex2dec('08');% default = 00000000
        OFFSET_Z_REG_L_M=hex2dec('09');% default = 00000000
        OFFSET_Z_REG_H_M=hex2dec('0A');% default = 00000000
        WHO_AM_I_M	    =hex2dec('0F');% default = 00111101
        CTRL_REG1_M	    =hex2dec('20');% default = 00010000
        CTRL_REG2_M	    =hex2dec('21');% default = 00000000
        CTRL_REG3_M	    =hex2dec('22');% default = 00000011
        CTRL_REG4_M	    =hex2dec('23');% default = 00000000
        CTRL_REG5_M	    =hex2dec('24');% default = 00000000
        STATUS_REG_M	=hex2dec('27');% default = Output
        OUT_X_L_M	    =hex2dec('28');% default = Output
        OUT_X_H_M	    =hex2dec('29');% default = Output
        OUT_Y_L_M	    =hex2dec('2A');% default = Output
        OUT_Y_H_M	    =hex2dec('2B');% default = Output
        OUT_Z_L_M	    =hex2dec('2C');% default = Output
        OUT_Z_H_M	    =hex2dec('2D');% default = Output
        INT_CFG_M	    =hex2dec('30');% default = 00001000
        INT_SRC_M	    =hex2dec('31');% default = 00000000
        INT_THS_L_M	    =hex2dec('32');% default = 00000000
        INT_THS_H_M	    =hex2dec('33');% default = 00000000
        
        % Value for register
        WHO_AM_I_VAL   = bin2dec('01101000')
        
    end
    
    properties (Hidden,Nontunable)
        i2cobj_A_G;
        i2cobj_MAG;
    end
    
    methods %constructor and read methods
        function obj = lsm9ds1Block()
            coder.allowpcode('plain');
            obj.i2cobj_A_G = codertarget.raspi.internal.I2CMasterWrite;
            obj.i2cobj_MAG = codertarget.raspi.internal.I2CMasterWrite;
        end
        
        function varargout = lsm9ds1_A_G_WriteRegister(obj,RegisterAddress,RegisterValue,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            status = writeRegister(obj.i2cobj_A_G,RegisterAddress,RegisterValue,DataType);
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        function [RegisterValue,varargout] = lsm9ds1_A_G_ReadRegister(obj,RegisterAddress,DataLength,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            [RegisterValue,status] = readRegister(obj.i2cobj_A_G,RegisterAddress,DataLength,DataType);
            if nargout > 1
                varargout{1} = status;
            end
        end
        
        function varargout = lsm9ds1_MAG_WriteRegister(obj,RegisterAddress,RegisterValue,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            status = writeRegister(obj.i2cobj_MAG,RegisterAddress,RegisterValue,DataType);
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        function [RegisterValue,varargout] = lsm9ds1_MAG_ReadRegister(obj,RegisterAddress,DataLength,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            [RegisterValue,status] = readRegister(obj.i2cobj_MAG,RegisterAddress,DataLength,DataType);
            if nargout > 1
                varargout{1} = status;
            end
        end
        
        function configureGyroscope(obj)
            %Configure gyroscope
            %Set CTRL_REG1_G
            lsm9ds1_A_G_WriteRegister(obj, obj.CTRL_REG1_G, (bin2dec('00000000')+...
                (32*obj.GyroOutputDataRateEnum)+(8*obj.GyroFullScaleEnum)+obj.GyroBandwidthModeEnum),'uint8');
            
            lsm9ds1_A_G_WriteRegister(obj, obj.CTRL_REG2_G,bin2dec('00000000'),'uint8');
            
            %Set CTRL_REG3_G
            lsm9ds1_A_G_WriteRegister(obj, obj.CTRL_REG3_G, (bin2dec('00000000')+...
                (64*obj.GyroscopeHighPassFilterEnabled)+obj.GyroscopeHPFModeEnum),'uint8');
            
            lsm9ds1_A_G_WriteRegister(obj, obj.CTRL_REG4,bin2dec('00111000'),'uint8');
            
            lsm9ds1_A_G_WriteRegister(obj, obj.ORIENT_CFG_G,bin2dec('00000000'),'uint8');
        end
        
         function configureAccelerometer(obj)
            %Turn on X,Y,Z axes
            lsm9ds1_A_G_WriteRegister(obj,obj.CTRL_REG5_XL,hex2dec('38'),'uint8');
            
            %Configure CTRL_REG6_XLG to set outputdatarate
            reg = bin2dec('00000100') + (32 * obj.AccelOutputDataRateEnum) + ...
                (8 * obj.AccelFullScaleEnum) + obj.AccelBandWidthEnum;
            lsm9ds1_A_G_WriteRegister(obj,obj.CTRL_REG6_XL,reg,'uint8');
            
            %Low res mode
            lsm9ds1_A_G_WriteRegister(obj,obj.CTRL_REG7_XL,hex2dec('00'),'uint8');
            
            %Block data update= 0. little endian
            % [BOOT|BDU|H_LACTIVE|PP_OD|SIM|IF_ADD_INC|BLE|SW_RESET]
            % Turn on IF_ADD_INC to enable burst reads
            reg = bin2dec('00000100');
            lsm9ds1_A_G_WriteRegister(obj,obj.CTRL_REG8,reg,'uint8');
        end
        
        
        function configureMagnetometer(obj)
            %Configure CTRL_REG1_M to set the Output data rate
            lsm9ds1_MAG_WriteRegister(obj, obj.CTRL_REG1_M,(bin2dec('00000000')+4*obj.MagOutputDataRateEnum),'uint8');
            %configyre CTRL_REG2_M to set full scale settings for the
            %Magnetometer
            lsm9ds1_MAG_WriteRegister(obj, obj.CTRL_REG2_M, (32*obj.MagFullScaleEnum),'uint8');
            lsm9ds1_MAG_WriteRegister(obj, obj.CTRL_REG3_M, uint8(0),'uint8'); %Continuous conversion
            lsm9ds1_MAG_WriteRegister(obj, obj.CTRL_REG4_M, uint8(0),'uint8'); %z-axis on, little endian
            lsm9ds1_MAG_WriteRegister(obj, obj.CTRL_REG5_M, uint8(0),'uint8');
        end
        
        function angularRate = readAngularRate(obj)
            % angularRate =readAngularRate(obj) reads a 1-by-3 vector of angular
            %  rate measured by the gyroscope of the ls,9ds1 sensor.
            
            angularRate = double(lsm9ds1_A_G_ReadRegister(obj,obj.OUT_X_L_G,3,'int16'))';
            angularRate = (angularRate * obj.CalGyroA + obj.CalGyroB) ...
                * obj.GyroFullScaleValueEnum / 32768;
        end
        
        function acceleration = readAcceleration(obj)
            % acceleration =readAcceleration(obj) reads a 1-by-3 vector of acceleration
            % measured by the accelerometer of the lsm9ds1 sensor.
            
            acceleration = double(lsm9ds1_A_G_ReadRegister(obj,uint8(40),3,'int16')');
            acceleration = (acceleration * obj.CalAccelA + obj.CalAccelB)...
                * obj.AccelFullScaleValueEnum / 32768;
        end
        
        function magneticField = readMagneticField(obj)
            % magneticField =readMagneticField(obj) reads a 1-by-3 vector of magneticField
            % measured by the magnetometer of the lsm9ds1 sensor.
            
            magneticField = double(lsm9ds1_MAG_ReadRegister(obj,obj.OUT_X_L_M,3,'int16'))';
            magneticField = (magneticField * obj.CalMagA + obj.CalMagB)...
                * obj.MagFullScaleValueEnum / 32768;
        end
        
        %------------------------------GYRO SETTINGS-----------------------
        function enableGyro = get.EnableGyro(obj)
            switch (obj.ActiveSensors)
                case {'Accelerometer, Gyroscope and Magnetometer',...
                        'Accelerometer and Gyroscope',...
                        'Gyroscope and Magnetometer',...
                        'Gyroscope'}
                    enableGyro = true;
                otherwise
                    enableGyro = false;
            end
        end
        
        function gyroODR = get.GyroOutputDataRateEnum(obj)
            switch (obj.GyroscopeOutputDataRate)
                case '14.9 Hz'
                    gyroODR = uint8(1);
                case '59.5 Hz'
                    gyroODR = uint8(2);
                case '119 Hz'
                    gyroODR = uint8(3);
                case '238 Hz'
                    gyroODR = uint8(4);
                case '476 Hz'
                    gyroODR = uint8(5);
                case '952 Hz'
                    gyroODR = uint8(6);
            end
        end
        
        function gyroFSR = get.GyroFullScaleEnum(obj)
            switch(obj.GyroscopeFullScaleRange)
                case '245 dps'
                    gyroFSR = uint8(0);
                case '500 dps'
                    gyroFSR = uint8(1);
                case '2000 dps'
                    gyroFSR = uint8(3);
            end
        end
        
        function gyroFSR = get.GyroFullScaleValueEnum(obj)
            switch(obj.GyroscopeFullScaleRange)
                case '245 dps'
                    gyroFSR = 245;
                case '500 dps'
                    gyroFSR = 500;
                case '2000 dps'
                    gyroFSR = 2000;
            end
        end
        
        function gyroBW = get.GyroBandwidthModeEnum(obj)
            switch (obj.GyroscopeBandwidthMode)
                case '0'
                    gyroBW = uint8(0);
                case '1'
                    gyroBW = uint8(1);
                case '2'
                    gyroBW = uint8(2);
                case '3'
                    gyroBW = uint8(3);
            end
        end
        
        function gyroHPF = get.GyroscopeHPFModeEnum(obj)
            switch (obj.GyroscopeHighPassFilterMode)
                case '0'
                    gyroHPF = uint8(0);
                case '1'
                    gyroHPF = uint8(1);
                case '2'
                    gyroHPF = uint8(2);
                case '3'
                    gyroHPF = uint8(3);
                case '4'
                    gyroHPF = uint8(4);
                case '5'
                    gyroHPF = uint8(5);
                case '6'
                    gyroHPF = uint8(6);
                case '7'
                    gyroHPF = uint8(7);
                case '8'
                    gyroHPF = uint8(8);
                case '9'
                    gyroHPF = uint8(9);
            end
        end
        
        %------------------------------Accelerometer Settings--------------------
        
        function enableAccel = get.EnableAccel(obj)
            switch (obj.ActiveSensors)
                case {'Accelerometer, Gyroscope and Magnetometer',...
                        'Accelerometer and Gyroscope',...
                        'Accelerometer and Magnetometer',...
                        'Accelerometer'}
                    enableAccel = true;
                otherwise
                    enableAccel = false;
            end
        end
        
        function accelODR = get.AccelOutputDataRateEnum(obj)
            switch (obj.AccelerometerOutputDataRate)
                case '10 Hz'
                    accelODR = uint8(1);
                case '50 Hz'
                    accelODR = uint8(2);
                case '119 Hz'
                    accelODR = uint8(3);
                case '238 Hz'
                    accelODR = uint8(4);
                case '476 Hz'
                    accelODR = uint8(5);
                case '952 Hz'
                    accelODR = uint8(6);
            end
        end
        
        function accelFSR = get.AccelFullScaleEnum(obj)
            switch (obj.AccelerometerFullScaleRange)
                case '+/- 2g'
                    accelFSR = uint8(0);
                case '+/- 4g'
                    accelFSR = uint8(2);
                case '+/- 8g'
                    accelFSR = uint8(3);
                case '+/- 16g'
                    accelFSR = uint8(1);
            end
        end
        
        function accelFSR = get.AccelFullScaleValueEnum(obj)
            switch (obj.AccelerometerFullScaleRange)
                case '+/- 2g'
                    accelFSR = 2;
                case '+/- 4g'
                    accelFSR = 4;
                case '+/- 8g'
                    accelFSR = 8;
                case '+/- 16g'
                    accelFSR = 16;
            end
        end
        
        function accelBW = get.AccelBandWidthEnum(obj)
            switch (obj.AccelerometerBandwidth)
                case '50 Hz'
                    accelBW = uint8(3);
                case '105 Hz'
                    accelBW = uint8(2);
                case '211 Hz'
                    accelBW = uint8(1);
                case '408 Hz'
                    accelBW = uint8(0);
            end
        end
        %------------------------------Magnetometer settings---------------------
        
        function enableMag = get.EnableMag(obj)
            switch (obj.ActiveSensors)
                case {'Accelerometer, Gyroscope and Magnetometer',...
                        'Gyroscope and Magnetometer',...
                        'Accelerometer and Magnetometer',...
                        'Magnetometer'}
                    enableMag = true;
                otherwise
                    enableMag = false;
            end
        end
        
        function magODR = get.MagOutputDataRateEnum(obj)
            switch(obj.MagnetometerOutputDataRate)
                case '0.625 Hz'
                    magODR = uint8(0);
                case '1.25 Hz'
                    magODR = uint8(1);
                case '2.5 Hz'
                    magODR = uint8(2);
                case '5 Hz'
                    magODR = uint8(3);
                case '10 Hz'
                    magODR = uint8(4);
                case '20 Hz'
                    magODR = uint8(5);
                case '40 Hz'
                    magODR = uint8(6);
                case '80 hz'
                    magODR = uint8(7);
            end
        end
        
        function magFSR = get.MagFullScaleEnum(obj)
            switch(obj.MagnetometerFullScaleRange)
                case '+/- 4 gauss'
                    magFSR = uint8(0);
                case '+/- 8 gauss'
                    magFSR = uint8(1);
                case '+/- 12 gauss'
                    magFSR = uint8(2);
                case '+/- 16 gauss'
                    magFSR = uint8(3);
            end
        end
        
        function magFSR = get.MagFullScaleValueEnum(obj)
            switch(obj.MagnetometerFullScaleRange)
                case '+/- 4 gauss'
                    magFSR = 4;
                case '+/- 8 gauss'
                    magFSR = 8;
                case '+/- 12 gauss'
                    magFSR = 12;
                case '+/- 16 gauss'
                    magFSR = 16;
            end
        end
        
        function set.SampleTime(obj,newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');
            if isLocked(obj)
                error(message('svd:svd:SampleTimeNonTunable'))
            end
            newTime = matlabshared.svd.internal.validateSampleTime(newTime);
            obj.SampleTime = newTime;
        end
    end
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            if obj.EnableAccel || obj.EnableGyro
                obj.i2cobj_A_G.BoardProperty = obj.BoardProperty_sh;
                obj.i2cobj_A_G.SlaveAddress = obj.GyroandAccelAddress;
                obj.i2cobj_A_G.SlaveByteOrder = 'LittleEndian';
                open(obj.i2cobj_A_G,100000);
                if obj.EnableGyro
                    configureGyroscope(obj);
                end
                if obj.EnableAccel
                    configureAccelerometer(obj);
                end
            end
            if obj.EnableMag
                obj.i2cobj_MAG.BoardProperty = obj.BoardProperty_sh;
                obj.i2cobj_MAG.SlaveAddress = obj.MagnetometerAddress;
                obj.i2cobj_MAG.SlaveByteOrder = 'LittleEndian';
                open(obj.i2cobj_MAG,100000);
                configureMagnetometer(obj);
            end
        end
        
        
        function [varargout] = stepImpl(obj)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            if (obj.EnableAccel && obj.EnableGyro && obj.EnableMag)
                varargout{1}=obj.readAngularRate;
                varargout{2}=obj.readAcceleration;
                varargout{3}=obj.readMagneticField;
            elseif (obj.EnableAccel && obj.EnableGyro && ~obj.EnableMag)
                varargout{1}=obj.readAngularRate;
                varargout{2}=obj.readAcceleration;
            elseif (obj.EnableAccel && ~obj.EnableGyro && obj.EnableMag)
                varargout{1}=obj.readAcceleration;
                varargout{2}=obj.readMagneticField;
            elseif (~obj.EnableAccel && obj.EnableGyro && obj.EnableMag)
                varargout{1}=obj.readAngularRate;
                varargout{2}=obj.readMagneticField;
            else
                if obj.EnableAccel
                    varargout{1}=obj.readAcceleration;
                end
                if obj.EnableGyro
                    varargout{1}=obj.readAngularRate;
                end
                if obj.EnableMag
                    varargout{1}=obj.readMagneticField;
                end
            end
        end
        
        function releaseImpl(obj)
            % Initialize discrete-state properties.
            if obj.EnableAccel || obj.EnableGyro
                close(obj.i2cobj_A_G);
            end
            if obj.EnableMag
                close(obj.i2cobj_MAG);
            end
        end
        
        function N = getNumInputsImpl(~)
            % Specify number of System inputs
            N = 0;
        end
        
        function N = getNumOutputsImpl(obj)
            % Specify number of System outputs
            N = 0;
            if obj.EnableAccel
                N = N+1;
            end
            if obj.EnableGyro
                N = N+1;
            end
            if obj.EnableMag
                N = N+1;
            end
        end
        
        function varargout = getOutputNamesImpl(obj)
            % Return output port names for System block
            if (obj.EnableAccel && obj.EnableGyro && obj.EnableMag)
                varargout{1}='AngularRate';
                varargout{2}='Acceleration';
                varargout{3}='MagneticField';
            elseif (obj.EnableAccel && obj.EnableGyro && ~obj.EnableMag)
                varargout{1}='AngularRate';
                varargout{2}='Acceleration';
            elseif (obj.EnableAccel && ~obj.EnableGyro && obj.EnableMag)
                varargout{1}='Acceleration';
                varargout{2}='MagneticField';
            elseif (~obj.EnableAccel && obj.EnableGyro && obj.EnableMag)
                varargout{1}='AngularRate';
                varargout{2}='MagneticField';
            else
                if obj.EnableAccel
                    varargout{1}='Acceleration';
                end
                if obj.EnableGyro
                    varargout{1}='AngularRate';
                end
                if obj.EnableMag
                    varargout{1}='MagneticField';
                end
            end
        end
        
        function varargout= getOutputSizeImpl(obj)
            % Return size for each output port
            n = obj.EnableAccel + obj.EnableGyro + obj.EnableMag;
            switch (n)
                case 1
                    varargout{1} = [1 3];
                case 2
                    varargout{1} = [1 3];
                    varargout{2} = [1 3];
                case 3
                    varargout{1} = [1 3];
                    varargout{2} = [1 3];
                    varargout{3} = [1 3];
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            n = obj.EnableAccel + obj.EnableGyro + obj.EnableMag;
            switch (n)
                case 1
                    varargout{1} = 'double';
                case 2
                    varargout{1} = 'double';
                    varargout{2} = 'double';
                case 3
                    varargout{1} = 'double';
                    varargout{2} = 'double';
                    varargout{3} = 'double';
            end
        end
        
        function varargout  = isOutputComplexImpl(obj)
            n = obj.EnableAccel + obj.EnableGyro + obj.EnableMag;
            switch (n)
                case 1
                    varargout{1} = false;
                case 2
                    varargout{1} = false;
                    varargout{2} = false;
                case 3
                    varargout{1} = false;
                    varargout{2} = false;
                    varargout{3} = false;
            end
        end
        
        function varargout   = isOutputFixedSizeImpl(obj)
            n = obj.EnableAccel + obj.EnableGyro + obj.EnableMag;
            switch (n)
                case 1
                    varargout{1} = true;
                case 2
                    varargout{1} = true;
                    varargout{2} = true;
                case 3
                    varargout{1} = true;
                    varargout{2} = true;
                    varargout{3} = true;
            end
        end
        
        function st = getSampleTimeImpl(obj)
            st = obj.SampleTime;
        end
    end
    
    methods(Static, Access = protected)
        % Note that this is ignored for the mask-on-mask
        function header = getHeaderImpl
            %getHeaderImpl Create mask header
            %   This only has an effect on the base mask.
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', 'LSM9DS1', ...
                'Text', '9DoF IMU Sensor.', ...
                'ShowSourceLink', false);
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'LSM9DS1 IMU sensor';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            codertarget.raspi.internal.I2CMasterRead.updateBuildInfo(buildInfo, context);
        end
    end
    
    methods(Access = protected, Static)
        function simMode = getSimulateUsingImpl
            % Return only allowed simulation mode in System block dialog
            simMode = 'Interpreted execution';
        end
        
        function flag = showSimulateUsingImpl
            % Return false if simulation mode hidden in System block dialog
            flag = false;
        end
        
        
    end
end

