classdef sensehat < handle & matlab.mixin.CustomDisplay
    %SENSEHAT Create a SenseHAT object.
    %
    % sh = sensehat(raspiObj) creates an object connected to the Sense HAT
    % attached to a Raspberry Pi board.'raspiObj' is the object connected 
    % to the Raspberry Pi, to which this Sense HAT is attached.
    %
    % 
    
    % Copyright 2016-2018 The MathWorks, Inc.
    
    properties (Constant)
        Name = 'Raspberry Pi Sense HAT';
    end
    
    properties(Hidden,Access = private)
        Bus
        Protocol = 'i2c';
        RaspiObj
        Map = containers.Map();
        Initialized = false;
        Opened = false;
        
    end
    
    properties(Hidden)
        HumiditySensor
        PressureSensor
        IMUSensor
        Joystick
        LEDMatrix
    end
    
    properties(Hidden)
        Debug
    end
    
    
    methods
        function obj = sensehat(hw,varargin)
            narginchk(1,2);
            if nargin > 1
                obj.Debug=varargin{1};
            end
            validateattributes(hw,{'raspi.internal.raspiOnline','raspi.internal.raspiDesktop'},{},'','hardware');
            obj.RaspiObj = hw;
            
            %Check if the SenseHAT is already in use
            if isUsed(obj, obj.Name)
                error(message('raspi:utils:SenseHATInUse','sensehat'));
            end
            
            %Check if the SenseHAT is available
            [bus,available]=obj.IsSensehatAvailable;
            if~(available)
                error(message('raspi:utils:NoSenseHAT'));
            else
                obj.Bus =bus;
            end
            
            %Open and Intialize senseHAT
            Open(obj);
            
            % Add object to the container map
            markUsed(obj,obj.Name);
            obj.Initialized = true;
        end
        
        function T = readTemperature(obj,varargin)
            %temperature = readTemperature(sensehatObj,sensor) reads the
            %value of temperature measured by the specified sensor on SenseHAT.
            % Tempearture can be measured using Humidity sensor or the
            % Pressure sensor.
            % temperature = readTemperature(sensehatObj, 'usehumiditysensor') 
            % reads the temperature from Humidity sensor.
            % temperature = readTemperature(sensehatObj, 'usepressuresensor') 
            % reads the temperature from Pressure sensor.
            %
            % By default, temperature is measured using Humidity sensor.
            %temperature = readTemperature(sensehatObj) reads the
            % temperature measured by the Humidity sensor on SenseHAT.
            %
            % The function returns Temperature as a double in Kelvin (K).
            narginchk(1,2);
            if nargin > 1
                option = validatestring(varargin{1},...
                    {'usehumiditySensor','usepressuresensor'});
                if strcmpi(option,'usehumiditysensor')
                    T = readTemperature(obj.HumiditySensor);
                else
                    if strcmpi(option,'usepressuresensor')
                        T = readTemperature(obj.PressureSensor);
                    else
                        error(message('raspi:utils:InvalidSensorSetting',...
                            'mode','''usehumiditysensor'' and ''usepressuresensor'''));
                    end
                end
            else
                T = readTemperature(obj.HumiditySensor);
            end
            
            % Convert temperature to kelvin
            T = T + 273.15;
        end
        
        function H = readHumidity(obj)
            %humidity = readHumidity(sensehatObj) reads the value of
            % relative humidity measured by the Humidity sensor.
            %
            % The function returns Humidity as a double in percentage relative
            % humidity (%rH).
            H = obj.HumiditySensor.readHumidity;
        end
        
        function  P = readPressure(obj)
            %pressure = readPressure(sensehatObj) reads the value of
            %pressure measured by the Barometric air pressure sensor.
            %
            %The function returns Pressure as a double in Pascal (Pa).
            P = obj.PressureSensor.readPressure;
            %Convert from hPa to Pa
                P = P*100;
            end
        
        function [angularVelocity,ts] = readAngularVelocity(obj,varargin)
            % angularVelocity =readAngularVelocity(sensehatObj) reads a 1-by-3 vector of angular
            % velocity measured by the Gyroscope of the IMU sensor.
            %
            % angularVelocity =readAngularVelocity(sensehatObj,'raw') reads the raw
            % uncalibrated value of angular velocity.
            %
            %The function returns angular velocity as a 1-by-3 vector of
            %double in radians per second (rad/s).
            narginchk(1,2);
            if nargin >1
                [angularVelocity,ts] = readAngularVelocity(obj.IMUSensor,varargin{:});
            else
                [angularVelocity,ts] = readAngularVelocity(obj.IMUSensor);
            end
            %Convert to rad/s
            angularVelocity = angularVelocity*0.01745;
        end
        
        function [acceleration,ts] = readAcceleration(obj,varargin)
            % acceleration =readAcceleration(sensehatObj) reads a 1-by-3 vector of acceleration
            % measured by the Accelerometer of the IMU sensor.
            %
            % acceleration =readAcceleration(sensehatObj,'raw') reads the raw
            % uncalibrated value of acceleration.
            %
            %The function returns acceleration as a 1-by-3 vector of
            %double in meter per second squared(m/s2).
            narginchk(1,2);
            if nargin >1
                [acceleration,ts] = readAcceleration(obj.IMUSensor,varargin{:});
            else
                [acceleration,ts] = readAcceleration(obj.IMUSensor);
            end
            %Convert to m/s2
                acceleration = acceleration*9.8;
            end
        
        function [magneticField,ts] = readMagneticField(obj,varargin)
            % magneticField =readMagneticField(sensehatObj) reads a 1-by-3 vector of magneticField
            % measured by the Magnetometer of the IMU sensor.
            %
            % magneticField =readMagneticField(sensehatObj,'raw') reads the raw
            % uncalibrated value of magneticField.
            %
            %The function returns magnetic field as a 1-by-3 vector of
            %double in micro Tesla (�T).
            narginchk(1,2);
            if nargin >1
                [magneticField,ts] = readMagneticField(obj.IMUSensor,varargin{:});
            else
                [magneticField,ts] = readMagneticField(obj.IMUSensor);
            end
        end
        
        
        
        function buttonpress = readJoystick(obj,varargin)
            % buttonpress = readJoystick(sensehatObj) reads the state of
            % the joystick on SenseHAT. readJoystick returns a value between
            % 0 and 5 depending on the state of the joystick.
            % Possible states of the joystick are:
            % * 0 - joystick not pressed
            % * 1 - center
            % * 2 - left
            % * 3 - up
            % * 4 - right
            % * 5 - down
            %
            % buttonpress = readJoystick(sensehatObj, buttonPosition)
            % reads whether the specified buttonposition on the joystick is
            % being pressed, and returns the status as a logical value.
            % * 0 - not pressed
            % * 1 - pressed
            
            narginchk(1,2);
            if nargin > 1
                buttonpress = readJoystick(obj.Joystick,varargin{1});
            else
                buttonpress = readJoystick(obj.Joystick);
            end
        end
        
        function writePixel(obj,pixelLocation,pixelValue)
            % writePixel(sensehatObj, pixelLocation, pixelValue) sets the
            % value specified by pixelValue to the pixel present in the
            % location specified by pixelLocation.
            %
            % pixelLocation should be a row vector. It is represented as
            % [col row], where, col and row can range between 1 to 8. Pixel
            % [1 1] is located at the top left of the LED Matrix and pixel [1 8]
            % is located at the bottom left of the LED Matrix.
            %
            % pixelvalue should be a row vector. It is represented as [R G B],
            % where, R, G, and B can range between 0 to 255. The color
            % for the pixel can also be specified by providing the name of
            % the color. The list od supported colors are:
            %  * 'red' or 'r'
            %  * 'green' or 'g'
            %  * 'blue' or 'b'
            %  * 'yellow' or 'y'
            %  * 'magenta' or 'm'
            %  * 'cyan' or 'c'
            %  * 'white' or 'w'
            %  * 'black' or 'k'
            writePixel(obj.LEDMatrix,pixelLocation,pixelValue);
        end
        
        function displayImage(obj,img,varargin)
            % displayImage(sensehatObj, image , orientation) displays the image on the
            % LED matrix of SenseHAT.
            % Image should be of 8-by-8-by-3 dimension and the value of each pixel can range between 0 to 255.
            % 
            % 'Orientation' decides the angle of rotation applied to the
            % displayed image. The supported values of orientation are 0,
            % 90, 180, and 270.
            displayImage(obj.LEDMatrix,img,varargin{:});
        end
        
        function displayMessage(obj,message,varargin) 
            % displayMessage(sensehatObj, message) displays a scrolling
            % message on the LED matrix of SenseHAT.
            %
            % displayMessage(sensehatObj,'P1',v1,'P2',v2,...) displays a
            % scrolling message on the LED matrix of SenseHAT applying the
            % specified parameter value pair.
            % Supported parameters are: 
            %
            %   * ScrollingSpeed - Time taken by the message to shift one column
            %   to the left on the LED matrix.Default: 0.1 s.
            %
            %   * Orientation - Angle of rotation applied to the display. The
            %   supported values of orientation are 0, 90, 180, and 270.
            %   Default: 0
            %
            %   * TextColor - Color of the text to be displayed. textColor
            %   can be specified as a 1-by-3 RGB color or as a color string
            %   such as 'white' or 'w'. Default: 'red' or 'r' or [255 0 0}
            %
            %   * BackgroundColor - background color for the text. backgroundColor
            %   can be specified as a 1-by-3 RGB color or as a color string
            %   such as 'white' or 'w'. Default: 'black' or 'k' or [0 0 0].
            % 
            % textColor and backgroundColor can be specifed by providing the
            % color names, the list of supported color names are:
            % * 'red' or 'r'
            % * 'green' or 'g'
            % * 'blue' or 'b'
            % * 'yellow' or 'y'
            % * 'magenta' or 'm'
            % * 'cyan' or 'c'
            % * 'white' or 'w'
            % * 'black' or 'k'
            
            
            displayMessage(obj.LEDMatrix,message,varargin{:});
        end
        
        function clearLEDMatrix(obj)
            % clearLEDMatrix(sensehatObj) clear the LED matrix and turnoff
            % all the pixels of the LED matrix present on SenseHAT.
            clearLEDMatrix(obj.LEDMatrix);
        end
    end
    
    methods(Access=private)
        function [Bus,available] = IsSensehatAvailable(obj)
            %Get the available i2c buses on the device
            AvailableBuses = obj.RaspiObj.AvailableI2CBuses;
            
            %Check if the SenseHAT is connected to the Board.
            %This is done by checking if the sensors with a known address
            %are present on the bus.
            SHavailable=0;
            Bus=-1;
            for ii= 1:length(AvailableBuses)
                Addresslist = obj.RaspiObj.scanI2CBus(AvailableBuses{ii});
                if ~isempty(Addresslist)
                    if (ismember('0x1C',Addresslist) && ismember('0x5C',Addresslist) && ...
                            ismember('0x5F',Addresslist) && ismember('0x6A',Addresslist))
                        SHavailable=1;
                        Bus = str2double(AvailableBuses{ii}(end));
                        break;
                    end
                end
            end
            available = SHavailable;
        end
        
        function ret = isUsed(obj, name)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress) && ...
                    ismember(name, obj.Map(obj.RaspiObj.DeviceAddress))
                ret = true;
            else
                ret = false;
            end
        end
        
        function markUsed(obj, name)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress)
                used = obj.Map(obj.RaspiObj.DeviceAddress);
                obj.Map(obj.RaspiObj.DeviceAddress) = union(used, name);
            else
                obj.Map(obj.RaspiObj.DeviceAddress) = {name};
            end
        end
        
        function markUnused(obj, name)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress)
                used = obj.Map(obj.RaspiObj.DeviceAddress);
                obj.Map(obj.RaspiObj.DeviceAddress) = setdiff(used, name);
            end
        end
        
        function delete(obj)
            try
                if obj.Initialized
                    obj.markUnused(obj.Name)
                    obj.HumiditySensor.delete
                    obj.PressureSensor.delete
                    obj.IMUSensor.delete
                end
            catch
                % Do not throw errors on destroy.
            end
        end
        
         function S = saveobj(~)
            S = [];
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:SaveNotSupported', 'sensehat'));
        end
        
        function Open(obj)
            try
                obj.HumiditySensor = raspi.internal.hts221('Master',obj.RaspiObj,'Bus_hts221',obj.Bus);
            catch
                error(message('raspi:utils:SenseHATInUse','hts221'));
            end
            try
                obj.PressureSensor = raspi.internal.lps25h('Master',obj.RaspiObj,'Bus',obj.Bus);
            catch
                error(message('raspi:utils:SenseHATInUse','lps25h'));
            end
            try
                obj.IMUSensor = raspi.internal.lsm9ds1('Master',obj.RaspiObj,'Bus',obj.Bus);
            catch
                error(message('raspi:utils:SenseHATInUse','lsm9ds1'));
            end
            
            try
                obj.Joystick = raspi.internal.joystick(obj.RaspiObj);
            catch
                error(message('raspi:utils:SenseHATInUse','Joystick'));
            end
            
            try
                obj.LEDMatrix = raspi.internal.frameBuffer(obj.RaspiObj);
            catch
                error(message('raspi:utils:SenseHATInUse','LEDMatrix'));
            end
        end
        
        function enableSensor(obj,varargin)
            %enableSensor(sensehatObj,sensor) enables the specified the
            %sensor on SenseHAT.
            %All sensor are enabled by default. Reading from a sensor is
            %permitted only when it is enabled.
            narginchk(1,2);
            if nargin > 1
                option = validatestring(varargin{1},{'humiditysensor',...
                    'pressuresensor','imusensor','gyroscope',...
                    'accelerometer','magnetometer'});
                switch option
                    case 'humiditysensor'
                        enableSensor(obj.HumiditySensor);
                    case 'pressuresensor'
                        enableSensor(obj.PressureSensor);
                    case 'imusensor'
                        enableSensor(obj.IMUSensor);
                    case 'gyroscope'
                        enableGyroscope(obj.IMUSensor);
                    case 'accelerometer'
                        enableAccelerometer(obj.IMUSensor);
                    case 'magnetometer'
                        enableMagnetometer(obj.IMUSensor);
                end
            else
                enableSensor(obj.HumiditySensor);
                enableSensor(obj.PressureSensor);
                enableSensor(obj.IMUSensor);
            end
        end
        
        function disableSensor(obj,varargin)
            %disableSensor(sensehatObj,sensor) disable the specified sensor
            %on SenseHAT.
            narginchk(1,2);
            if nargin > 1
                option = validatestring(varargin{1},{'humiditysensor',...
                    'pressuresensor','imusensor','gyroscope',...
                    'accelerometer','magnetometer'});
                switch (char(option))
                    case 'humiditysensor'
                        disableSensor(obj.HumiditySensor);
                    case 'pressuresensor'
                        disableSensor(obj.PressureSensor);
                    case 'imusensor'
                        disableSensor(obj.IMUSensor);
                    case 'gyroscope'
                        disableGyroscope(obj.IMUSensor);
                    case 'accelerometer'
                        disableAccelerometer(obj.IMUSensor);
                    case 'magnetometer'
                        disableMagnetometer(obj.IMUSensor);
                end
            else
                disableSensor(obj.HumiditySensor);
                disableSensor(obj.PressureSensor);
                disableSensor(obj.IMUSensor);
            end
        end
    end %methods
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            % Display main options
            fprintf('                          Name: %-15s\n', 'Raspberry Pi Sense HAT');
            fprintf('\n%s\n',getFooter(obj));
        end
        function s = getFooter(obj) %#ok<MANU>
            s = sprintf(['  <a href="matlab:raspi.internal.helpView', ...
                '(''raspberrypiio'',''sense_hat'')">', ...
                'Show all functions</a>\n']);
        end
    end%methods
    
    methods (Hidden, Static)
        function out = loadobj(~)
            out = raspi.internal.sensehat.empty();
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:LoadNotSupported', ...
                'sensehat', 'sensehat'));
        end
    end
end
