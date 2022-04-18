classdef hts221 < matlab.System ...
        & matlab.I2C.Slave & matlab.mixin.CustomDisplay
    %HTS221 Capacitive digital sensor for relative humidity and
    %temperature.
    %
    % <a href="http://www.st.com/web/en/resource/technical/document/datasheet/DM00116291.pdf">Device Datasheet</a>
    
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    
    properties (Constant)
        Name = 'HTS221 Humidity and Temperature Sensor';
    end
    
    properties (Nontunable,Hidden)
        Protocol = 'I2C'; % Communication protocol
    end
    
    properties(Access = private)
        Map = containers.Map();
        Initialized = false;
        Enabled=false;
    end
    
    properties (Nontunable, GetAccess = private)
        CommChannel
        Master
        Bus_hts221
    end
    
    properties
        OperationMode = 'continuous';
        OutputDataRate = 12.5;
    end
    
    properties (Dependent,Hidden)
        OuputDataRateEnum;
    end
    
    properties (Access = protected)
        T0_degC
        T1_degC
        T0_out
        T1_out
        H0_rh
        H1_rh
        H0_T0_out
        H1_T0_out
    end
    
    properties(Hidden)
        NumAvgTempSamp = 16;
        NumAvgHumSamp  = 32;
    end
    
    properties (Constant, Access = protected)
        WHO_AM_I       = hex2dec('0F')
        AV_CONF        = hex2dec('10')
        CTRL_REG1      = hex2dec('20')
        CTRL_REG2      = hex2dec('21')
        CTRL_REG3      = hex2dec('22')
        STATUS_REG     = hex2dec('27')
        HUMIDITY_OUT_L = hex2dec('28')
        HUMIDITY_OUT_H = hex2dec('29')
        TEMP_OUT_L     = hex2dec('2A')
        TEMP_OUT_H     = hex2dec('2B')
        CALIB_0_REG    = hex2dec('30')
        CALIB_F_REG    = hex2dec('3F')
        % Value for register
        WHO_AM_I_VAL   = bin2dec('10111100')
        AvailableNumAvgTempSamp=[2, 4, 8, 16, 32, 64, 128, 256];
        AvailableNumAvgHumSamp= [4, 8, 16, 32, 64, 128, 256, 512];
        AvailableODR = [1,7,12.5];
        AvailableOperationMode = {'one-shot','continuous'};
    end
    
    methods
        function obj = hts221(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments when constructing the
            % object.
            setProperties(obj,nargin,varargin{:});
            %Check if the sensor is already in use
            if isUsed(obj, obj.Name)
                error(message('raspi:utils:SenseHATInUse','hts221'));
            end
            %Set the address of the hts221 sensor address
            obj.Address = bin2dec('1011111');
            obj.MaximumI2CSpeed = 400e3;
            obj.Bus = obj.Bus_hts221;
            checkI2CMasterCompatible(obj,obj.Master);
            obj.CommChannel = matlab.I2C.BusTransactor(obj.Master);
            % BusTransactor has to store all slave device address,
            % mode, speed info for the
            % read/write/readRegister/writeRegister to work across
            % supported protocols I2C, SPI and Serial
%             obj.Bus = obj.Bus_hts221;
            obj.CommChannel.Bus = obj.Bus_hts221;
            obj.CommChannel.Address = obj.Address;
            openCommChannel(obj.CommChannel);
            initSensor(obj);
            markUsed(obj,obj.Name);
            obj.Initialized = true;
            obj.Enabled=true;
        end
        
        function temperature = readTemperature(obj)
            %temperature = readTemperature(obj) reads the
            %temperature measured by the hts221 sensor.
            if obj.Enabled
                if isequal(obj.OperationMode,'one-shot')
                    %set the CTRL_REG2 to start new dataset
                    writeRegister(obj.CommChannel,obj.CTRL_REG2,bin2dec('00000001'));
                    %wait until the measurtement is completed
                    while(~isequal(readRegister(obj.CommChannel,obj.CTRL_REG2,1),0))% check if readRegister has a timeout. This is required if the conversion fails.
                    end
                    data = readRegister(obj.CommChannel,bitor(obj.TEMP_OUT_L,hex2dec('80')),2);
                else
                    data = readRegister(obj.CommChannel,bitor(obj.TEMP_OUT_L,hex2dec('80')),2);
                end
                Tout = double(typecast(data,'int16'));
                temperature = (Tout - obj.T0_out)/(obj.T1_out - obj.T0_out) * (obj.T1_degC - obj.T0_degC) + obj.T0_degC;
            else
                error(message('raspi:utils:SensorDisabled','HTS221 - Humidity','temperature'));
            end
        end
        
        function humidity = readHumidity(obj)
            %humidity = readHumidity(obj) reads the value of
            %humidity measured by hts221.
            if obj.Enabled
                if isequal(obj.OperationMode,'one-shot')
                    %set the CTRL_REG2 to start new dataset
                    writeRegister(obj.CommChannel,obj.CTRL_REG2,bin2dec('00000001'));
                    %wait until the measurtement is completed
                    while(~isequal(readRegister(obj.CommChannel,obj.CTRL_REG2,1),0))
                    end
                    data = readRegister(obj.CommChannel,bitor(obj.HUMIDITY_OUT_L,hex2dec('80')),2);
                else
                    data = readRegister(obj.CommChannel,bitor(obj.HUMIDITY_OUT_L,hex2dec('80')),2);
                end
                Hout = double(typecast(data,'int16'));
                humidity = (Hout - obj.H0_T0_out) / (obj.H1_T0_out - obj.H0_T0_out) * (obj.H1_rh - obj.H0_rh) + obj.H0_rh;
            else
                error(message('raspi:utils:SensorDisabled','HTS221 - Humidity','humidity'));
            end
        end
    end
    
    methods
        function set.OperationMode(obj, value)
            value = validatestring(value, obj.AvailableOperationMode, ...
                '', 'OutputDtaRate');
            if ~ismember(value, obj.AvailableOperationMode)
                error(message('raspi:utils:InvalidSensorSetting',...
                    'Operation Mode',i_printAvailableStringValues(obj.AvailableOperationMode)));
            end
            obj.OperationMode=lower(value);
            obj.setSensorParams;
        end
            
        function set.OutputDataRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Mode');
            if ~ismember(value, obj.AvailableODR)
                error(message('raspi:utils:InvalidSensorSetting',...
                    'OutputDataRate',i_printAvailableValues(obj.AvailableODR)));
            end
            obj.OutputDataRate = value;
            obj.setSensorParams;
        end
        
        function OutputDataRate = get.OuputDataRateEnum(obj)
            if strcmpi(obj.OperationMode,'one-shot')
                OutputDataRate = uint8(0);
            elseif isequal(obj.OutputDataRate,1)
                OutputDataRate = uint8(1);
            elseif isequal(obj.OutputDataRate,7)
                OutputDataRate = uint8(2);
            elseif isequal(obj.OutputDataRate,12.5)
                OutputDataRate = uint8(3);
            end
        end
        
        function set.NumAvgTempSamp(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Mode');
            if ~ismember(value, obj.AvailableNumAvgTempSamp)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''Number of Temperature samples to average'''...
                    ,i_printAvailableValues(obj.AvailableNumAvgTempSamp)));
            end
            obj.NumAvgTempSamp= value;
            obj.setSensorParams;
        end
               
        function set.NumAvgHumSamp(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Mode');
            if ~ismember(value, obj.AvailableNumAvgHumSamp)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''Number of Humidity samples to average'''...
                    ,i_printAvailableValues(obj.AvailableNumAvgHumSamp)));
            end
            obj.NumAvgHumSamp= value;
            obj.setSensorParams;
        end
        
        function enableSensor(obj)
            writeRegister(obj.CommChannel,obj.CTRL_REG1,(bin2dec('10000000')+obj.OuputDataRateEnum));
            obj.Enabled=true;
        end
        
        function disableSensor(obj)
            writeRegister(obj.CommChannel,obj.CTRL_REG1,(bin2dec('10000000')+obj.OuputDataRateEnum-128));
            obj.Enabled=false;
        end
        
       
    end
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            openCommChannel(obj.CommChannel);
            initSensor(obj);
        end
        
        function [temperature, humidity] = stepImpl(obj)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            temperature = readTemperature(obj);
            humidity = readHumidity(obj);
        end
        
        function releaseImpl(obj)
            % Initialize discrete-state properties.
            closeCommChannel(obj.CommChannel);
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
                case 'SPI'
                    inactiveProps = {'ChipSelect','Mode'};
                case 'I2C'
                    inactiveProps = {'Bus','Address'};
            end
            flag = ismember(prop,inactiveProps);
        end
        
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            % Display hts221 options
            fprintf('                     OperationMode: %-15s  (%s)\n', ...
                obj.OperationMode, i_printAvailableStringValues(obj.AvailableOperationMode));
            fprintf('                OutputDataRate(Hz): %-15s  (%s)\n', ...
                num2str(obj.OutputDataRate), i_printAvailableValues(obj.AvailableODR));
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
                'Title', 'HTS221 Humidity Sensor', ...
                'Text', 'Capacitive digital sensor for relative humidity and temperature.', ...
                'ShowSourceLink', false);
        end
    end
    
    methods(Access=protected)
        function initSensor(obj)
            % CTRL1 = PD(ON), BDU = 0 , ODR1/ODR0 = as per the property
            NumAvgTemp=find(obj.AvailableNumAvgTempSamp==obj.NumAvgTempSamp)-1;
            NumAvgHum=find(obj.AvailableNumAvgHumSamp==obj.NumAvgHumSamp)-1;
            writeRegister(obj.CommChannel,obj.CTRL_REG1,(bin2dec('10000000')+obj.OuputDataRateEnum));
            writeRegister(obj.CommChannel,obj.AV_CONF,(bin2dec('00000000')+(NumAvgTemp*8)+(NumAvgHum)));
            % Read calibration data. Set MSB of register CALIB_0_REG to '1'
            % to enable auto address increment for bulk reading of all
            % calibration registers
            data = readRegister(obj.CommChannel,bitor(obj.CALIB_0_REG,hex2dec('80')),16);
            obj.T0_degC = double(typecast([data(3) bitand(data(6),3)],'int16'))/8;
            obj.T1_degC = double(typecast([data(4) bitshift(bitand(data(6),hex2dec('C')),-2)],'int16'))/8;
            obj.T0_out  = double(typecast(data(13:14),'int16'));
            obj.T1_out  = double(typecast(data(15:16),'int16'));
            
            % Humidity calibration coefficients
            obj.H0_rh = double(data(1))/2;
            obj.H1_rh = double(data(2))/2;
            obj.H0_T0_out = double(typecast(data(7:8),'int16'));
            obj.H1_T0_out = double(typecast(data(11:12),'int16'));
        end
        
         function terminateSensor(obj)
             closeCommChannel(obj.CommChannel);
         end
        
        function setSensorParams(obj)
            if obj.Initialized
                % CTRL1 = PD(ON), BDU = 0 , ODR1/ODR0 = as per the property
                NumAvgTemp=find(obj.AvailableNumAvgTempSamp==obj.NumAvgTempSamp)-1;
                NumAvgHum=find(obj.AvailableNumAvgHumSamp==obj.NumAvgHumSamp)-1;
                writeRegister(obj.CommChannel,obj.CTRL_REG1,(bin2dec('10000000')+obj.OuputDataRateEnum));
                writeRegister(obj.CommChannel,obj.AV_CONF,(bin2dec('00000000')+(NumAvgTemp*8)+(NumAvgHum)));
            end
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

function str = i_printAvailableValues(values)
str = '';
for i = 1:length(values)
    str = [str num2str(values(i))]; %#ok<AGROW>
    if i ~= length(values)
        str = [str, ', ']; %#ok<AGROW>
    end
end
end

function str = i_printAvailableStringValues(values)
str = '';
for i = 1:length(values)
    str = [str, '''' values{i}, '''']; %#ok<AGROW>
    if i ~= length(values)
        str = [str, ', ']; %#ok<AGROW>
    end
end
end
