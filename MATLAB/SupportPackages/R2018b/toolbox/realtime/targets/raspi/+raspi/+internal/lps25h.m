classdef lps25h < matlab.System & matlab.I2C.Slave
    %LPS25h MEMS pressure Sensor.
    %
    % <a href="http://www.st.com/web/en/resource/technical/document/datasheet/DM00066332.pdf">Device Datasheet</a>
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    
    properties(Constant)
        Name = 'LPS25H Pressure Sensor';
    end
    
    properties (Nontunable, Hidden)
        Protocol = 'I2C'; % Communication protocol
    end
    
    
    properties(Access = private)
        Map = containers.Map();
        Initialized = false;
        Opened = false;
        Enabled = false;
    end
    
    properties (Nontunable, GetAccess = private)
        CommChannel
        Master
    end
    
    properties
        OperationMode  = 'continuous';
        OutputDataRate = 25 ;
    end
    
    properties(Hidden)
        NumAvgTempSamp = 16;
        NumAvgPressureSamp = 32;
    end
    
    properties (Dependent,Hidden)
        OuputDataRateEnum;
    end
    
    properties (Access = private)
        p_h
        p_l
        p_xl
        t_h
        t_l
        p_data
        CTRL_REG1_Value = bin2dec('10000000');
    end
    
    properties (Constant,Access = private)
        REF_P_XL = hex2dec('08')
        REF_P_L = hex2dec('09')
        REF_P_H = hex2dec('0A')
        WHO_AM_I= hex2dec('0F')
        RES_CONF= hex2dec('10')
        CTRL_REG1= hex2dec('20')
        CTRL_REG2= hex2dec('21')
        CTRL_REG3= hex2dec('22')
        CTRL_REG4= hex2dec('23')
        INTERRUPT_CFG= hex2dec('24')
        INT_SOURCE= hex2dec('25')
        STATUS_REG= hex2dec('27')
        PRESS_OUT_XL= hex2dec('28')
        PRESS_OUT_L= hex2dec('29')
        PRESS_OUT_H= hex2dec('2A')
        TEMP_OUT_L= hex2dec('2B')
        TEMP_OUT_H= hex2dec('2C')
        FIFO_CTRL= hex2dec('2E')
        FIFO_STATUS= hex2dec('2F')
        THS_P_L= hex2dec('30')
        THS_P_H= hex2dec('31')
        RPDS_L= hex2dec('39')
        RPDS_H= hex2dec('3A')
        
        % Value for register
        WHO_AM_I_VAL   = bin2dec('10111101')
        
        % Supported parameters
        AvailableODR = [1, 7, 12.5, 25];
        AvailableNumAvgTempSamp = [8, 16, 32, 64];
        AvailableNumAvgPressureSamp = [8, 32, 128, 512];
        AvailableOperationMode = {'one-shot','continuous'};
    end
    
    methods
        function obj = lps25h(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments when constructing the
            % object.
            setProperties(obj,nargin,varargin{:});
            %Check if the sensor is already in use
            if isUsed(obj, obj.Name)
                error(message('raspi:utils:SenseHATInUse','lps25h'));
            end
            obj.Address = bin2dec('1011100');
            obj.MaximumI2CSpeed = 400e3;
            checkI2CMasterCompatible(obj,obj.Master);
            obj.CommChannel = matlab.I2C.BusTransactor(obj.Master);
            % BusTransactor has to store all slave device address,
            % mode, speed info for the
            % read/write/readRegister/writeRegister to work across
            % supported protocols I2C, SPI and Serial
            obj.CommChannel.Bus = obj.Bus;
            obj.CommChannel.Address = obj.Address;
            openCommChannel(obj.CommChannel);
            initSensor(obj);
            markUsed(obj,obj.Name);
            obj.Initialized = true;
            obj.Enabled=true;
        end
        
        function pressure = readPressure(obj)
            %pressure = readPressure(obj) reads the value of
            %pressure measured by lps25h sensor.
            if obj.Enabled
                if isequal(obj.OperationMode,'one-shot')
                    %set the CTRL_REG2 to start new dataset
                    writeRegister(obj.CommChannel,obj.CTRL_REG2,bin2dec('00000001'));
                    %wait until the measurtement is completed
                    while(~isequal(readRegister(obj.CommChannel,obj.CTRL_REG2,1),0))
                    end
                    data= readRegister(obj.CommChannel,bitor(obj.PRESS_OUT_XL,hex2dec('80')),3);
                else
                    data= readRegister(obj.CommChannel,bitor(obj.PRESS_OUT_XL,hex2dec('80')),3);
                end
                obj.p_xl=double(data(1)) ;
                obj.p_l=bitshift(double(data(2)),8);
                obj.p_h=bitshift(double(data(3)),16);
                pressure=(bitor(obj.p_h,bitor(obj.p_l,obj.p_xl))/4096);
            else
                error(message('raspi:utils:SensorDisabled','LPS25H - Air-Pressure','pressure'));
            end
        end
        
        function temperature = readTemperature(obj)
            %temperature = readTemperature(obj) reads the
            %temperature measured by lps25h sensor.
            if obj.Enabled
                if isequal(obj.OperationMode,'one-shot')
                    %set the CTRL_REG2 to start new dataset
                    writeRegister(obj.CommChannel,obj.CTRL_REG2,bin2dec('00000001'));
                    %wait until the measurtement is completed
                    while(~isequal(readRegister(obj.CommChannel,obj.CTRL_REG2,1),0))
                    end
                    data= readRegister(obj.CommChannel,bitor(obj.TEMP_OUT_L,hex2dec('80')),2);
                else
                    data= readRegister(obj.CommChannel,bitor(obj.TEMP_OUT_L,hex2dec('80')),2);
                end
                obj.t_l=int16(data(1));
                obj.t_h=bitshift(int16(data(2)),8);
                temperature=(42.5+(double(bitor(obj.t_h,obj.t_l))/480));
            else
                error(message('raspi:utils:SensorDisabled','LPS25H - Air-Pressure','temperature'));
            end
        end
        
    end%methods
    
    methods
        function set.OperationMode(obj, value)
            value = validatestring(value, obj.AvailableOperationMode, ...
                '', 'OutputDtaRate');
            if ~ismember(value, obj.AvailableOperationMode)
                error(message('raspi:utils:InvalidSensorSetting',...
                    'Operation Mode',i_printAvailableStringValues(obj.AvailableOperationMode)));
            end
            obj.OperationMode=value;
            obj.setSensorParams;
        end
        
        function set.OutputDataRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Mode');
            if ~ismember(value, obj.AvailableODR)
                error(message('raspi:utils:InvalidSensorSetting',...
                    'OutputDataRate ',i_printAvailableValues(obj.AvailableODR)));
            end
            obj.OutputDataRate = lower(value);
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
            elseif isequal(obj.OutputDataRate,25)
                OutputDataRate = uint8(4);
            end
        end
        
        function set.NumAvgTempSamp(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'NumAvgTempSamp');
            if ~ismember(value, obj.AvailableNumAvgTempSamp)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''Number of Temperature samples to average'''...
                    ,i_printAvailableValues(obj.AvailableNumAvgTempSamp)));
            end
            obj.NumAvgTempSamp= value;
            obj.setSensorParams;
        end
            
        function set.NumAvgPressureSamp(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'NumAvgPressureSamp');
            if ~ismember(value, obj.AvailableNumAvgPressureSamp)
                error(message('raspi:utils:InvalidSensorSetting',...
                    '''Number of Pressure samples to average'''...
                    ,i_printAvailableValues(obj.AvailableNumAvgPressureSamp)));
            end
            obj.NumAvgPressureSamp = value;
            obj.setSensorParams;
        end    
    end
    
    methods       
        function enableSensor(obj)
            writeRegister(obj.CommChannel,obj.CTRL_REG1,(obj.CTRL_REG1_Value+(16*obj.OuputDataRateEnum)));
            obj.Enabled=true;
        end
        
        function disableSensor(obj)
            writeRegister(obj.CommChannel,obj.CTRL_REG1,(obj.CTRL_REG1_Value+(16*obj.OuputDataRateEnum)-128));
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
        
        function [temperature, pressure] = stepImpl(obj)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            temperature = readtemperature(obj);
            pressure = readpressure(obj);
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
                'Title', 'LPS25H Pressure Sensor', ...
                'Text', 'MEMS Pressure Sensor.', ...
                'ShowSourceLink', false);
        end
    end
    
    methods(Access = protected)
        function initSensor(obj)
            % CTRL1 = PD(ON), BDU = 0 , ODR1/ODR0 = 12.5 Hz
            writeRegister(obj.CommChannel,obj.CTRL_REG1,(obj.CTRL_REG1_Value+(16*obj.OuputDataRateEnum)));
            writeRegister(obj.CommChannel,obj.RES_CONF,hex2dec('05'));
            writeRegister(obj.CommChannel,obj.FIFO_CTRL,hex2dec('c0'));
            writeRegister(obj.CommChannel,obj.CTRL_REG2,hex2dec('40'));
        end
        
         function terminateSensor(obj)
             closeCommChannel(obj.CommChannel);
        end
        
        function setSensorParams(obj)
            if obj.Initialized
                % CTRL1 = PD(ON), BDU = 0 , ODR1/ODR0 = According to the
                %property
                NumAvgTemp=find(obj.AvailableNumAvgTempSamp==obj.NumAvgTempSamp)-1;
                NumAvgPressure=find(obj.AvailableNumAvgPressureSamp==obj.NumAvgPressureSamp)-1;
                writeRegister(obj.CommChannel,obj.CTRL_REG1,(obj.CTRL_REG1_Value+(16*obj.OuputDataRateEnum)));
                writeRegister(obj.CommChannel,obj.RES_CONF,(bin2dec('00000000')+(NumAvgTemp*4)+(NumAvgPressure)));
                writeRegister(obj.CommChannel,obj.FIFO_CTRL,hex2dec('c0'));
                writeRegister(obj.CommChannel,obj.CTRL_REG2,hex2dec('40'));
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

