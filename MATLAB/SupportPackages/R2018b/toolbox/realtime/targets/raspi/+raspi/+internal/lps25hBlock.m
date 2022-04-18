classdef lps25hBlock < codertarget.raspi.internal.I2CMasterWrite
    %LPS25h MEMS pressure Sensor.
    %
    % <a href="http://www.st.com/web/en/resource/technical/document/datasheet/DM00066332.pdf">Device Datasheet</a>
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    
    
    properties (Nontunable)
        %Sensor output data rate (ODR)
        OutputDataRate = '25 Hz';
        %Sample time
        SampleTime = 0.1;
    end
    
    properties (Dependent,Hidden)
        OuputDataRateEnum
    end
    
    properties (Access=private,Nontunable)
        Address=uint8(bin2dec('1011100'));
    end
    
    
    properties (Access = protected)
        p_h
        p_l
        p_xl
        t_h
        t_l
        p_data
        CTRL_REG1_Value = bin2dec('10000000');
    end
    
    properties (Constant,Hidden)
        OutputDataRateSet = matlab.system.StringSet({'1 Hz','7 Hz','12.5 Hz','25 Hz'});
        REF_P_XL = hex2dec('08');
        REF_P_L = hex2dec('09');
        REF_P_H = hex2dec('0A');
        WHO_AM_I= hex2dec('0F');
        RES_CONF= hex2dec('10');
        CTRL_REG1= hex2dec('20');
        CTRL_REG2= hex2dec('21');
        CTRL_REG3= hex2dec('22');
        CTRL_REG4= hex2dec('23');
        INTERRUPT_CFG= hex2dec('24');
        INT_SOURCE= hex2dec('25');
        STATUS_REG= hex2dec('27');
        PRESS_OUT_XL= hex2dec('28');
        PRESS_OUT_L= hex2dec('29');
        PRESS_OUT_H= hex2dec('2A');
        TEMP_OUT_L= hex2dec('2B');
        TEMP_OUT_H= hex2dec('2C');
        FIFO_CTRL= hex2dec('2E');
        FIFO_STATUS= hex2dec('2F');
        THS_P_L= hex2dec('30');
        THS_P_H= hex2dec('31');
        RPDS_L= hex2dec('39');
        RPDS_H= hex2dec('3A');
        WHO_AM_I_VAL   = bin2dec('10111101');
    end
    
    methods
        function obj = lps25hBlock(varargin)
            coder.allowpcode('plain');
        end
        
        function varargout = lps25hWriteRegister(obj,RegisterAddress,RegisterValue,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            status = writeRegister(obj,RegisterAddress,RegisterValue,DataType);
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        function [RegisterValue,varargout] = lps25hReadRegister(obj,RegisterAddress,DataLength,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            [RegisterValue,status] = readRegister(obj,RegisterAddress,DataLength,DataType);
            if nargout > 1
                varargout{1} = status;
            end
        end
        function pressure = readPressure(obj)
            %pressure = readPressure(obj) reads the value of
            %pressure measured by lps25h sensor.
            data= lps25hReadRegister(obj,bitor(obj.PRESS_OUT_XL,hex2dec('80')),3,'uint8');
            obj.p_xl=double(data(1)) ;
            obj.p_l=bitshift(double(data(2)),8);
            obj.p_h=bitshift(double(data(3)),16);
            pressure=(bitor(obj.p_h,bitor(obj.p_l,obj.p_xl))/4096);
        end
        
        function temperature = readTemperature(obj)
            %temperature = readTemperature(obj) reads the
            %temperature measured by lps25h sensor.
            data= lps25hReadRegister(obj,bitor(obj.TEMP_OUT_L,hex2dec('80')),2,'uint8');
            obj.t_l=int16(data(1));
            obj.t_h=bitshift(int16(data(2)),8);
            temperature=(42.5+(double(bitor(obj.t_h,obj.t_l))/480));
        end
    end%methods
    
    methods
        function OutputDataRate = get.OuputDataRateEnum(obj)
            switch(obj.OutputDataRate)
                case '1 Hz'
                    OutputDataRate = uint8(1);
                case '7 Hz'
                    OutputDataRate = uint8(2);
                case '12.5 Hz'
                    OutputDataRate = uint8(3);
                case '25 Hz'
                    OutputDataRate = uint8(4);
                otherwise
                    OutputDataRate = uint8(1);
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
        
        function st = getSampleTimeImpl(obj)
            st = obj.SampleTime;
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
        
        function [pressure,temperature] = stepImpl(obj)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            temperature = readTemperature(obj);
            pressure = readPressure(obj);
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
            name = 'Pressure';
            name2 = 'Temp';
        end
        
        function [pressure,temperature] = getOutputSizeImpl(~)
            % Return size for each output port
            temperature = [1 1];
            pressure = [1 1];
            
            % Example: inherit size from first input port
            % out = propagatedInputSize(obj,1);
        end
        
        function [pressure,temperature] = getOutputDataTypeImpl(~)
            % Return data type for each output port
            temperature = 'double';
            pressure = 'double';
            
            % Example: inherit data type from first input port
            % out = propagatedInputDataType(obj,1);
        end
        
        function [pressure,temperature] = isOutputComplexImpl(~)
            % Return true for each output port with complex data
            temperature = false;
            pressure = false;
            
            % Example: inherit complexity from first input port
            % out = propagatedInputComplexity(obj,1);
        end
        
        function [pressure,temperature]  = isOutputFixedSizeImpl(~)
            % Return true for each output port with fixed size
            temperature = true;
            pressure = true;
            
            % Example: inherit fixed-size status from first input port
            % out = propagatedInputFixedSize(obj,1);
        end
        
    end
    
    methods(Static, Access = protected)
        % Note that this is ignored for the mask-on-mask
        function header = getHeaderImpl
            %getHeaderImpl Create mask header
            %   This only has an effect on the base mask.
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', 'LPS25H Pressure Sensor', ...
                'Text', ['Measure barometric air pressure and ambient temperature.' newline newline ...
                'The block outputs barometric air pressure as a double in hectoPascal (hPa) and ambient temperature as a double in degree Celsius (C).'], ...
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
    
    methods(Access = protected)
         function maskDisplayCmds = getMaskDisplayImpl(~)
              maskDisplayCmds = [ ...
                ['color(''white'');',newline]...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...  
                ['sppkgroot = strrep(codertarget.raspi.internal.getSpPkgRootDir(),''\'',''/'');',newline]...
                ['image(fullfile(sppkgroot,''blocks'',''sensehat_lps25h.jpg''),''center'')',newline]...
                ['text(65,90, '' RASPBERRYPI '', ''horizontalAlignment'', ''right'');',newline]  ...
                ['color(''black'');',newline]...
                ['port_label(''output'', 1, ''Pressure'');', newline] ...
                ['port_label(''output'', 2, ''Temp'');', newline]...
                ];
            
         end
    end 
    
    
    methods(Access = protected)
        function initSensor(obj)
            % CTRL1 = PD(ON), BDU = 0 , ODR1/ODR0 = 12.5 Hz
            lps25hWriteRegister(obj,obj.CTRL_REG1,(obj.CTRL_REG1_Value+(16*obj.OuputDataRateEnum)),'uint8');
            lps25hWriteRegister(obj,obj.RES_CONF,hex2dec('05'),'uint8');
            lps25hWriteRegister(obj,obj.FIFO_CTRL,hex2dec('c0'),'uint8');
            lps25hWriteRegister(obj,obj.CTRL_REG2,hex2dec('40'),'uint8');
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'LPS25H pressure sensor';
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

