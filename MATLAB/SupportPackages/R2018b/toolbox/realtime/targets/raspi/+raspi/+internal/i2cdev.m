classdef i2cdev < handle
    %I2CDEV Construct an I2C device object.
    %   I2CDEV(HW,BUS,ADDR) creates an I2C device object given a
    %   rhardware object HW (e.g. Raspberry Pi), the I2C bus name BUS,
    %   (e.g., 'i2c-1'), and the I2C bus address ADDR as a decimal number
    %   or a hexadecimal string (e.g., '0x1E', '70', 14).
    
    % Copyright 2013-2015 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Bus       = ''         % I2C bus name, e.g., 'i2c-1'
        Address   = '0'        % I2C device address as a hexadecimal string
    end
    
    properties (Access = private)
        BusNumber = uint32(0)  % I2C bus number as a decimal value
        AddrDec   = uint8(0)   % I2C device address as a decimal value
    end
    
    properties (Access = private)
        Hw
        Initialized = false
        Map = containers.Map
    end
    
    properties (Dependent, Access = private)
        DeviceID
    end
    
    properties (Constant, Access = private)
        % I2C requests
        REQUEST_I2C_INIT           = 3001
        REQUEST_I2C_READ           = 3002
        REQUEST_I2C_WRITE          = 3003
        REQUEST_I2C_TERMINATE      = 3004
        REQUEST_I2C_READ_REGISTER  = 3005
        REQUEST_I2C_WRITE_REGISTER = 3006
        
        MAX_I2C_ADDRESS = hex2dec('7f')
        
        AvailablePrecisions = {'int8','uint8','int16','uint16',...
            'int32','uint32','int64','uint64','single','double'}
    end
    
    methods
        function obj = i2cdev(hw, bus, addr)
            %I2CDEV Construct I2C object.
            %  hw:  hardware object
            %  bus: String name of I2C bus, i.e., 'i2c-1'
            % addr: I2C address as decimal number or hexadecimal string
            %       Examples: '0x1E', '70', 14
            
            obj.Hw = hw;
            obj.Bus = bus;
            
            [addrDec,addrHex] = convertAddress(addr);
            if addrDec < 0 || addrDec > obj.MAX_I2C_ADDRESS
                error(message('raspi:utils:InvalidI2CAddress'));
            end
            obj.Address = addrHex;
            obj.AddrDec = uint8(addrDec);
            
            % Check that the given bus is available.
            %
            % This is done here instead of the set method since it requires
            % accessing properties of Hw
            %
            if ~any(strcmpi(bus,hw.AvailableI2CBuses))
                error(message('raspi:utils:InvalidI2CBus', bus));
            end
            
            % Record bus number, taken from bus name
            % - 'i2c-#' with multiple digits
            busnum = sscanf(bus,'i2c-%d');
            obj.BusNumber = uint32(busnum);
            
            % Check that a device with given I2C address is on the bus
            all_i2c_dev = obj.hex2dec(scanI2CBus(obj.Hw,bus));
            if isempty(all_i2c_dev) || ...
                    ~any(addrDec == all_i2c_dev)
                error(message('raspi:utils:NoSuchI2CDevice',addrHex));
            end
            
            % Check if address is already in use
            if isUsed(obj,obj.DeviceID)
                error(message('raspi:utils:I2CAddressInUse',addrHex));
            end
            
            % Initialize I2C bus for RDWR
            init(obj);
            markUsed(obj,obj.DeviceID);
            obj.Initialized = true;
        end
        
        function write(obj,data,prec)
            %write Write data to I2C device.
            %
            %   write(obj,DATA,PREC) writes a DATA to I2C device with
            %   specified precision PREC. If omitted, PREC defaults to
            %   'uint8'.
            %
            % If DATA is a vector, each value is written to the I2C device
            % in succession.
            if nargin < 3
                prec = 'uint8';
            else
                prec = validatestring(prec, obj.AvailablePrecisions, ...
                    '', 'precision');
            end
            data = cast(data, prec);
            
            sendRequest(obj.Hw, ...
                obj.REQUEST_I2C_WRITE, ...
                obj.BusNumber, ...
                obj.AddrDec, ...
                uint32(numel(data) * sizeof(prec)), ...
                data);
            recvResponse(obj.Hw);
        end
        
        function writeRegister(obj,reg,data,prec)
            %writeRegister Write value to register.
            %  writeRegister(obj, REG, DATA)
            %  writeRegister(obj, REG, DATA, PREC)
            %
            % If DATA is a vector, each value is written to the register in
            % succession.  Specifying a vector enables efficient writing
            % for devices that automatically increment the register address
            % after each write operation.
            if nargin < 4
                prec = 'uint8';
            else
                prec = validatestring(prec, ...
                    obj.AvailablePrecisions,'','precision');
            end
            data = [uint8(reg) typecast(cast(data,prec),'uint8')];
            sendRequest(obj.Hw, ...
                obj.REQUEST_I2C_WRITE, ...
                obj.BusNumber, ...
                obj.AddrDec, ...
                uint32(numel(data)),  ...
                data);
            recvResponse(obj.Hw);
        end
        
        function data = read(obj,cnt,prec)
            %read Read a value from I2C device.
            %   read(obj,CNT) returns a row vector of CNT values read from
            %   an I2C device. The precision of returned data is uint8.
            %
            %   read(obj,CNT,PREC) reads a row vector of CNT values with
            %   specified precision PREC.
            if nargin < 3
                prec = 'uint8';
            else
                prec = validatestring(prec, ...
                    obj.AvailablePrecisions,'','precision');
            end
            sendRequest(obj.Hw, ...
                obj.REQUEST_I2C_READ, ...
                obj.BusNumber, ...
                obj.AddrDec, ...
                uint32(cnt * sizeof(prec)));
            data = typecast(recvResponse(obj.Hw), prec);
        end
        
        function data = readRegister(obj,reg,arg3,arg4)
            %readRegister Read value from register.
            %   readRegister(obj,REG) reads a uint8 value from register
            %   REG.  REG must be a scalar numeric address.
            %
            %   readRegister(obj,REG,PREC) specifies precision PREC as a
            %   string.  If omitted, PREC = 'uint8'.
            %
            %   readRegister(obj,REG,CNT) returns a row vector of CNT
            %   values read successively from the register.  Specifying CNT
            %   > 1 enables efficient register reading for devices that
            %   automatically increment the register address after each
            %   read operation. By default, CNT = 1.
            %
            %   readRegister(obj,REG,PREC,CNT) specifies both precision and
            %   count.
            if nargin > 2
                if ischar(arg3)
                    prec = validatestring(arg3, ...
                        obj.AvailablePrecisions,'','precision');
                    if nargin > 3
                        cnt = arg4;
                    else
                        cnt = 1;
                    end
                else
                    narginchk(3,3); % this syntax doesn't support 4 args
                    cnt = arg3;
                    prec = 'uint8';
                end
            else
                prec = 'uint8';
                cnt = 1;
            end
            
            % Get uint8 data from register
            sendRequest(obj.Hw, ...
                obj.REQUEST_I2C_READ_REGISTER, ...
                obj.BusNumber, ...
                obj.AddrDec, ...
                uint8(reg), ...
                uint32(cnt * sizeof(prec)));
            bytes = recvResponse(obj.Hw);
            data = typecast(bytes,prec);
            
            %             switch prec
            %                 case 'uint8'
            %                     data = bytes;
            %                 case 'int8'
            %                     data = typecast(bytes,prec);
            %                 otherwise
            %                     % Swap bytes if wordsize is greater than 8-bits
            %                     data = typecast(flip(bytes),prec);
            %             end
        end
    end
    
    methods
        function value = get.DeviceID(obj)
            value = double(obj.AddrDec) + ...
                double(obj.BusNumber) * (1 + obj.MAX_I2C_ADDRESS);
        end
        
        function set.Bus(obj, value)
            validateattributes(value, {'char'}, ...
                {'row','nonempty'},'','Bus');
            obj.Bus = value;
        end
        
        function set.BusNumber(obj, value)
            % Bus number must be a scalar uint32
            validateattributes(value, {'uint32'}, ...
                {'scalar'},'','BusNumber');
            obj.BusNumber = value;
        end
    end
    
    methods (Access = private)
        function init(obj)
            sendRequest(obj.Hw, ...
                obj.REQUEST_I2C_INIT, ...
                obj.BusNumber);
            recvResponse(obj.Hw);
        end
        
        function terminate(obj)
            sendRequest(obj.Hw, ...
                obj.REQUEST_I2C_TERMINATE, ...
                obj.BusNumber);
            recvResponse(obj.Hw);
        end
        
        function delete(obj)
            try
                if obj.Initialized
                    markUnused(obj,obj.DeviceID);
                    terminate(obj);
                end
            catch
                % do not throw errors/warnings on destruction
            end
        end
        
        function S = saveobj(~)
            S = [];
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:SaveNotSupported', 'i2cdev'));
        end
        
        function ret = isUsed(obj,deviceID)
            addr = obj.Hw.DeviceAddress;
            ret = isKey(obj.Map, addr) && ...
                ismember(deviceID, obj.Map(addr));
        end
        
        function markUsed(obj,deviceID)
            addr = obj.Hw.DeviceAddress;
            if isKey(obj.Map, addr)
                obj.Map(addr) = union(obj.Map(addr), deviceID);
            else
                obj.Map(addr) = deviceID;
            end
        end
        
        function markUnused(obj,deviceID)
            addr = obj.Hw.DeviceAddress;
            if isKey(obj.Map, addr)
                obj.Map(addr) = setdiff(obj.Map(addr), deviceID);
            end
        end
    end
    
    methods (Hidden, Static)
        function out = loadobj(~)
            out = raspi.internal.i2cdev.empty();
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:LoadNotSupported', ...
                'i2cdev', 'i2cdev'));
        end
        
        function decvalue = hex2dec(hexvalue)
            % Remove '0x' if present, then convert to decimal
            decvalue = hex2dec(regexprep(hexvalue,'0x',''));
        end
        
        function hexvalue = dec2hex(decvalue)
            hexvalue = sprintf('0x%02s', dec2hex(decvalue));
        end
    end
end

function [addrNum,addrStr] = convertAddress(addr)
% Convert address to decimal numeric and hexadecimal string formats.
%
% Accept hexadecimal strings with and without '0x' string prefix, or
% decimal values.
%
% Returns hexadecimal string with '0x' prefix.

if isnumeric(addr)
    validateattributes(addr, {'numeric'}, ...
        {'scalar','nonnegative'},'','Address');
    addrNum = addr;
else
    validateattributes(addr, {'char'}, ...
        {'nonempty'},'','Address');
    addrNum = hex2dec(regexprep(addr,'0x',''));
end
% I2C address format is two hexadecimal numbers in the form 0x0E (letters
% are upper case)
addrStr = sprintf('0x%02s',dec2hex(addrNum));
end

%--------------------------------------------------------------------------
function ret = sizeof(prec)
switch prec
    case {'int8','uint8'}
        ret = 1;
    case {'int16','uint16'}
        ret = 2;
    case {'int32','uint32','single'}
        ret = 4;
    case {'int64','uint64','double'}
        ret = 8;
end
end
%[EOF]
