classdef hts221Block < codertarget.raspi.internal.I2CMasterWrite
    %HTS221 Capacitive digital sensor for relative humidity and
    %temperature.
    %
    % <a href="http://www.st.com/web/en/resource/technical/document/datasheet/DM00116291.pdf">Device Datasheet</a>
    
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    
    properties (Nontunable)
        %Sensor output data rate (ODR)
        OutputDataRate = '12.5 Hz';
        %Sample time
        SampleTime = 0.1;
    end
    
    properties (Hidden)
        blockPlatform = 'RASPBERRYPI';
    end
        
    properties (Dependent,Hidden)
        OuputDataRateEnum;
    end
    
    properties (Access=private,Nontunable)
        Address=uint8(bin2dec('1011111'));
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
   
    
    properties(Constant, Hidden)
        OutputDataRateSet = matlab.system.StringSet({'1 Hz','7 Hz','12.5 Hz'});
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
        WHO_AM_I_VAL   = bin2dec('10111100')
        AvailableNumAvgTempSamp=[2, 4, 8, 16, 32, 64, 128, 256];
        AvailableNumAvgHumSamp= [4, 8, 16, 32, 64, 128, 256, 512];
    end
    
    methods
        function obj = hts221Block()
            coder.allowpcode('plain');
        end
        
        function varargout = hts221WriteRegister(obj,RegisterAddress,RegisterValue,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            status = writeRegister(obj,RegisterAddress,RegisterValue,DataType);
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        function [RegisterValue,varargout] = hts221ReadRegister(obj,RegisterAddress,DataLength,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            [RegisterValue,status] = readRegister(obj,RegisterAddress,DataLength,DataType);
            if nargout > 1
                varargout{1} = status;
            end
        end
        
        
        function temperature = readTemperature(obj)
            %temperature = readTemperature(obj) reads the
            %temperature measured by the hts221 sensor.
            data = hts221ReadRegister(obj,bitor(obj.TEMP_OUT_L,hex2dec('80')),2,'uint8');
            Tout = double(typecast(data,'int16'));
            temperature = (Tout - obj.T0_out)/(obj.T1_out - obj.T0_out) * (obj.T1_degC - obj.T0_degC) + obj.T0_degC;
        end
        
        function humidity = readHumidity(obj)
            %humidity = readHumidity(obj) reads the value of
            %humidity measured by hts221.
            data = hts221ReadRegister(obj,bitor(obj.HUMIDITY_OUT_L,hex2dec('80')),2,'uint8');
            Hout = double(typecast(data,'int16'));
            humidity = (Hout - obj.H0_T0_out) / (obj.H1_T0_out - obj.H0_T0_out) * (obj.H1_rh - obj.H0_rh) + obj.H0_rh;
            
        end
    end
    
    methods
        function OutputDataRate = get.OuputDataRateEnum(obj)
            switch(obj.OutputDataRate)
                case '1 Hz'
                    OutputDataRate = uint8(1);
                case '7 Hz'
                    OutputDataRate = uint8(2);
                case '12.5 Hz'
                    OutputDataRate = uint8(3);
                otherwise
                    OutputDataRate = uint8(1);
            end
        end
    end
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            obj.SlaveAddress = obj.Address;
            open(obj,100000);
            initSensor(obj);
        end
        
        function [humidity,temperature] = stepImpl(obj)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            temperature = readTemperature(obj);
            humidity = readHumidity(obj);
        end
        
        
        function N = getNumInputsImpl(~)
            % Specify number of System inputs
            N = 0;
        end
        
        function N = getNumOutputsImpl(~)
            % Specify number of System outputs
            N = 2;
        end
        
        function [name,name2] = getOutputNamesImpl(~)
            % Return output port names for System block
            name = 'Humidity';
            name2 = 'Temp';
        end
        
        function [temperature,humidity] = getOutputSizeImpl(~)
            % Return size for each output port
            temperature = [1 1];
            humidity = [1 1];
        end
        
        function [humidity,temperature] = getOutputDataTypeImpl(~)
            % Return data type for each output port
            temperature = 'double';
            humidity = 'double';
        end
        
        function [humidity,temperature]  = isOutputComplexImpl(~)
            % Return true for each output port with complex data
            temperature = false;
            humidity = false;
        end
        
        function [humidity,temperature]   = isOutputFixedSizeImpl(~)
            % Return true for each output port with fixed size
            temperature = true;
            humidity = true;
        end
        
    end
    
    methods(Static, Access = protected)
        % Note that this is ignored for the mask-on-mask
        function header = getHeaderImpl
            %getHeaderImpl Create mask header
            %   This only has an effect on the base mask.
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', 'HTS221 Humidity Sensor', ...
                'Text', ['Measure relative humidity and ambient temperature.' newline newline ...
                'The block outputs relative humidity as a double in percentage(%) and ambient temperature as a double in degree Celsius (C).'], ...
                'ShowSourceLink', false);
        end
        
        function groups = getPropertyGroupsImpl
            
            % BoardProperty
            BoardProperty = matlab.system.display.internal.Property('BoardProperty', 'Description', 'Board');
            %OutputDataRate
            OutputDataRate = matlab.system.display.internal.Property('OutputDataRate', 'Description', 'Sensor output data rate (ODR)');
            % Sample Time
            Sampletime = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            
            % Replace I2C Module with BoardProperty
            PropertyListOut = {BoardProperty,OutputDataRate, Sampletime};
            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            
        end       
    end
    
    methods ( Access = protected)
         function maskDisplayCmds = getMaskDisplayImpl(~)
              maskDisplayCmds = [ ...
                ['color(''white'');',newline]...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...                
                ['sppkgroot = strrep(codertarget.raspi.internal.getSpPkgRootDir(),''\'',''/'');',newline]...
                ['image(fullfile(sppkgroot,''blocks'',''sensehat_hts221.jpg''),''center'')',newline]...
                ['text(65,90, '' RASPBERRYPI '', ''horizontalAlignment'', ''right'');',newline]  ...
                ['color(''black'');',newline]...
                ['port_label(''output'', 1, ''Humidity'');', newline] ...
                ['port_label(''output'', 2, ''Temp'');', newline]...
                ];
            
         end
    end
    
    methods
         function set.SampleTime(obj,newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');
            if isLocked(obj)
                error(message('svd:svd:SampleTimeNonTunable'))
            end
            newTime = matlabshared.svd.internal.validateSampleTime(newTime);
            obj.SampleTime = newTime;
        end
        
        function st = getSampleTimeImpl(obj)
            st = obj.SampleTime;
        end
    end
    
    methods(Access=protected)
        function initSensor(obj)
            % CTRL1 = PD(ON), BDU = 0 , ODR1/ODR0 = as per the property
            hts221WriteRegister(obj,obj.CTRL_REG1,(bin2dec('10000000')+obj.OuputDataRateEnum),'uint8');
            % AV_CONF = AVGT = 16, AVGH = 32.
            hts221WriteRegister(obj,obj.AV_CONF,bin2dec('00011011'),'uint8');
            % Read calibration data. Set MSB of register CALIB_0_REG to '1'
            % to enable auto address increment for bulk reading of all
            % calibration registers
            data = hts221ReadRegister(obj,bitor(obj.CALIB_0_REG,hex2dec('80')),16,'uint8');
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
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'HTS221 humidity sensor';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw') || context.isCodeGenTarget('sfun');
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




