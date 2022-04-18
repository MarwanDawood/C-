classdef raspi < handle ...
        & matlab.mixin.CustomDisplay
    %	Connect to a Raspberry Pi hardware board.
    %
    %   Syntax:
    %       r = raspi
    %       r = raspi(ipaddress,username,password)
    %       r = raspi(hostname,username,password)
    %       r = raspi(name)
    %       r = raspi(serialnum)
    %
    %   Description:
    %       r = raspi                                 Creates a desktop or MATLAB Online connection to a Raspberry Pi board.
    %       r = raspi(ipaddress,username,password)    Creates a desktop connection to the Raspberry Pi board at specified IP address with specified login credentials.
    %       r = raspi(hostname,username,password)     Creates a desktop connection to the Raspberry Pi board with specified hostname and login credentials.
    %       r = raspi(name)                           Creates a MATLAB Online connection to the Raspberry Pi board with specified name.
    %       r = raspi(serialnum)                      Creates a MATLAB Online connection to the Raspberry Pi board with specified serial number.
    %
    %   MATLAB Desktop Example:
    %   Connect to a Raspberry Pi board at IP address 172.54.23.10 with username 'pi' and password 'raspberry':
    %       r = raspi('172.54.23.10','pi','raspberry');
    %
    %   MATLAB Online Example:
    %   Connect to a Raspberry Pi board with name 'testpi' in MATLAB Online:
    %       r = raspi('testpi');
    %
    %   Connect to a Raspberry Pi board with serial number '000000003d1d1c36' in MATLAB Online:
    %       r = raspi('000000003d1d1c36');
    %
    %   Input Arguments:
    %   ipaddress - Raspberry Pi IP address (character vector or string, e.g. '172.54.23.10')
    %   hostname  - Raspberry Pi hostname (character vector or string, e.g. 'raspberrypi-MJONES.foo')
    %   username  - Raspberry Pi login username (character vector or string, e.g. 'pi')
    %   password  - Raspberry Pi login password (character vector or string, e.g. 'raspberry')
    %   name      - Raspberry Pi MATLAB Online display name (character vector or string, e.g. 'myhomepi')
    %   serialnum - Raspberry Pi serial number (character vector or string, e.g '000000003d1d1c36')
    %
    %   Output Arguments:
    %   r - Raspberry Pi board connection
    %
    %   See also raspilist, writeDigitalPin, readDigitalPin, i2cdev, spidev, webcam, cameraboard
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties (SetAccess = private)
        DeviceAddress
        SerialNumber
        Port
        BoardName
        AvailableLEDs
        AvailableDigitalPins
        AvailableSPIChannels
        AvailableI2CBuses
        I2CBusSpeed
        AvailableWebcams = {}
    end
    
    properties(Access = private)
        RaspiImpl
    end
    
    methods (Hidden)
        function obj = raspi(varargin)
            % Create a connection to Raspberry Pi hardware board.
            
            % Register the error message catalog location
            matlab.internal.msgcat.setAdditionalResourceLocation(raspi.internal.getRaspiBaseRoot);
            
            try
                s = settings;
                if ~s.matlab.hardware.raspi.IsOnline.ActiveValue
                    obj.RaspiImpl = raspi.internal.raspiDesktop(varargin{:});
                    obj.Port = obj.RaspiImpl.Port;
                else
                    obj.RaspiImpl = raspi.internal.raspiOnline(varargin{:});
                    obj.SerialNumber = obj.RaspiImpl.SerialNumber;
                end
            catch e
                throwAsCaller(e)
            end
        end
    end
    
    methods(Access = private, Static)
        function name = matlabCodegenRedirect(~)
            name = 'raspi.codegen.raspi';
        end
    end
    
    % GET / SET methods
    methods
        function value = get.DeviceAddress(obj)
            value = obj.RaspiImpl.DeviceAddress;
        end
        
        function value = get.BoardName(obj)
            value = obj.RaspiImpl.BoardName;
        end
        
        function value = get.AvailableLEDs(obj)
            value = obj.RaspiImpl.AvailableLEDs;
        end
        
        function value = get.AvailableDigitalPins(obj)
            value = obj.RaspiImpl.AvailableDigitalPins;
        end
        
        function value = get.AvailableSPIChannels(obj)
            value = obj.RaspiImpl.AvailableSPIChannels;
        end
        
        function value = get.AvailableI2CBuses(obj)
            value = obj.RaspiImpl.AvailableI2CBuses;
        end
        
        function value = get.I2CBusSpeed(obj)
            value = obj.RaspiImpl.I2CBusSpeed;
        end
        
        function value = get.AvailableWebcams(obj)
            value = obj.RaspiImpl.AvailableWebcams;
        end
    end
    
    % Public methods
    methods
        function openShell(obj)
            %   Open an interactive command shell to Raspberry Pi hardware board.
            %
            %   Syntax:
            %   openShell(r)
            %
            %   Description:
            %   Open an interactive command shell to Raspberry Pi.
            %
            %   Example:
            %       r = raspi;
            %       openShell(r);
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %
            %   See also system, getFile, putFile, deleteFile
            try
                obj.RaspiImpl.openShell;
            catch e
                throwAsCaller(e);
            end
        end
        
        function output = system(obj,varargin)
            %   Run command in Linux shell on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   output = system(r,command)
            %   output = system(r,command,sudo)
            %
            %   Description:
            %   Run command in Linux shell on Raspberry Pi.
            %
            %   Example:
            %       r = raspi;
            %       output = system(r,'ls /dev/tty*');
            %
            %   Example:
            %       r = raspi;
            %       output = system(r,'ls /dev/tty*','sudo');
            %
            %   Input Arguments:
            %   r       - Raspberry Pi connection
            %   command - Shell command to run on hardware (character vector)
            %   sudo    - Run shell command with sudo permission (character vector, e.g 'sudo')
            %
            %   Output Arguments:
            %   output - stdout of the command execution (character vector)
            %
            %   See also openShell, getFile, putFile, deleteFile
            try
                output = obj.RaspiImpl.system(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function putFile(obj,varargin)
            %   Transfer a file from host computer to Raspberry Pi hardware board.
            %
            %   Syntax:
            %   putFile(r,source)
            %   putFile(r,source,destination)
            %
            %   Description:
            %   Transfer a file from host computer to Raspberry Pi.
            %
            %   Example:
            %       r = raspi;
            %       putFile(r,'testfile');
            %
            %   Example:
            %       r = raspi;
            %       putFile(r,'testfile','/home/pi');
            %
            %   Input Arguments:
            %   r           - Raspberry Pi connection
            %   source      - File on host computer to transfer to Raspberry Pi (character vector)
            %   destination - Destination folder path and optional file name on Raspberry Pi (character vector)
            %
            %   See also getFile, deleteFile, system, openShell
            try
                obj.RaspiImpl.putFile(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function getFile(obj,source,varargin)
            %   Transfer a file from Raspberry Pi hardware board to host computer or MATLAB Drive.
            %
            %   Syntax:
            %   getFile(r,source)
            %   getFile(r,source,destination)
            %
            %   Description:
            %   Transfer a file from Raspberry Pi to host computer or MATLAB Drive.
            %
            %   Example:
            %       r = raspi;
            %       getFile(r,'myvideo.mp4');
            %
            %   Example:
            %       r = raspi;
            %       getFile(r,'myvideo.mp4','C:\MATLAB');
            %
            %   Example:
            %       r = raspi;
            %       getFile(r,'myvideo.mp4','/MATLAB Drive/myfolder');
            %
            %   Input Arguments:
            %   r           - Raspberry Pi connection
            %   source      - File on Raspberry Pi to transfer to host computer or MATLAB Drive (character vector)
            %   destination - Destination folder path and optional file name on host computer or MATLAB Drive (character vector)
            %
            %   See also putFile, deleteFile, system, openShell
            try
                obj.RaspiImpl.getFile(source,varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function deleteFile(obj, filename)
            %   Delete a file on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   deleteFile(r,filename)
            %
            %   Description:
            %   Delete a file on Raspberry Pi.
            %
            %   Example:
            %       r = raspi;
            %       deleteFile(r,'myvideo.mp4');
            %
            %   Input Arguments:
            %   r        - Raspberry Pi connection
            %   filename - File on Raspberry Pi to delete (character vector)
            %
            %   See also putFile, getFile, system, openShell
            try
                obj.RaspiImpl.deleteFile(filename);
            catch e
                throwAsCaller(e);
            end
        end
        
        function ret = scanI2CBus(obj, varargin)
            %   Scan I2C bus for connected I2C devices and return the device addresses.
            %
            %   Syntax:
            %   addrs = scanI2CBus(r);
            %   addrs = scanI2CBus(r,bus);
            %
            %   Description:
            %   Scans the I2C bus for connected I2C devices, and returns a cell array of the I2C device addresses in hex.
            %
            %   Example:
            %       r = raspi;
            %       addrs = scanI2CBus(r);
            %
            %   Example:
            %       r = raspi;
            %       addrs = scanI2CBus(r,'i2c-1');
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %   bus - I2C bus number (character vector, 'i2c-0' or 'i2c-1')
            %
            %   Output Arguments:
            %   addrs - I2C bus addresses in hex (cell array of character vectors)
            %
            %   See also i2cdev
            
            try
                ret = obj.RaspiImpl.scanI2CBus(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function enableSPI(obj)
            %   Enable SPI peripherial on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   enableSPI(r)
            %
            %   Description:
            %   Enable SPI peripherial on Raspberry Pi to allow SPI operations on the SPI pins.
            %
            %   Example:
            %       r = raspi;
            %       enableSPI(r);
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %
            %   See also disableSPI, spidev, writeRead
            
            try
                obj.RaspiImpl.enableSPI;
            catch e
                throwAsCaller(e);
            end
        end
        
        function disableSPI(obj)
            %   Disable SPI peripherial on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   disableSPI(r)
            %
            %   Description:
            %   Disable SPI peripherial on Raspberry Pi to allow digital operations on the SPI pins.
            %
            %   Example:
            %       r = raspi;
            %       disableSPI(r);
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %
            %   See also enableSPI, spidev, writeRead
            
            try
                obj.RaspiImpl.disableSPI;
            catch e
                throwAsCaller(e);
            end
        end
        
        function enableI2C(obj, varargin)
            %   Enable I2C peripherial on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   enableI2C(r)
            %
            %   Description:
            %   Enable I2C peripherial on Raspberry Pi to allow I2C operations on the I2C pins.
            %
            %   Example:
            %       r = raspi;
            %       enableI2C(r);
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %
            %   See also disableI2C, scanI2CBus, i2cdev, read, write, readRegister, writeRegister
            
            try
                obj.RaspiImpl.enableI2C(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function disableI2C(obj)
            %   Disable I2C peripherial on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   disableI2C(r)
            %
            %   Description:
            %   Disable I2C peripherial on Raspberry Pi to allow digital operations on the I2C pins.
            %
            %   Example:
            %       r = raspi;
            %       disableI2C(r);
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %
            %   See also enableI2C, scanI2CBus, i2cdev, read, write, readRegister, writeRegister
            
            try
                obj.RaspiImpl.disableI2C;
            catch e
                throwAsCaller(e);
            end
        end
        
        function showPins(obj)
            %	Shows a diagram of user accessible pins on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   showPins(r)
            %
            %   Description:
            %   Shows a diagram of user accessible pins on Raspberry Pi
            %
            %   Example:
            %       r = raspi;
            %       showPins(r);
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %
            %   See also configurePin, readDigitalPin, writeDigitalPin
            
            try
                obj.RaspiImpl.showPins;
            catch e
                throwAsCaller(e);
            end
        end
        
        % LED interface
        function showLEDs(obj)
            %	Shows location, name and color of user-controllable LEDs on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   showLEDs(r)
            %
            %   Description:
            %   Shows location, name and color of user-controllable LEDs on Raspberry Pi.
            %
            %   Example:
            %       r = raspi;
            %       showLEDs(r);
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %
            %   See also writeLEDs
            
            try
                obj.RaspiImpl.showLEDs;
            catch e
                throwAsCaller(e);
            end
        end
        
        function writeLED(obj, led, value)
            %	Turn LED on or off on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   writeLED(r,led,value)
            %
            %   Description:
            %   Turn the specified LED on or off on Raspberry Pi.
            %
            %   Example:
            %       r = raspi;
            %       writeLED(r,'led0',true);
            %
            %   Input Arguments:
            %   r     - Raspberry Pi connection
            %   led   - User-controllable LED name (character vector)
            %   value - LED value (logical or digital value of 0 or 1)
            %
            %   See also showLEDs
            
            try
                obj.RaspiImpl.writeLED(led,value);
            catch e
                throwAsCaller(e);
            end
        end
        
        function pinMode = configureDigitalPin(obj, pinNumber, varargin)
            % configureDigitalPin(rpi, pinNumber, pinMode)
            % pinMode = configureDigitalPin(rpi, pinNumber)
            try
                pinMode = obj.RaspiImpl.configureDigitalPin(pinNumber,varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function pinMode = configurePin(obj,varargin)
            %   Configure pin mode on Raspberry Pi hardware board.
            %
            %   Syntax:
            %       pinMode = configurePin(r,pin)
            %       configurePin(r,pin,mode)
            %
            %   Description:
            %       Displays the pin mode of the specified pin or sets the
            %       specified pin on the Raspberry Pi to the specified
            %       mode.
            %
            %   Example:
            %       r = raspi();
            %       configurePin(r,4,'DigitalInput')
            %
            %   Input Arguments:
            %   r    - Raspberry Pi connection
            %   pin  - Pin number on the physical hardware (double).
            %   mode - Pin mode (character vector, e.g. DigitalInput, Pullup, DigitalOutput, PWM)
            %
            %   Example:
            %       r = raspi();
            %       config = configurePin(r, 4);
            %
            %   Output Arguments:
            %   config - Current mode (character vector) for specified pin.
            %
            %   See also readDigitalPin, writeDigitalPin
            
            try
                pinMode = obj.RaspiImpl.configurePin(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function value = readDigitalPin(obj, pinNumber)
            %   Read digital pin value on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   value = readDigitalPin(r,pin)
            %
            %   Description:
            %   Reads logical value from the specified pin on Raspberry Pi
            %
            %   Example:
            %       r = raspi();
            %       value = readDigitalPin(r,'D13');
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %   pin - Digital pin number (double)
            %
            %   Output Arguments:
            %   value - Digital (0, 1) value acquired from digital pin (double)
            %
            %   See also writeDigitalPin
            
            try
                value = obj.RaspiImpl.readDigitalPin(pinNumber);
            catch e
                throwAsCaller(e);
            end
        end
        
        function writeDigitalPin(obj, pinNumber, value)
            %   Write digital pin value on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   writeDigitalPin(r,pin,value)
            %
            %   Description:
            %   Writes specified value to the specified pin on Raspberry Pi.
            %
            %   Example:
            %       r = raspi();
            %       writeDigitalPin(r,3,1);
            %
            %   Input Arguments:
            %   r     - Raspberry Pi connection
            %   pin   - Digital pin number (double)
            %   value - Digital value (0, 1) or (true, false) to write to the specified pin (double or logical)
            %
            %   See also readDigitalPin
            
            try
                obj.RaspiImpl.writeDigitalPin(pinNumber,value);
            catch e
                throwAsCaller(e);
            end
        end
        
        function writePWMVoltage(obj,pin,voltage)
            %   Set PWM pin voltage on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   writePWMVoltage(r,pin,voltage)
            %
            %   Description:
            %   Set specified PWM pin voltage to the specified value on Raspberry Pi
            %
            %   Example:
            %       r = raspi;
            %       writePWMVoltage(r,4,2.5)
            %
            %   Input Arguments:
            %   r       - Raspberry Pi connection
            %   pin     - Digital pin number (double, e.g 3)
            %   voltage - PWM signal voltage between 0 and 3.3 (double)
            %
            %   See also writePWMFrequency, writePWMDutyCycle
            
            try
                obj.RaspiImpl.writePWMVoltage(pin, voltage);
            catch e
                throwAsCaller(e);
            end
        end
        
        function writePWMFrequency(obj,pinNumber,frequency)
            %   Set PWM pin frequency on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   writePWMFrequency(r,pin,frequency)
            %
            %   Description:
            %   Set specified PWM pin frequency to the specified value on Raspberry Pi
            %
            %   Example:
            %       r = raspi;
            %       writePWMFrequency(r, 12, 2000000)
            %
            %   Input Arguments:
            %   r         - Raspberry Pi connection
            %   pin       - Digital pin number (double, e.g 3)
            %   frequency - PWM signal voltage between 1 and 1000000000 (double)
            %
            %   See also writePWMVoltage, writePWMDutyCycle
            
            try
                obj.RaspiImpl.writePWMFrequency(pinNumber,frequency);
            catch e
                throwAsCaller(e);
            end
        end
        
        function writePWMDutyCycle(obj,pinNumber,dutyCycle)
            %   Output a PWM signal on a digital pin on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   writePWMDutyCycle(r,pin,dutyCycle)
            %
            %   Description:
            %   Set the specified duty cycle on the specified digital pin.
            %
            %   Example:
            %   Set the brightness of the LED on digital pin 4 of the Raspberry Pi hardware to 33%
            %       r = raspi();
            %       writePWMDutyCycle(r,4,0.33);
            %
            %   Input Arguments:
            %   r         - Raspberry Pi connection
            %   pin       - Digital pin number (double, e.g 3)
            %   dutyCycle - PWM signal duty cycle between 0 and 1 (double)
            %
            %   See also writePWMFrequency, writePWMVoltage
            
            % Send write request
            try
                obj.RaspiImpl.writePWMDutyCycle(pinNumber,dutyCycle);
            catch e
                throwAsCaller(e);
            end
        end
        
        % I2C interface
        function i2cObj = i2cdev(obj,varargin)
            %   Connect to an I2C device on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   i2cObj = i2cdev(r,bus,address)
            %
            %   Description:
            %   Connect to an I2C device at the specified address on the specified I2C bus of Raspberry Pi.
            %
            %   Example:
            %       r = raspi();
            %       tmp102 = i2cdev(r,'i2c-1','0x48');
            %
            %   Input Arguments:
            %   r       - Raspberry Pi connection
            %   bus     - I2C bus on which the device is connected to (character vector, e.g 'i2c-1')
            %   address - I2C address of device (character vector, e.g '0x48')
            %
            %   Output Arguments:
            %   i2cObj  - I2C device connection.
            %
            %   See also spidev, servo, serialdev, webcam, cameraboard, sensehat
            try
                i2cObj = obj.RaspiImpl.i2cdev(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        % SPI interface
        function spiObj = spidev(obj,varargin)
            %   Connect to the SPI device on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   spiObj = spidev(r,channel)
            %   spiObj = spidev(r,channel,mode,speed)
            %
            %   Description:
            %   spiObj = spidev(r,channel)            Connect to an SPI device on the specified channel
            %   spiObj = spidev(r,channel,mode,speed) Connect to an SPI device on the specified channel with specified mode and specified speed.
            %
            %   Example:
            %       r = raspi();
            %       ad5231 = spidev(r,'CE1');
            %
            %   Example:
            %       r = raspi();
            %       ad5231 = spidev(a,'CE1',0,20000000);
            %
            %   Input Arguments:
            %   r       - Raspberry Pi connection
            %   channel - SPI channel (character vector, e.g 'CE0' or 'CE1')
            %   mode    - SPI mode (numeric 0-3, default to 0)
            %   speed   - SPI speed in Hertz (numeric)
            %
            %   Output Arguments:
            %   spiObj  - SPI device connection.
            %
            %   See also i2cdev, servo, serialdev, webcam, cameraboard, sensehat
            try
                spiObj = obj.RaspiImpl.spidev(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        % Serial interface
        function serialObj = serialdev(obj,varargin)
            %   Connect to a serial device on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   serialObj = serialdev(r,port)
            %   serialObj = serialdev(r,port,baudRate,dataBits,parity,stopBits)
            %
            %   Description:
            %   serialObj = serialdev(r,port)   Connect to a serial device at the specified port on Raspberry Pi.
            %   serialObj = serialdev(r,port,baudRate,dataBits,parity,stopBits)   Connect to a serial device at the specified port with specified baud rate, data bits, parity and stop bits on Raspberry Pi.
            %
            %   Example:
            %       r = raspi();
            %       s = serialdev(r,'/dev/serial0');
            %
            %   Example:
            %       r = raspi();
            %       s = serialdev(r,'/dev/serial0',9600);
            %
            %   Example:
            %       r = raspi();
            %       s = serialdev(r,'/dev/serial0',9600,6,'even',2);
            %
            %   Input Arguments:
            %   r        - Raspberry Pi connection
            %   port     - Serial device path and file name (character vector, e.g '/dev/serial0')
            %   baudRate - Serial device baud rate (numeric, default to 115200)
            %   dataBits - Serial device data bits per character (numeric, default to 8)
            %   parity   - Serial device parity bit (character vector, default to 'none')
            %   stopBits - Serial device stop bits (numeric, default to 1)
            %
            %   Output Arguments:
            %   serialObj  - Serial device connection.
            %
            %   See also spidev, servo, i2cdev, webcam, cameraboard, sensehat
            try
                serialObj = obj.RaspiImpl.serialdev(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        % CameraBoard interface
        function camObj = cameraboard(obj, varargin)
            %   Connect to a camera board on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   camObj = cameraboard(r)
            %   camObj = cameraboard(r,Name,Value)
            %
            %   Description:
            %   camObj = cameraboard(r)            Creates a camera board object connected to the Raspberry Pi.
            %   camObj = cameraboard(r,Name,Value) Creates a camera board object with additional options specified by one or more Name-Value pair arguments.
            %
            %   Example:
            %       r = raspi();
            %       c = cameraboard(r);
            %
            %   Example:
            %       r = raspi();
            %       c = cameraboard(r,'Resolution','1280x720');
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %
            %   Name-Value Pair Input Arguments:
            %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value.
            %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
            %
            %   NV Pair:
            %   'Resolution'           - Image dimension (character vector, default '640x480').
            %   'Quality'              - JPEG image quality (numeric, default 10).
            %   'Rotation'             - Degrees of clockwise rotation (numeric, default 0).
            %   'HorizontalFlip'       - The pulse duration for the servo at its maximum position (numeric, default 2.4e-3 seconds).
            %   'VerticalFlip'         - Flip image vertically (logical, default 0).
            %   'FrameRate'            - Video frame rate (numeric, default 30).
            %   'Brightness'           - Image brightness (numeric, default 50).
            %   'Contrast'             - Image contrast (numeric, default 0).
            %   'Saturation'           - Image color saturation (numeric, default 0).
            %   'Sharpness'            - Image sharpness (numeric, default 0).
            %   'ExposureMode'         - Exposure mode (character vector, default 'auto').
            %   'ExposureCompensation' - Exposure compensation (numeric, default 0).
            %   'AWBMode'              - Automatic white balance mode (character vector, default 'auto').
            %   'MeteringMode'         - Metering mode (character vector, default 'average').
            %   'ImageEffect'          - Special effect (character vector, default 'none').
            %   'VideoStabilization'   - Video stabilization (character vector, default 'off').
            %   'ROI'                  - Region of interest (numeric vector, default [0.00 0.00 1.00 1.00]).
            %
            %   Output Arguments:
            %   camObj  - Camera board connection.
            %
            %   See also i2cdev, spidev, servo, serialdev, webcam, sensehat
            try
                camObj = obj.RaspiImpl.cameraboard(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function servoObj = servo(obj,varargin)
            %   Connect to a servo on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   servoObj = servo(r,pin)
            %   servoObj = servo(r,pin,Name,Value)
            %
            %   Description:
            %   servoObj = servo(r,pin)            Creates a servo motor object connected to the specified pin on Raspberry Pi.
            %   servoObj = servo(r,pin,Name,Value) Creates a servo motor object with additional options specified by one or more Name-Value pair arguments.
            %
            %   Example:
            %       r = raspi();
            %       s = servo(r,7);
            %
            %   Example:
            %       r = raspi();
            %       s = servo(r,7,'MinPulseDuration',1e-3,'MaxPulseDuration',2e-3);
            %
            %   Input Arguments:
            %   r   - Raspberry Pi connection
            %   pin - GPIO pin number (numeric)
            %
            %   Name-Value Pair Input Arguments:
            %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value.
            %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
            %
            %   NV Pair:
            %   'MinPulseDuration' - The pulse duration for the servo at its minimum position (numeric, default 5.44e-4 seconds).
            %   'MaxPulseDuration' - The pulse duration for the servo at its maximum position (numeric, default 2.4e-3 seconds).
            %
            %   Output Arguments:
            %   servoObj  - Servo motor connection.
            %
            %   See also i2cdev, spidev, serialdev, webcam, cameraboard, sensehat
            try
                servoObj = obj.RaspiImpl.servo(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function webcamObj = webcam(obj,varargin)
            %   Connect to a web camera on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   webcamObj = webcam(r)
            %   webcamObj = webcam(r,cameraName)
            %   webcamObj = webcam(r,cameraIndex)
            %   webcamObj = webcam(r,cameraName,resolution)
            %   webcamObj = webcam(r,cameraIndex,resolution)
            %
            %   Description:
            %   webcamObj = webcam(r)                        Connect to the first available web camera on Raspberry Pi
            %   webcamObj = webcam(r,cameraName)             Connect to the web camera with specified name on Raspberry Pi
            %   webcamObj = webcam(r,cameraIndex)            Connect to the web camera at the specified index in AvailableWebcams on Raspberry Pi
            %   webcamObj = webcam(r,cameraName,resolution)  Connect to the web camera with specified name and specified resolution on Raspberry Pi
            %   webcamObj = webcam(r,cameraIndex,resolution) Connect to the web camera at the specified index in AvailableWebcams and with specified resolution on Raspberry Pi
            %
            %   Example:
            %       r = raspi();
            %       w = webcam(r);
            %
            %   Example:
            %       r = raspi();
            %       w = webcam(r,'/dev/video0');
            %
            %   Example:
            %       r = raspi();
            %       w = webcam(r,1);
            %
            %   Example:
            %       r = raspi();
            %       w = webcam(r,'/dev/video0','640x480');
            %
            %   Example:
            %       r = raspi();
            %       w = webcam(r,1,'640x480');
            %
            %   Input Arguments:
            %   r        - Raspberry Pi connection
            %   cameraName  - Name of the web camera (character vector, e.g '/dev/video0')
            %   cameraIndex - Index of web camera in AvailableWebcams property (numeric, e.g 1)
            %   resolution  - Web camera resolution (character vector, e.g '640x480')
            %
            %   Output Arguments:
            %   webcamObj  - Web camera connection.
            %
            %   See also spidev, servo, i2cdev, serialdev, cameraboard, sensehat
            
            try
                webcamObj = obj.RaspiImpl.webcam(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function sensehatObj = sensehat(obj,varargin)
            %   Connect to a Sense HAT device on Raspberry Pi hardware board.
            %
            %   Syntax:
            %   sensehatObj = sensehat(r)
            %
            %   Description:
            %   Connect to a Sense HAT shield on Raspberry Pi.
            %
            %   Example:
            %       r = raspi();
            %       hat = sensehat(r);
            %
            %   Input Arguments:
            %   r       - Raspberry Pi connection
            %
            %   Output Arguments:
            %   sensehatObj  - Sense HAT device connection.
            %
            %   See also i2cdev, spidev, servo, serialdev, webcam, cameraboard
            
            try
                sensehatObj = obj.RaspiImpl.sensehat(varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function displayImage(obj,img,varargin)
            %   Display an input image
            %
            %   Syntax:
            %   displayImage(r, inputImage)
            %   displayImage(r, inputImage, Name, Value)
            %
            %   Description:
            %   displayImage(r, inputImage)                  Display the inputImage on the computer screen. During deployment, the image is displayed on the Raspberry Pi screen.
            %   displayImage(r, inputImage, Name, Value)     Display the inputImage with additional options specified by one or more Name-Value pair arguments.
            %
            %   Example:
            %       r = raspi();
            %       w = webcam(r);
            %       img = snapshot(w);
            %       displayImage(r,img);
            %
            %   Example:
            %       r = raspi();
            %       w = webcam(r);
            %       img = snapshot(w);
            %       displayImage(r,img,'Title','Webcam Output');
            %
            %   Input Arguments:
            %   r        - Raspberry Pi connection
            %   inputImage  - Input image of size MxNx3 or MxN
            %
            %   Name-Value Pair Input Arguments:
            %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value.
            %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
            %
            %   NV Pair:
            %   'Title' - Title of the image window.
            %
            %   See also webcam, cameraboard
            try
                obj.RaspiImpl.displayImage(img,varargin{:});
            catch me
                throwAsCaller(me);
            end
        end
    end
    
    % Display method
    methods(Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            obj.RaspiImpl.displayObject;
            fprintf('\n%s\n',getFooter(obj));
        end
        
        function s = getFooter(obj) %#ok<MANU>
            s = sprintf(['  <a href="matlab:raspi.internal.helpView', ...
                '(''raspberrypiio'',''RaspiSupportedPeripherals'')">', ...
                'Supported peripherals</a>\n']);
        end
    end
end

% LocalWords:  ipaddress serialnum testpi raspberrypi MJONES myhomepi
% LocalWords:  raspilist cdev spidev webcam cameraboard sudo dev tty testfile
% LocalWords:  myvideo myfolder addrs CBus SPI peripherial rpi Pullup
% LocalWords:  tmp serialdev sensehat AWB GPIO Webcams raspberrypiio spi
