classdef lsm9ds1 < matlab.System & matlab.I2C.Slave
    %LSM9DS1 9 DOF IMU sensor.
    %
    % <a href="http://www.st.com/web/en/resource/technical/document/datasheet/DM00066332.pdf">Device Datasheet</a>
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    
    properties(Constant)
        Name = 'LSM9DS1 IMU Sensor';
    end
    
    properties (Nontunable, Hidden)
        Protocol = 'I2C'; % Communication protocol
    end
    
    properties(Hidden,Access = private)
        Map = containers.Map();
        Initialized = false;
        GyroEnabled = false;
        AccelEnabled = false;
        MagEnabled = false;
    end
    
    properties (Nontunable, GetAccess = private)
        CommChannel_XLG
        CommChannel_Mag
        Master
    end
    
    properties
        GyroscopeOutputDataRate = 119;
        GyroscopeFullScaleRange = 245;
        GyroscopeBandwidthMode  = 0;
        GyroscopeHighPassFilterEnabled = false;
        GyroscopeHighPassFilterMode = 0;
        AccelerometerOutputDataRate = 119;
        AccelerometerFullScaleRange = 2;
        AccelerometerBandwidth = 50;
        MagnetometerOutputDataRate = 40;
        MagnetometerFullScaleRange = 4;
    end
    
    
    properties (Dependent,Hidden)
        GyroOutputDataRateEnum
        GyroFullScaleEnum
        AccelOutputDataRateEnum
        AccelFullScaleEnum
        AccelBandWidthEnum
        MagOutputDataRateEnum
        MagFullScaleEnum
    end
    
    properties(Hidden)
        CalGyroA = [1 0 0;0 1 0;0 0 1];
        CalGyroB = [0 0 0];
        
        CalAccelA = [1 0 0;0 1 0;0 0 1];
        CalAccelB = [0 0 0];
        
        CalMagA = [1 0 0;0 1 0;0 0 1];
        CalMagB = [0 0 0];
    end
    
    properties(GetAccess=public,SetAccess=private)
        GyroandAccelAddress = hex2dec('6A');
        MagnetometerAddress = hex2dec('1C');
    end
    
    properties(Constant, Access = private)
        AvailableGyroOutputDataRate = [14.9, 59.5, 119, 238, 476, 952];
        AvailableGyroFullScale = [245, 500, 2000];
        AvailableGyroBandWidthMode = [0, 1, 2, 3];
        AvailableGyroHPFMode = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        AvailableGyroHPFEnableOptions=[true,false];
        AvailableAccelOutputDataRate=[10, 50, 119, 238, 476, 952];
        AvailableAccelFullScale=[2, 4, 8, 16];
        AvailableAccelBandWidth=[50, 105, 211, 408];
        AvailableMagOutputDataRate=[0.625, 1.25, 2.5, 5, 10, 20, 40, 80];
        AvailableMagFullScale=[4, 8, 12, 16];
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
    
    methods %constructor and read methods
        function obj = lsm9ds1(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments when constructing the
            % object.
            setProperties(obj,nargin,varargin{:});
            obj.MaximumI2CSpeed = 400e3;
            checkI2CMasterCompatible(obj,obj.Master);
            obj.CommChannel_XLG = matlab.I2C.BusTransactor(obj.Master);
            obj.CommChannel_Mag = matlab.I2C.BusTransactor(obj.Master);
            % BusTransactor has to store all slave device address,
            % mode, speed info for the
            % read/write/readRegister/writeRegister to work across
            % supported protocols I2C, SPI and Serial
            obj.CommChannel_XLG.Bus = obj.Bus;
            obj.CommChannel_Mag.Bus = obj.Bus;
            obj.CommChannel_XLG.Address = obj.GyroandAccelAddress;
            obj.CommChannel_Mag.Address = obj.MagnetometerAddress;
            openCommChannel(obj.CommChannel_XLG);
            openCommChannel(obj.CommChannel_Mag);
            initSensor(obj);
            markUsed(obj,obj.Name);
            obj.Initialized = true;
            obj.GyroEnabled = true;
            obj.AccelEnabled = true;
            obj.MagEnabled = true;
        end
    end %methods - constructor and read methods
    
    methods(Access = protected) % sensor init and configurations
        function configureGyroscope(obj)
            %Configure gyroscope
            %Set CTRL_REG1_G
            writeRegister(obj.CommChannel_XLG, obj.CTRL_REG1_G, (bin2dec('00000000')+...
                (32*obj.GyroOutputDataRateEnum)+(8*obj.GyroFullScaleEnum)+obj.GyroscopeBandwidthMode));
            
            writeRegister(obj.CommChannel_XLG, obj.CTRL_REG2_G,bin2dec('00000000'));
            
            %Set CTRL_REG3_G
            writeRegister(obj.CommChannel_XLG, obj.CTRL_REG3_G, (bin2dec('00000000')+...
                (64*obj.GyroscopeHighPassFilterEnabled)+obj.GyroscopeHighPassFilterMode));
            
            writeRegister(obj.CommChannel_XLG, obj.CTRL_REG4,bin2dec('00111000'));
            
            writeRegister(obj.CommChannel_XLG, obj.ORIENT_CFG_G,bin2dec('00000000'));
        end
        
        function configureAccelerometer(obj)
            %Turn on X,Y,Z axes
            writeRegister(obj.CommChannel_XLG,obj.CTRL_REG5_XL,hex2dec('38'));
            
            %Configure CTRL_REG6_XLG to set outputdatarate
            reg = bin2dec('00000100') + (32 * obj.AccelOutputDataRateEnum) + ...
                (8 * obj.AccelFullScaleEnum) + obj.AccelBandWidthEnum;
            writeRegister(obj.CommChannel_XLG,obj.CTRL_REG6_XL,reg);
            
            %Low res mode
            writeRegister(obj.CommChannel_XLG,obj.CTRL_REG7_XL,hex2dec('00'));
            
            %Block data update= 0. little endian
            % [BOOT|BDU|H_LACTIVE|PP_OD|SIM|IF_ADD_INC|BLE|SW_RESET]
            % Turn on IF_ADD_INC to enable burst reads
            reg = bin2dec('00000100');
            writeRegister(obj.CommChannel_XLG,obj.CTRL_REG8,reg);
        end
        
        
        function configureMagnetometer(obj)
            %Configure CTRL_REG1_M to set the Output data rate
            writeRegister(obj.CommChannel_Mag, obj.CTRL_REG1_M,(bin2dec('00000000')+4*obj.MagOutputDataRateEnum));
            %configyre CTRL_REG2_M to set full scale settings for the
            %Magnetometer
            writeRegister(obj.CommChannel_Mag, obj.CTRL_REG2_M, (32*obj.MagFullScaleEnum));
            writeRegister(obj.CommChannel_Mag, obj.CTRL_REG3_M, 0); %Continuous conversion
            writeRegister(obj.CommChannel_Mag, obj.CTRL_REG4_M, 0); %z-axis on, little endian
            writeRegister(obj.CommChannel_Mag, obj.CTRL_REG5_M, hex2dec('0'));
        end
        
        function setSensorParams(obj,sensor)
            if obj.Initialized
                switch(sensor)
                    case 'gyro'
                        configureGyroscope(obj);
                    case 'accel'
                        configureAccelerometer(obj);
                    case 'mag'
                        configureMagnetometer(obj);
                end
            end
        end
    end
    
    methods
        function disableGyroscope(obj)
            %Disable Gyroscope
            writeRegister(obj.CommChannel_XLG, obj.CTRL_REG1_G, bin2dec('00000000'));
            obj.GyroEnabled = false;
        end
        
        function disableAccelerometer(obj)
            %Disable Accelerometer
            writeRegister(obj.CommChannel_XLG, obj.CTRL_REG6_XL, bin2dec('00000100'));
            obj.AccelEnabled = false;
        end
        
        function disableMagnetometer(obj)
            %Disable Magnetometer
            writeRegister(obj.CommChannel_Mag, obj.CTRL_REG3_M, 3);
            obj.MagEnabled = false;
        end
        
        function enableGyroscope(obj)
            %Enable Gyroscope
            writeRegister(obj.CommChannel_XLG, obj.CTRL_REG1_G, (bin2dec('00000000')+...
                (32*obj.GyroOutputDataRateEnum)+(8*obj.GyroFullScaleEnum)+obj.GyroscopeBandwidthMode));
            obj.GyroEnabled = true;
        end
        
        function enableAccelerometer(obj)
            %Enable Accelerometer
            writeRegister(obj.CommChannel_XLG, obj.CTRL_REG6_XL,(bin2dec('00000100')...
                +(32*obj.AccelerometerOutputDataRate)+(8*obj.AccelerometerFullScaleRange)+obj.AccelerometerBandwidth));
            obj.AccelEnabled = true;
        end
        
        function enableMagnetometer(obj)
            %Enable Magnetometer
            writeRegister(obj.CommChannel_Mag, obj.CTRL_REG3_M, 0);
            obj.MagEnabled = true;
        end
        
        function enableSensor(obj)
            %enableSensor(obj) enables sensors of lsm9ds1 sensor.
            %All sensor are enabled by default. Reading from a sensor is
            %permitted only when it is enabled.
            enableGyroscope(obj);
            enableAccelerometer(obj);
            enableMagnetometer(obj);
            obj.GyroEnabled = true;
            obj.AccelEnabled = true;
            obj.MagEnabled = true;
        end
        
        function disableSensor(obj)
            %disableSensor(obj) disable the lsm9ds1 sensor.
            disableGyroscope(obj);
            disableAccelerometer(obj);
            disableMagnetometer(obj);
            obj.GyroEnabled = false;
            obj.AccelEnabled = false;
            obj.MagEnabled = false;
        end
        
        function [angularVelocity,ts] = readAngularVelocity(obj,varargin)
            % angularVelocity =readAngularVelocity(obj) reads a 1-by-3 vector of angular
            % rate measured by the gyroscope of the ls,9ds1 sensor.
            %
            % angularVelocity =readAngularVelocity(obj,'raw') reads the raw
            % uncalibrated value of angular velocity.
            if ~obj.GyroEnabled
                error(message('raspi:utils:SensorDisabled',...
                    'LSM9DS1-IMU sensor-Gyroscope','Angular Rate'));
            end
            narginchk(1,2);
            if nargin > 1
                if ~strcmpi(varargin{1},'raw')
                    error(message('raspi:utils:InvalidValue','second input argument',' ''raw'''));
                end
            end
            
            angularVelocity = double(readRegister(obj.CommChannel_XLG,obj.OUT_X_L_G,'int16',3));
            if (nargin < 2)
                angularVelocity = (angularVelocity * obj.CalGyroA + obj.CalGyroB) ...
                    * obj.GyroscopeFullScaleRange / 32768;
            end
            if nargout > 1
                ts = datetime;
            end
        end
        
        function [acceleration,ts] = readAcceleration(obj,varargin)
            % acceleration =readAcceleration(obj) reads a 1-by-3 vector of acceleration
            % measured by the accelerometer of the lsm9ds1 sensor.
            %
            % acceleration =readAcceleration(obj,'raw') reads the raw
            % uncalibrated value of acceleration.
            if ~obj.AccelEnabled
                error(message('raspi:utils:SensorDisabled',...
                    'LSM9DS1-IMU sensor-Accelerometer','Acceleration'));
            end
            narginchk(1,2);
            if nargin > 1
                if nargin > 1
                    if ~strcmpi(varargin{1},'raw')
                        error(message('raspi:utils:InvalidValue','second input argument',' ''raw'''));
                    end
                end
            end
            
            acceleration = double(readRegister(obj.CommChannel_XLG,obj.OUT_X_L_XL,'int16',3));
            if (nargin < 2)
                acceleration = (acceleration * obj.CalAccelA + obj.CalAccelB) ...
                    * obj.AccelerometerFullScaleRange / 32768;
            end
            if nargout > 1
                ts = datetime;
            end
        end
        
        function [magneticField,ts] = readMagneticField(obj,varargin)
            % magneticField =readMagneticField(obj) reads a 1-by-3 vector of magneticField
            % measured by the magnetometer of the lsm9ds1 sensor.
            %
            % magneticField =readMagneticField(obj,'raw') reads the raw
            % uncalibrated value of magneticField.
            if ~obj.MagEnabled
                error(message('raspi:utils:SensorDisabled',...
                    'LSM9DS1-IMU sensor-Magnetometer','Magnetic Field'));
            end
            narginchk(1,2);
            if nargin > 1
                if nargin > 1
                    if ~strcmpi(varargin{1},'raw')
                        error(message('raspi:utils:InvalidValue','second input argument',' ''raw'''));
                    end
                end
            end
            
            magneticField = double(readRegister(obj.CommChannel_Mag,obj.OUT_X_L_M,'int16',3));
            if (nargin < 2)
                magneticField = (magneticField * obj.CalMagA + obj.CalMagB)...
                    * obj.MagnetometerFullScaleRange / 32768;
            end
            if nargout > 1
                ts = datetime;
            end
        end
    end %methods - sensor init and configurations
    
    methods  %set and get methods
        %------------------------------GYRO SETTINGS-----------------------
        function set.GyroscopeOutputDataRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'GyroscopeOutputDataRate');
            if ~ismember(value, obj.AvailableGyroOutputDataRate)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''GyroscopeOutputDataRate''settings'...
                    ,i_printAvailableValues(obj.AvailableGyroOutputDataRate)));
            end
            obj.GyroscopeOutputDataRate = value;
            setSensorParams(obj,'gyro');
        end
        
        
        function OutputDataRate = get.GyroOutputDataRateEnum(obj)
            if isequal(obj.GyroscopeOutputDataRate,14.9)
                OutputDataRate = uint8(1);
            elseif isequal(obj.GyroscopeOutputDataRate,59.5)
                OutputDataRate = uint8(2);
            elseif isequal(obj.GyroscopeOutputDataRate,119)
                OutputDataRate = uint8(3);
            elseif isequal(obj.GyroscopeOutputDataRate,238)
                OutputDataRate = uint8(4);
            elseif isequal(obj.GyroscopeOutputDataRate,476)
                OutputDataRate = uint8(5);
            elseif  isequal(obj.GyroscopeOutputDataRate,952)
                OutputDataRate = uint8(6);
            end
        end
        
        function set.GyroscopeFullScaleRange(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'GyroscopeFullScaleRange');
            if ~ismember(value, obj.AvailableGyroFullScale)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''GyroscopeFullScaleRange''settings'...
                    ,i_printAvailableValues(obj.AvailableGyroFullScale)));
            end
            obj.GyroscopeFullScaleRange= value;
            setSensorParams(obj,'gyro');
        end
        
        
        function FSR = get.GyroFullScaleEnum(obj)
            if isequal(obj.GyroscopeFullScaleRange,245)
                FSR = uint8(0);
            elseif isequal(obj.GyroscopeFullScaleRange,500)
                FSR = uint8(1);
            elseif isequal(obj.GyroscopeFullScaleRange,2000)
                FSR = uint8(3);
            end
        end
        
        function set.GyroscopeBandwidthMode(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'GyroscopeBandwidthMode');
            if ~ismember(value, obj.AvailableGyroBandWidthMode)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''GyroscopeBandwidthMode''settings'...
                    ,i_printAvailableValues(obj.AvailableGyroBandWidthMode)));
            end
            obj.GyroscopeBandwidthMode= value;
            setSensorParams(obj,'gyro');
        end
        
        
        function set.GyroscopeHighPassFilterEnabled(obj, value)
            validateattributes(value, {'numeric', 'logical'}, ...
                {'scalar'}, '', 'HighPassFilterEnabled');
            if isnumeric(value) && ~((value == 0) || (value == 1))
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''GyroscopeHighPassFilterEnabled''settings'...
                    ,i_printAvailableValues(obj.AvailableGyroHPFEnableOptions)));
            end
            obj.GyroscopeHighPassFilterEnabled = logical(value);
            setSensorParams(obj,'gyro');
        end
        
        function set.GyroscopeHighPassFilterMode(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'GyroscopeHighPassFilterMode');
            if ~ismember(value, obj.AvailableGyroHPFMode)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''GyroscopeHighPassFilterMode''settings'...
                    ,i_printAvailableValues(obj.AvailableGyroHPFMode)));
            end
            obj.GyroscopeHighPassFilterMode= value;
            setSensorParams(obj,'gyro');
        end
        
        %------------------------------Accelerometer Settings--------------------
        function set.AccelerometerOutputDataRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'AccelerometerOutputDataRate');
            if ~ismember(value, obj.AvailableAccelOutputDataRate)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''AccelerometerOutputDataRate''settings'...
                    ,i_printAvailableValues(obj.AvailableAccelOutputDataRate)));
            end
            obj.AccelerometerOutputDataRate= value;
            setSensorParams(obj,'accel');
        end
        
        
        function OutputDataRate = get.AccelOutputDataRateEnum(obj)
            if isequal(obj.AccelerometerOutputDataRate,10)
                OutputDataRate = uint8(1);
            elseif isequal(obj.AccelerometerOutputDataRate,50)
                OutputDataRate = uint8(2);
            elseif isequal(obj.AccelerometerOutputDataRate,119)
                OutputDataRate = uint8(3);
            elseif isequal(obj.AccelerometerOutputDataRate,238)
                OutputDataRate = uint8(4);
            elseif isequal(obj.AccelerometerOutputDataRate,476)
                OutputDataRate = uint8(5);
            elseif  isequal(obj.AccelerometerOutputDataRate,952)
                OutputDataRate = uint8(6);
            end
        end
        
        function set.AccelerometerFullScaleRange(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'AccelerometerFullScaleRange');
            if ~ismember(value, obj.AvailableAccelFullScale)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''AccelerometerFullScaleRange''settings'...
                    ,i_printAvailableValues(obj.AvailableAccelFullScale)));
            end
            obj.AccelerometerFullScaleRange= value;
            setSensorParams(obj,'accel');
        end
        
        
        function FSR = get.AccelFullScaleEnum(obj)
            if isequal(obj.AccelerometerFullScaleRange,2)
                FSR = uint8(0);
            elseif isequal(obj.AccelerometerFullScaleRange,4)
                FSR = uint8(2);
            elseif isequal(obj.AccelerometerFullScaleRange,8)
                FSR = uint8(3);
            elseif isequal(obj.AccelerometerFullScaleRange,16)
                FSR = uint8(1);
            end
        end
        
        function set.AccelerometerBandwidth(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'AccelerometerBandwidth');
            if ~ismember(value, obj.AvailableAccelBandWidth)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''AccelerometerBandwidth''settings'...
                    ,i_printAvailableValues(obj.AvailableAccelBandWidth)));
            end
            obj.AccelerometerBandwidth= value;
            setSensorParams(obj,'accel');
        end
        
        
        function LPF = get.AccelBandWidthEnum(obj)
            if isequal(obj.AccelerometerBandwidth,408)
                LPF = uint8(0);
            elseif isequal(obj.AccelerometerBandwidth,211)
                LPF = uint8(1);
            elseif isequal(obj.AccelerometerBandwidth,105)
                LPF = uint8(2);
            elseif isequal(obj.AccelerometerBandwidth,50)
                LPF = uint8(3);
            end
        end
        
        %------------------------------Magnetometer settings---------------------
        function set.MagnetometerOutputDataRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'AvailableMagOutputDataRate');
            if ~ismember(value, obj.AvailableMagOutputDataRate)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''MagnetometerOutputDataRate''settings'...
                    ,i_printAvailableValues(obj.AvailableMagOutputDataRate)));
            end
            obj.MagnetometerOutputDataRate= value;
            setSensorParams(obj,'mag');
        end
        
        function OutputDataRate = get.MagOutputDataRateEnum(obj)
            if isequal(obj.MagnetometerOutputDataRate,0.625)
                OutputDataRate = uint8(0);
            elseif isequal(obj.MagnetometerOutputDataRate,1.25)
                OutputDataRate = uint8(1);
            elseif isequal(obj.MagnetometerOutputDataRate,2.5)
                OutputDataRate = uint8(2);
            elseif isequal(obj.MagnetometerOutputDataRate,5)
                OutputDataRate = uint8(3);
            elseif isequal(obj.MagnetometerOutputDataRate,10)
                OutputDataRate = uint8(4);
            elseif  isequal(obj.MagnetometerOutputDataRate,20)
                OutputDataRate = uint8(5);
            elseif  isequal(obj.MagnetometerOutputDataRate,40)
                OutputDataRate = uint8(6);
            elseif  isequal(obj.MagnetometerOutputDataRate,80)
                OutputDataRate = uint8(7);
            end
        end
        
        function set.MagnetometerFullScaleRange(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'MagnetometerFullScaleRange');
            if ~ismember(value, obj.AvailableMagFullScale)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''MagnetometerFullScaleRange''settings'...
                    ,i_printAvailableValues(obj.AvailableMagFullScale)));
            end
            obj.MagnetometerFullScaleRange= value;
            setSensorParams(obj,'mag');
        end
        
        function FSR = get.MagFullScaleEnum(obj)
            if isequal(obj.MagnetometerFullScaleRange,4)
                FSR = uint8(0);
            elseif isequal(obj.MagnetometerFullScaleRange,8)
                FSR = uint8(1);
            elseif isequal(obj.MagnetometerFullScaleRange,12)
                FSR = uint8(2);
            elseif isequal(obj.MagnetometerFullScaleRange,16)
                FSR = uint8(3);
            end
        end
    end %methods- set and get
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            openCommChannel(obj.CommChannel_XLG);
            openCommChannel(obj.CommChannel_Mag);
            initSensor(obj);
        end
        
        function [angularVelocity,acceleration,magneticField] = stepImpl(obj)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            angularVelocity=obj.readAngularVelocity;
            acceleration=obj.readAcceleration;
            magneticField=obj.readMagneticField;
        end
        
        function releaseImpl(obj)
            % Initialize discrete-state properties.
            closeCommChannel(obj.CommChannel_XLG);
             closeCommChannel(obj.CommChannel_Mag);
        end
        
        function N = getNumInputsImpl(~)
            % Specify number of System inputs
            N = 0;
        end
        
        function N = getNumOutputsImpl(~)
            % Specify number of System outputs
            N = 2;
        end
        
        function flag = isInactivePropertyImpl(obj,prop)
            switch obj.Protocol
                case 'I2C'
                    inactiveProps = {'ChipSelect','Mode'};
                case 'SPI'
                    inactiveProps = {'Bus','Address'};
            end
            flag = ismember(prop,inactiveProps);
        end
        
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            % Display hts221 options
            %Display Gyroscope options
            fprintf('Gyroscope Options\n');
            fprintf('       GyroscopeOutputDataRate(Hz): %-15s  (%s)\n', ...
                num2str(obj.GyroscopeOutputDataRate), i_printAvailableValues(obj.AvailableGyroOutputDataRate));
            fprintf('      GyroscopeFullScaleRange(dps): %-15s  (%s)\n', ...
                num2str(obj.GyroscopeFullScaleRange), i_printAvailableValues(obj.AvailableGyroFullScale));
            fprintf('            GyroscopeBandwidthMode:  %-15s %s\n', ...
                num2str(obj.GyroscopeBandwidthMode), i_getHyperlinkAction(1));
            fprintf('    GyroscopeHighPassFilterEnabled:  %-15s (%s)\n', ...
                num2str(obj.GyroscopeHighPassFilterEnabled), i_printAvailableValues(obj.AvailableGyroHPFEnableOptions));
            fprintf('       GyroscopeHighPassFilterMode:  %-15s %s\n', ...
                num2str(obj.GyroscopeHighPassFilterMode), i_getHyperlinkAction(2));
            
            
            % Display Accelerometer options
            fprintf('\nAccelerometer Options\n');
            fprintf('   AccelerometerOutputDataRate(Hz): %-15s  (%s)\n', ...
                num2str(obj.AccelerometerOutputDataRate), i_printAvailableValues(obj.AvailableAccelOutputDataRate));
            fprintf('    AccelerometerFullScaleRange(g): %-15s  (%s)\n', ...
                num2str(obj.AccelerometerFullScaleRange),i_printAvailableValues(obj.AvailableAccelFullScale));
            fprintf('        AccelerometerBandwidth(Hz): %-15s  (%s)\n', ...
                num2str(obj.AccelerometerBandwidth), i_printAvailableValues(obj.AvailableAccelBandWidth));
            
            %Display Magnetometer options
            fprintf('\nMagnetometer Options\n');
            fprintf('    MagnetometerOutputDataRate(Hz): %-15s  (%s)\n', ...
                num2str(obj.MagnetometerOutputDataRate), i_printAvailableValues(obj.AvailableMagOutputDataRate));
            fprintf(' MagnetometerFullScaleRange(gauss): %-15s  (%s)\n', ...
                num2str(obj.MagnetometerFullScaleRange), i_printAvailableValues(obj.AvailableMagFullScale));
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end %displayscalrobject
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
    
    methods(Access=protected)
        function initSensor(obj)
            configureGyroscope(obj);
            configureAccelerometer(obj);
            configureMagnetometer(obj);
        end
        
        function terminateSensor(obj)
             closeCommChannel(obj.CommChannel_XLG);
             closeCommChannel(obj.CommChannel_Mag);
        end
        
        function ret = isUsed(obj, name)
            if isKey(obj.Map, obj.Master.DeviceAddress) && ...
                    ismember(name, obj.Map(obj.Master.DeviceAddress))
                ret = true;
            else
                ret = false;
            end
        end
        
        function markUsed(obj, name)
            if isKey(obj.Map, obj.Master.DeviceAddress)
                used = obj.Map(obj.Master.DeviceAddress);
                obj.Map(obj.Master.DeviceAddress) = union(used, name);
            else
                obj.Map(obj.Master.DeviceAddress) = {name};
            end
        end
        
        function markUnused(obj, name)
            if isKey(obj.Map, obj.Master.DeviceAddress)
                used = obj.Map(obj.Master.DeviceAddress);
                obj.Map(obj.Master.DeviceAddress) = setdiff(used, name);
            end
        end
    end
    
    methods
        function delete(obj)
            if obj.Initialized
                disableSensor(obj);
                terminateSensor(obj);
                obj.markUnused(obj.Name)
            end
        end
    end
    
    
end

%% Internal functions
function str = i_printAvailableValues(values)
str = '';
for i = 1:length(values)
    str = [str num2str(values(i))]; %#ok<AGROW>
    if i ~= length(values)
        str = [str, ', ']; %#ok<AGROW>
    end
end
end

function str = i_getHyperlinkAction(option)
if (option==1)
    str=sprintf(['<a href="matlab:raspi.internal.helpView', ...
        '(''raspberrypiio'',''RaspiSupportedPeripherals'')">', ...
        'View available Bandwidth modes</a>']);
else
    str=sprintf(['<a href="matlab:raspi.internal.helpView', ...
        '(''raspberrypiio'',''RaspiSupportedPeripherals'')">', ...
        'View available HighPassFilter modes</a>']);
end

end

