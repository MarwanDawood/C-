classdef raspi < handle ...
        & matlab.I2C.Master ...
        & matlab.SPI.Master
    %RASPI Access Raspberry Pi hardware peripherals.
    %
    % obj = RASPI(DEVICEADDRESS, USERNAME, PASSWORD) creates a RASPI object
    % connected to the Raspberry Pi hardware at DEVICEADDRESS with login
    % credentials USERNAME and PASSWORD. The DEVICEADDRESS can be an
    % IP address such as '192.168.0.10' or a hostname such as
    % 'raspberrypi-MJONES.foo.com'.
    %
    % obj = RASPI creates a RASPI object connected to Raspberry Pi hardware
    % using saved values for DEVICEADDRESS, USERNAME and PASSWORD.
    %
    % Type <a href="matlab:methods('raspi')">methods('raspi')</a> for a list of methods of the raspi object.
    %
    % Type <a href="matlab:properties('raspi')">properties('raspi')</a> for a list of properties of the raspi object.
    
    % Copyright 2013-2018 The MathWorks, Inc.
    %#codegen
    properties (SetAccess = private)
        AvailableI2CBuses
        I2CBusSpeed
        RaspiDisplay
    end
    
    properties (Hidden, SetAccess = private)
        DigitalPin = struct('Available',false,'Inuse',false,'Mode',1);
    end
    
    properties (Hidden, Constant)
        UPINMODESTR = {'unset','DigitalInput','DigitalOutput','PWM','Servo'}
        PINMODE_UNSET           = 1
        PINMODE_DI              = 2
        PINMODE_DO              = 3
        PINMODE_PWM             = 4
        PINMODE_SERVO           = 5
        AVAILABLE_PWM_FREQUENCY = [8000,4000,2000,1600,1000,800,500,400,320,...
            250,200,160,100,80,50,40,20,10]
        AvailableLeds = {'led0'};
        AvailableDigitalPins = [4,5,6,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27];
        VDD                     = 3.3
    end
    
    methods (Hidden)
        function obj = raspi(varargin)
            % Create a connection to Raspberry Pi hardware.
            %narginchk(0,0);
            
            pinConfigStruct = struct('Available',false,'Inuse',false,'Mode',1);
            obj.DigitalPin = repmat(pinConfigStruct,1,40);
            % Find available peripherals
            obj.getAvailablePeripherals();
            
            % New code for I2C master
            obj.AvailableI2CBuses = {'i2c-1'};
            %obj.AvailableI2CSpeeds = 100e3;
            obj.I2CBusSpeed = 100e3;
            obj.RaspiDisplay = raspi.internal.codegen.SDLVideoDisplay();
        end
    end
    
    methods (Access = protected)
        % I2C interface
        function ret = getAvailableI2CBusNumbers(obj) %#ok<*MANU>
            ret = 1;
        end
        
        function ret = getAvailableSPIChipSelect(obj)
            ret = [0,1];
        end
        
        function getAvailablePeripherals(obj)
            % Check of I2C
            % Initialize the current state of GPIO pins
            
            % TO-DO:
            % Get available pins based on the board
            for pin = obj.AvailableDigitalPins
                obj.DigitalPin(pin).Available = true;
            end
        end
        
        function checkDigitalPin(obj, pinNumber)
            validateattributes(pinNumber, {'numeric'}, {'scalar','>=',1,'<=',40}, ...
                '', 'the pin number');
            
            mustBeMember(pinNumber,obj.AvailableDigitalPins);
        end
        
        function checkWriteDigitalPin(obj,pinNumber)
            validateattributes(pinNumber, {'numeric'}, {'scalar','>=',1,'<=',40}, ...
                '', 'the pin number');
            
            % Configure the Pin as Output if it is not configured
            if (obj.DigitalPin(pinNumber).Mode == obj.PINMODE_UNSET)
                obj.configurePin(pinNumber,obj.UPINMODESTR{obj.PINMODE_DO});
            end
        
            if (~(obj.DigitalPin(pinNumber).Available) || ~(obj.DigitalPin(pinNumber).Mode == obj.PINMODE_DO))
                fprintf('Pin number %d is not configured for GPIO output\n',int32(pinNumber));
                coder.ceval('main_terminate');
            end
        end
        
        function checkReadDigitalPin(obj,pinNumber)
            validateattributes(pinNumber, {'numeric'}, {'scalar','>=',1,'<=',40}, ...
                '', 'the pin number');
            
            % Configure the Pin as Input if it is not configured
            if (obj.DigitalPin(pinNumber).Mode == obj.PINMODE_UNSET)
                obj.configurePin(pinNumber,obj.UPINMODESTR{obj.PINMODE_DI});
            end
            
            if (~(obj.DigitalPin(pinNumber).Available) || ~(obj.DigitalPin(pinNumber).Mode == obj.PINMODE_DI))
                fprintf('Pin number %d is not configured for GPIO input\n',int32(pinNumber));
                coder.ceval('main_terminate');
            end
        end
        
        function checkPWMPin(obj,pinNumber)
            validateattributes(pinNumber, {'numeric'}, {'scalar','>=',1,'<=',40}, ...
                '', 'the pin number');
            
            if (~(obj.DigitalPin(pinNumber).Available) || ~(obj.DigitalPin(pinNumber).Mode == obj.PINMODE_PWM))
                fprintf('Pin number %d is not configured for PWM output\n',int32(pinNumber));
                coder.ceval('main_terminate');
            end
        end
        
        function checkPinUnset(obj,pinNumber)
            validateattributes(pinNumber, {'numeric'}, {'scalar','>=',1,'<=',40}, ...
                '', 'the pin number');
            
            if (~(obj.DigitalPin(pinNumber).Available) || ~(obj.DigitalPin(pinNumber).Mode == obj.PINMODE_UNSET))
                fprintf('Pin number %d is not available\n',int32(pinNumber));
                coder.ceval('main_terminate');
            end
        end
        
    end
    
    methods
        function serialObj = serialdev(~,varargin)
            def_port = '/dev/serial0';
            def_baudRate = 9600;
            def_dataBits = '8';
            def_parity = 'None';
            def_stopBits = '1';
            
            if nargin > 1
                def_port = varargin{1};
            end
            if nargin > 2
                def_baudRate = varargin{2};
            end
            if nargin > 3
                def_dataBits = num2str(varargin{3});
            end
            if nargin > 4
                def_parity = varargin{4};
            end
            if nargin > 5
                def_stopBits = num2str(varargin{5});
            end
            serialObj = codertarget.raspi.internal.SCIReadWrite('SCIModule',def_port,'Baudrate',def_baudRate,'DataBits',def_dataBits,'Parity',def_parity,'StopBits',def_stopBits);
        end
        
        function servoObj = servo(~,varargin)
            % TODO
            % Validation check for pin number and other parameters
            %varargin = [{'Pin'} varargin];
            servoObj = raspi.internal.ServoBlock('PinNumber',varargin{:});
            initServo(servoObj);
        end
        
     
        function camObj = cameraboard(~,varargin)
            camObj = raspi.internal.codegen.cameraboard(varargin{:});
        end
        
        % Configure Pin
        function pinMode = configurePin(obj,pinNumber,pinMode,varargin)
            mustBeMember(pinNumber,obj.AvailableDigitalPins);
            checkDigitalPin(obj,pinNumber);
            if nargin == 3
                pinMode = validatestring(pinMode,{obj.UPINMODESTR{1:obj.PINMODE_PWM}},'configurePin');
                switch pinMode
                    case obj.UPINMODESTR{obj.PINMODE_PWM}
                        if nargin < 4
                            frequency = 500; % Hz
                        else
                            frequency = varargin{1};
                            validateattributes(frequency,{'numeric'},...
                                {'scalar','nonnegative'},'','frequency');
                        end
                        configurePinUnset(obj,pinNumber);
                        pwmObj = raspi.internal.PWMBlock;
                        ret = initPWM(pwmObj,pinNumber,frequency,0);
                        if (ret == 0)
                            registerPinMode(obj,pinNumber,obj.PINMODE_PWM);
                        end
                    case obj.UPINMODESTR{obj.PINMODE_DI}
                        direction = 0;
                        configurePinUnset(obj,pinNumber);
                        gpioObj = raspi.internal.GPIOCodegen;
                        ret = initGPIO(gpioObj,pinNumber,direction);
                        if (ret == 0)
                            registerPinMode(obj,pinNumber,obj.PINMODE_DI);
                        end
                    case obj.UPINMODESTR{obj.PINMODE_DO}
                        direction = 1;
                        configurePinUnset(obj,pinNumber);
                        raspiGPIO = raspi.internal.GPIOCodegen;
                        ret = initGPIO(raspiGPIO,pinNumber,direction);
                        if (ret == 0)
                            registerPinMode(obj,pinNumber,obj.PINMODE_DO);
                        end
                    case obj.UPINMODESTR{obj.PINMODE_UNSET}
                        % Unset and free the pin
                        configurePinUnset(obj,pinNumber);
                    otherwise
                        %do nothing
                end
            end
        end
        
        function writeDigitalPin(obj, pinNumber, value)
            mustBeMember(pinNumber,obj.AvailableDigitalPins);
            validValues = [1,0];
            validateattributes(value, {'logical','numeric'}, {'scalar'}, '','writeDigitalPin');
            if isnumeric(value)
                mustBeMember(value,validValues);
            end
            
            checkWriteDigitalPin(obj,pinNumber)
            gpioObj = raspi.internal.GPIOCodegen;
            writeGPIO(gpioObj,pinNumber, value);
        end
        
        function value = readDigitalPin(obj, pinNumber)
            mustBeMember(pinNumber,obj.AvailableDigitalPins);
            checkReadDigitalPin(obj, pinNumber);
            gpioObj = raspi.internal.GPIOCodegen;
            value = readGPIO(gpioObj, pinNumber);
        end
        
        function writePWMDutyCycle(obj,pinNumber,dutyCycle)
            mustBeMember(pinNumber,obj.AvailableDigitalPins);
            validateattributes(dutyCycle,{'numeric'},...
                {'scalar','>=',0,'<=',1}, '', 'dutyCycle');
            
            %Check for pin conflicts
            checkPWMPin(obj, pinNumber);
            pwmObj = raspi.internal.PWMBlock;
            setPWMDutyCycle(pwmObj,pinNumber,dutyCycle);
        end
        
        function writePWMFrequency(obj,pinNumber,frequency)
            mustBeMember(pinNumber,obj.AvailableDigitalPins);
            mustBeMember(frequency,obj.AVAILABLE_PWM_FREQUENCY);
            
            %Check for pin conflicts
            checkPWMPin(obj, pinNumber);
            pwmObj = raspi.internal.PWMBlock;
            setPWMFrequency(pwmObj,pinNumber,frequency);
        end
        
        function writePWMVoltage(obj,pinNumber,voltage)
            mustBeMember(pinNumber,obj.AvailableDigitalPins);
            validateattributes(voltage,{'numeric'},...
                {'scalar','positive','real','finite','>=',0,'<=',3.3}, '', 'voltage');
            
            % Calculate duty cycle required
            dutyCycle = voltage/obj.VDD;
            writePWMDutyCycle(obj,pinNumber,dutyCycle);
        end
        
        function configurePinUnset(obj,pinNumber)
            % pinMode == unset
            if ~obj.DigitalPin(pinNumber).Inuse
                return;
            end
            
            switch obj.DigitalPin(pinNumber).Mode
                case {obj.PINMODE_DI,obj.PINMODE_DO}
                    % Digital I/O (GPIO)
                    gpioObj = raspi.internal.GPIOCodegen;
                    ret = terminateGPIO(gpioObj,pinNumber);
                    if (ret ~= 0)
                        % Terminate GPIO failed.
                        return;
                    end
                case obj.PINMODE_PWM
                    % PWM
                    pwmOjb = raspi.internal.PWMBlock;
                    ret = terminatePWM(pwmOjb,pinNumber);
                    if (ret ~= 0)
                        %Terminate PWM failed.
                        return;
                    end
            end
            
            obj.DigitalPin(pinNumber).Inuse = false;
            obj.DigitalPin(pinNumber).Mode  = obj.PINMODE_UNSET;
        end
        
        function registerPinMode(obj,pinNumber,mode)
            obj.DigitalPin(pinNumber).Inuse = true;
            obj.DigitalPin(pinNumber).Mode  = mode;
        end
        
        function writeLED(obj,led,value)
            led = validatestring(led,obj.AvailableLeds,'writeLED');
            validLEDvalues = [1,0];
            validateattributes(value, {'logical','numeric'}, {'scalar'}, '','writeLED');
            if isnumeric(value)
                mustBeMember(value,validLEDvalues);
            end
            ledObj = raspi.internal.codegen.LEDOnBoard('led',led);
            writeLED(ledObj,value);
        end
        
        function webcamObj = webcam(obj,varargin)
            webcamObj = raspi.internal.codegen.webcam(obj,varargin{:});
        end
        
        function displayImage(obj,img,varargin)   
             if nargin > 2
                narginchk(4,4);
                validatestring(varargin{1},{'Title'},'Title');
                obj.RaspiDisplay.windowTitle = varargin{2};
            else
                narginchk(2,2);
                obj.RaspiDisplay.windowTitle = 'Raspberry Pi Display';
            end      
            displayImage(obj.RaspiDisplay,img);                
        end
        
        function out = system(obj, varargin) %#ok<INUSL>
            systemObj = raspi.internal.codegen.raspisystem();
            if nargin == 3
                validatestring(varargin{2},{'sudo'},'system');
            end
            out = runSystemCmd(systemObj,varargin{:});
        end
        
        function i2cDevice = i2cdev(~, varargin)
            % Pattern of I2C Bus Number - 'i2c-#'
            % Fetch the I2C Bus Number from input arguments
            I2CBus = varargin{1};
            % Validate I2C Bus Number for being a char vector of 5 elements
            validateattributes(I2CBus, {'char', 'string'}, {}, '','I2C Bus Number');
            % Validate I2C Bus Number = {i2c-0, i2c-1}
            validatestring(I2CBus, {'i2c-0', 'i2c-1'}, '', 'I2C Bus Number');
            % Extract the I2C Bus Number
            I2CBus = extractAfter(I2CBus, "i2c-");
            
            % Pattern of I2C device Address - '0x#'
            % Fetch I2C device address from input arguments
            I2CAddress = varargin{2};
            % Validate I2C device address for being a char vector / string
            validateattributes(I2CAddress, {'char', 'string'}, {}, '', 'I2C device address');
            I2CAddress = char(I2CAddress);
            % Validate whether I2C device address is prefixed with '0x'
            validatestring(I2CAddress(1:2), {'0x'}, '', 'first two characters of the I2C device address');
            % Extract the I2C device address and convert hex to decimal
            I2CAddress = hex2dec(extractAfter(I2CAddress, "0x"));
            
            i2cDevice = codertarget.raspi.internal.I2CReadWrite('I2CModule', I2CBus, 'SlaveAddress',I2CAddress);
        end
        
        function spiDevice = spidev(~, varargin)
            SPIChannel = varargin{1};
            % Validate SPI Channel for being a char vector of 3 elements
            validateattributes(SPIChannel, {'char', 'string'}, {}, '','SPI Channel');
            % Validate SPI Channel = {CE0, CE1}
            validatestring(SPIChannel, {'CE0', 'CE1'}, '', 'SPI Channel');
            % Cannot concatenate char with string and strcat isn't
            % supported for codegen. Hence manipulating characters.
            % There is only 1 SPI module in any Raspi - SPI0.
            SPIChannel = ['SPI0_', char(SPIChannel)];
            
            % Optional parameters Mode and BitRate
            SPIMode = 0;
            SPIBitRate = 5e5;
            if nargin >= 3
                SPIMode = num2str(varargin{2});
            end
            if nargin == 4
                SPIBitRate = varargin{3};
            end
            % SPI Mode nonnegative and < 3
            validateattributes(SPIMode, {'numeric'}, {'scalar', 'finite', 'integer', 'nonnan', 'nonnegative', '<=', 3}, '', 'SPI clock mode');
            % SPI Bus Speed should be numeric
            validateattributes(SPIBitRate, {'numeric'}, {'scalar', 'finite', 'integer', 'nonnan', 'nonnegative'}, '', 'SPI Bus Speed');
            % SPI Bus Speed should match one of the specified values
            validatestring(num2str(SPIBitRate), {'500000', '1000000', '2000000', '4000000', '8000000', '16000000', '32000000'}, '', 'SPI Bus Speed');
            
            spiDevice = codertarget.raspi.internal.SPIReadWrite('BusSpeed', SPIBitRate, 'Pin', SPIChannel, 'ClockMode', num2str(SPIMode));
        end
        
        %%----------------Non Codegen function----------------------%%
        function showLEDs(~)
            %No action during code generation
        end
        
        function showPins(~)
            %No action during code generation
        end
        
        function openShell(~)
            %No action during code generation
        end
        
        function [varargout] = scanI2CBus(~, varargin)
            [varargout{1:nargout}] = functionNotSupported('scanI2CBus');
        end
        
        function enableI2C(~, varargin)
            functionNotSupported('enableI2C');
        end
        
        function disableI2C(~, varargin)
            functionNotSupported('disableI2C');
        end
        
        function enableSPI(~, varargin)
            functionNotSupported('enableSPI');
        end
        
        function disableSPI(~, varargin)
            functionNotSupported('disableSPI');
        end
        
        function senseHatObj = sensehat(obj, varargin)
            senseHatObj = raspi.internal.codegen.sensehat(obj,varargin{:});
        end
        
        function getFile(~, ~, varargin)
            functionNotSupported('getFile');
        end
        
        function putFile(~, varargin)
            functionNotSupported('putFile');
        end
        
        function deleteFile(~, varargin)
            functionNotSupported('deleteFile');
        end
    end
end


function [varargout] = functionNotSupported(fname)
coder.internal.prefer_const(fname);
coder.inline('always');
coder.internal.assert(false, ...
    'raspi:matlabtarget:CodeGenNotSupported',fname);
[varargout{1:nargout}] = deal([]);
end
%[EOF]


% LocalWords:  DEVICEADDRESS raspberrypi MJONES Inuse narginchk CSpeeds GPIO
% LocalWords:  dev Baudrate utils runSystemCmd
