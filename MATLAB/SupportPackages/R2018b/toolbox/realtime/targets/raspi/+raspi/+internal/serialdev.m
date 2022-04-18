classdef serialdev < handle & matlab.mixin.CustomDisplay
    %SERIALDEV Create a serial device object.
    %   
    % sp = serialdev(port) creates a serial device object.
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = private)
        Port
        BaudRate = 115200;
        DataBits = 8;
        Parity   = 'none';
        StopBits = 1;
    end
    
    properties (Access = public)
        Timeout  = 10;
    end
    
    properties (Access = private)
        RaspiObj
        DeviceNumber
        SizeofPrecision
        PollTimeoutInMs
        % Maintain a map of created objects to gain exclusive access
        Map = containers.Map();
        Initialized = false;
    end
    
    properties (Dependent, Access = private)
        NumericParity
    end
    
    properties (Hidden, Constant)
        % Serial constants
        AvailableBaudRates = [50, 75, 110, 134, 150, 200, 300, 600, ...
            1200, 1800, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400];
        AvailableDataBits = [5, 6, 7, 8];
        AvailableParities = {'none', 'even', 'odd'};
        AvailableStopBits = [1, 2];
    end
    
    properties (Constant, Access = private)
        % Serial requests
        REQUEST_SERIAL_INIT           = 5000;
        REQUEST_SERIAL_READ           = 5001;
        REQUEST_SERIAL_WRITE          = 5002;
        REQUEST_SERIAL_TERMINATE      = 5003;
    end
    
    properties (Constant, Access = private)
        AvailablePrecisions = {'char', 'int8', 'uint8', 'int16', 'uint16', ...
            'int32', 'uint32', 'int64', 'uint64', 'single', 'double'};
        SIZEOF = struct(...
            'char', 1, ...
            'int8', 1, ...
            'uint8', 1, ...
            'int16', 2, ...
            'uint16', 2, ...
            'int32', 4, ...
            'uint32', 4, ...
            'int64', 8, ...
            'uint64', 8, ...
            'single', 4, ...
            'double', 8);
        AvailableNumericParities = [0, 1, 2];
    end
    
    methods
        function obj = serialdev(raspiObj, port, baudRate, dataBits, parity, stopBits)
            obj.RaspiObj = raspiObj;
            
            % Set main parameters of the object
            obj.Port = port;
            if nargin > 2
                obj.BaudRate = baudRate;
            end
            if nargin > 3
                obj.DataBits = dataBits;
            end
            if nargin > 4
                obj.Parity = parity;
            end
            if nargin > 5
                obj.StopBits = stopBits;
            end
            
            % Check if an existing serial object exists
            if isUsed(obj, obj.Port)
                error(message('raspi:utils:SerialPortInUse', obj.Port));
            end
            
            % Initialize serial device
            obj.RaspiObj.sendRequest(obj.REQUEST_SERIAL_INIT, ...
                uint32(obj.BaudRate), uint32(obj.DataBits), ...
                uint32(obj.NumericParity), uint32(obj.StopBits), ...
                uint8(obj.cString(obj.Port)));
            obj.DeviceNumber = typecast(obj.RaspiObj.recvResponse(), 'uint32');

            % Add serial connection to map
            obj.markUsed(obj.Port);
            obj.Initialized = true;
        end
        
        function write(obj, data, precision)
            try
                if (nargin < 3)
                    precision = 'uint8';
                else
                    precision = validatestring(precision, obj.AvailablePrecisions, ...
                        '', 'precision');
                end
                if strcmp(precision,'char')
                    data = uint8(data);
                else
                data = typecast(cast(data, precision), 'uint8');
                end
                obj.RaspiObj.sendRequest(obj.REQUEST_SERIAL_WRITE, ...
                    uint32(obj.DeviceNumber), ...
                    uint32(length(data)), data);
                obj.RaspiObj.recvResponse();
            catch e
                throwAsCaller(e);
            end
        end
        
        function data = read(obj, count, precision)
            try
                if (nargin < 3)
                    precision = 'uint8';
                else
                    precision = validatestring(precision, obj.AvailablePrecisions, ...
                        '', 'precision');
                end
                obj.RaspiObj.sendRequest(obj.REQUEST_SERIAL_READ, ...
                    uint32(obj.DeviceNumber), ...
                    uint32(count * obj.SIZEOF.(precision)), ...
                    int32(obj.PollTimeoutInMs));
                
                if strcmp(precision,'char')
                    data = char(obj.RaspiObj.recvResponse());
                else
                data = typecast(obj.RaspiObj.recvResponse(), precision);
                end
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods
        % GET / SET methods
        function set.Port(obj, value)
            validateattributes(value, {'char'}, ...
                    {'nonempty', 'row'}, '', 'port');
            obj.Port = strtrim(value);
        end
        
        function set.BaudRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan'}, '', 'BaudRate');
            if ~ismember(value, obj.AvailableBaudRates)
                error(message('raspi:utils:InvalidBaudRate', ...
                    ['[' sprintf('%d, ',obj.AvailableBaudRates) ']']));
            end
            obj.BaudRate = value;
        end
        
        function set.DataBits(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan'}, '', 'DataBits');
            if ~ismember(value, obj.AvailableDataBits)
                error(message('raspi:utils:InvalidDataBits', ...
                    ['[' sprintf('%d, ',obj.AvailableDataBits) ']']));
            end
            obj.DataBits = value;
        end
        
        function set.StopBits(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan'}, '', 'StopBits');
            if ~ismember(value, obj.AvailableStopBits)
                error(message('raspi:utils:InvalidStopBits', ...
                    ['[' sprintf('%d, ',obj.AvailableStopBits) ']']));
            end
            obj.StopBits = value;
        end
        
        function set.Parity(obj, value)
            obj.Parity = validatestring(value, obj.AvailableParities, ...
                '', 'Parity');
        end
        
        function set.Timeout(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative','<=',10, 'nonnan'}, '', 'Timeout');
            obj.Timeout = value;
        end
        
        function ret = get.NumericParity(obj)
            ret = obj.AvailableNumericParities(...
                ismember(obj.AvailableParities, obj.Parity));
        end
        
        function ret = get.PollTimeoutInMs(obj)
            if isinf(obj.Timeout)
                ret = -1; %poll function takes -1 to indicate wait forever 
            else
                ret = 1000 * obj.Timeout;
            end
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            orderedPropNames = {...
                'Port', ...
                'BaudRate', ...
                'DataBits', ...
                'Parity', ...
                'StopBits', ...
                'Timeout'};
            groups = matlab.mixin.util.PropertyGroup(orderedPropNames);
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj, groups);
            
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
    
    methods (Access = private)
        function delete(obj)
            try
                if obj.Initialized
                    obj.markUnused(obj.Port);
                    obj.RaspiObj.sendRequest(obj.REQUEST_SERIAL_TERMINATE, ...
                        uint32(obj.DeviceNumber));
                    obj.RaspiObj.recvResponse();
                end
            catch
                % do not throw errors/warnings at destruction
            end
        end
        
        function S = saveobj(~)
            S = [];
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:SaveNotSupported', 'serialdev'));
        end
        
        function ret = isUsed(obj, port)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress) && ...
                ismember(port, obj.Map(obj.RaspiObj.DeviceAddress))
                ret = true;
            else
                ret = false;
            end
        end
        
        function markUsed(obj, port)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress)
                used = obj.Map(obj.RaspiObj.DeviceAddress);
                obj.Map(obj.RaspiObj.DeviceAddress) = union(used, port);
            else
                obj.Map(obj.RaspiObj.DeviceAddress) = {port};
            end
        end
        
        function markUnused(obj, port)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress)
                used = obj.Map(obj.RaspiObj.DeviceAddress);
                obj.Map(obj.RaspiObj.DeviceAddress) = setdiff(used, port);
            end
        end
    end
    
    methods (Hidden, Static)
        function out = loadobj(~)
            out = raspi.internal.serialdev.empty();
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:LoadNotSupported', ...
                'serialdev', 'serialdev'));
        end
        
        function decvalue = hex2dec(hexvalue)
            decvalue = hex2dec(regexprep(hexvalue, '0x', ''));
        end
        
        function hexvalue = dec2hex(decvalue)
            hexvalue = ['0x' dec2hex(decvalue)];
        end
        
        function str = cString(str)
            str(end+1) = 0;
        end
    end
end

