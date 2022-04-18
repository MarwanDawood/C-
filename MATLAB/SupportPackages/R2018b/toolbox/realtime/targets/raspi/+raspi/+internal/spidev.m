classdef spidev < handle & matlab.mixin.CustomDisplay
    %SPIDEV Create a SPI device object.
    %   
    % sp = spidev(channel) creates a SPI device object.
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = private)
        Channel
        Mode        = 0;
        BitsPerWord = 8;
        Speed       = 500000;
    end
    
    properties (Hidden, Constant)
        % SPI constants
        AvailableSPIModes    = [0, 1, 2, 3];
        AvailableBitsPerWord = 8;
        AvailableSpeeds      = [500000, 1000000, 2000000, 4000000, 8000000, 16000000, 32000000];
    end
    
    properties (Access = private)
        RaspiObj
        ChannelNumber
        Initialized = false;
        Map = containers.Map();  
    end
    
    properties (Constant, Access = private)
        % SPI requests
        REQUEST_SPI_INIT           = 4000;
        REQUEST_SPI_TERMINATE      = 4001;
        REQUEST_SPI_WRITEREAD      = 4002;
        REQUEST_SPI_READ_REGISTER  = 4003;
        REQUEST_SPI_WRITE_REGISTER = 4004;
        AvailablePrecisions = {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32'};
    end
    
    methods
        function obj = spidev(raspiObj, channel, mode, speed, bitsPerWord)
            obj.RaspiObj = raspiObj;
            
            % Set main properties of this object
            obj.Channel = channel;
            if nargin > 2
                obj.Mode = mode;
            end
            if nargin > 3
                obj.Speed = speed;
            end
            if nargin > 4
                obj.BitsPerWord = bitsPerWord;
            end
            
            % Check that the given channel is available. This is done here
            % instead of the set method since it requires accessing the
            % properties of raspiObj
            if ~ismember(obj.Channel, obj.RaspiObj.AvailableSPIChannels)
                error(message('raspi:utils:InvalidSPIChannel', obj.Channel));
            end
            obj.ChannelNumber = str2double(obj.Channel(end));
            
            % Check if user has already constructed an SPI object for this
            % channel
            if isUsed(obj, obj.Channel)
                error(message('raspi:utils:SPIChannelInUse', obj.Channel));
            end
            
            % Initialize SPI channel for RDWR
            obj.RaspiObj.sendRequest(obj.REQUEST_SPI_INIT, ...
                uint32(obj.ChannelNumber), uint8(obj.Mode), ...
                uint8(obj.BitsPerWord), uint32(obj.Speed));
            obj.RaspiObj.recvResponse();
            
            % Add this instance to the map
            obj.markUsed(obj.Channel);
            obj.Initialized = true;
        end

        function rdData = writeRead(obj, wrData, precision)
            %int EXT_SPI_writeRead(const unsigned int channel, void *data, 
            %const uint8_T bitsPerWord, const size_t count)
            if (nargin < 3)
                precision = 'uint8';
            else
                precision = validatestring(precision, obj.AvailablePrecisions, ...
                    '', 'precision');
            end
            % Data is written by the SPI controller in chunks of uint8
            wrData = typecast(cast(wrData, precision), 'uint8'); 
            obj.RaspiObj.sendRequest(obj.REQUEST_SPI_WRITEREAD, ...
                uint32(obj.ChannelNumber), uint8(obj.BitsPerWord), ...
                uint32(length(wrData)), wrData); 
            rdData = typecast(obj.RaspiObj.recvResponse(), precision);
        end
    end
    
    methods
        % GET / SET methods
        function set.RaspiObj(obj, value)
            if ~isa(value, 'raspi.internal.raspiBase')
                error(message('raspi:utils:ExpectedRaspiObj'));
            end
            obj.RaspiObj = value;
        end
        
        function set.Mode(obj, value)
            validateattributes(value, {'numeric'}, ...
                    {'scalar', 'nonnegative'}, '', 'Mode');
            if ~ismember(value, obj.AvailableSPIModes)
                str = obj.printIntArray(obj.AvailableSPIModes);
                error(message('raspi:utils:InvalidSPIMode', str));
            end
            obj.Mode = value;
        end
        
        function set.BitsPerWord(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative'}, '', 'BitsPerWord');
            if ~ismember(value, obj.AvailableBitsPerWord)
                str = obj.printIntArray(obj.AvailableBitsPerWord);
                error(message('raspi:utils:InvalidSPIBitsPerWord', str));
            end
            obj.BitsPerWord = value;
        end
        
        function set.Channel(obj, value)
            validateattributes(value, {'char'}, ...
                    {'row', 'nonempty'}, '', 'Channel');
            obj.Channel = value;
        end
        
        function set.ChannelNumber(obj, value)
            validateattributes(value, {'numeric'}, ...
                    {'scalar', 'nonnegative'}, '', 'ChannelNumber');
            obj.ChannelNumber = value;
        end
        
        function set.Speed(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'positive'}, '', 'Speed');
            if ~ismember(value, obj.AvailableSpeeds)
                str = obj.printIntArray(obj.AvailableSpeeds);
                error(message('raspi:utils:InvalidSPISpeed', str));
            end
            obj.Speed = value;
        end
    end
    
    methods (Access = private)
        function delete(obj)
            try
                if obj.Initialized
                    obj.markUnused(obj.Channel)
                    obj.RaspiObj.sendRequest(obj.REQUEST_SPI_TERMINATE, ...
                        uint32(obj.ChannelNumber));
                    obj.RaspiObj.recvResponse();
                end
            catch
                % do not throw errors/warnings on destruction
            end
        end
        
        function S = saveobj(~)
            S = [];
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:SaveNotSupported', 'spidev'));
        end
        
        function ret = isUsed(obj, channel)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress) && ...
                ismember(channel, obj.Map(obj.RaspiObj.DeviceAddress))
                ret = true;
            else
                ret = false;
            end
        end
        
        function markUsed(obj, channel)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress)
                used = obj.Map(obj.RaspiObj.DeviceAddress);
                obj.Map(obj.RaspiObj.DeviceAddress) = union(used, channel);
            else
                obj.Map(obj.RaspiObj.DeviceAddress) = {channel};
            end
        end
        
        function markUnused(obj, channel)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress)
                used = obj.Map(obj.RaspiObj.DeviceAddress);
                obj.Map(obj.RaspiObj.DeviceAddress) = setdiff(used, channel);
            end
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            % Display main options
            fprintf('                 Channel: %-15s\n', obj.Channel);
            fprintf('                    Mode: %-15d (0, 1, 2 or 3)\n', obj.Mode);
            fprintf('             BitsPerWord: %-15d (only 8-bits per word is supported)\n', obj.BitsPerWord);  
            fprintf('                   Speed: %-15d (<a href="%s">View available speeds</a>)\n', ... 
                obj.Speed, ...
                i_getHyperlinkAction('Available speeds', obj.printIntArray(obj.AvailableSpeeds)));
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
    
    methods (Hidden, Static)
        function out = loadobj(~)
            out = raspi.internal.spidev.empty();
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:LoadNotSupported', ...
                'spidev', 'spidev'));
        end
        
        function str = printIntArray(array)
            array = array(:);
            str = '';
            N = length(array);
            for i = 1:N
                str = [str, sprintf('%d', array(i))]; %#ok<AGROW>
                if i ~= N
                    str = [str, ', ']; %#ok<AGROW>
                end
            end
        end
    end
end

%% Internal functions
function str = i_getHyperlinkAction(title, valuesStr)
str = [title, ': ', valuesStr];
str = ['matlab:disp(''' str ''')'];
end

