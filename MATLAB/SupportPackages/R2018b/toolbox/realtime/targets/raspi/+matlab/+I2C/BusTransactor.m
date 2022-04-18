classdef BusTransactor < matlab.interface.BusTransactionInterface
    %BUSTRANSACTOR
    %
    
    %#codegen
    properties (SetAccess = private)
        BusNumList
        Hw
    end
    
    properties
        Bus = 1
        Address = 0
    end
    
    properties (Constant, Access = private)
        % I2C requests
        REQUEST_I2C_INIT           = 3001
        REQUEST_I2C_READ           = 3002
        REQUEST_I2C_WRITE          = 3003
        REQUEST_I2C_TERMINATE      = 3004
        REQUEST_I2C_READ_REGISTER  = 3005
        REQUEST_I2C_WRITE_REGISTER = 3006
        MARKER = 10000
        
        AvailablePrecisions = {'int8','uint8','int16','uint16',...
            'int32','uint32','int64','uint64','single','double'}
    end
    
    methods
        function obj = BusTransactor(hw)
            %BusTransactor Constructor
            if isempty(find(ismember(superclasses(hw),'matlab.I2C.Master'),1))
                error('a:b','Hardware object must be an I2C Master');
            end
            obj.Hw = hw;
            obj.BusNumList = obj.MARKER * ones(1,8,'uint32');
        end
    end
    
    methods(Access = private, Static)
        function name = matlabCodegenRedirect(~)
            name = 'matlab.I2C.codegen.BusTransactor';
        end
    end
    
    methods (Access = public)
        function openCommChannel(obj)
            %openBus Open an I2C bus for reading / writing
            if isBusOpened(obj,obj.Bus)
                return;
            end
            sendRequest(obj.Hw,obj.REQUEST_I2C_INIT,uint32(obj.Bus));
            recvResponse(obj.Hw);
            addToBusList(obj,uint32(obj.Bus));
        end
        
        function closeCommChannel(obj)
            if ~isBusOpened(obj,uint32(obj.Bus))
                return;
            end
            sendRequest(obj.Hw,obj.REQUEST_I2C_TERMINATE,uint32(obj.Bus));
            recvResponse(obj.Hw);
            removeFromBusList(obj,obj.Bus)
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
                uint32(obj.Bus), ...
                uint8(obj.Address), ...
                uint32(numel(data) * (prec)), ...
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
                uint32(obj.Bus), ...
                uint8(obj.Address), ...
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
                uint32(obj.Bus), ...
                uint8(obj.Address), ...
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
                uint32(obj.Bus), ...
                uint8(obj.Address), ...
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
    
    methods (Access = protected)
        function ret = isBusOpened(obj,busNum)
            busNum_uint32 = uint32(busNum);
            if ismember(busNum_uint32,obj.BusNumList)
                ret = true;
            else
                ret = false;
            end
        end
        
        function addToBusList(obj,busNum)
            % Assumes I2C address
            for k = 1:numel(obj.BusNumList)
                if obj.BusNumList(k) == obj.MARKER
                    break;
                end
            end
            obj.BusNumList(k) = busNum;
        end
        
        function removeFromBusList(obj,busNum)
            for k = 1:numel(obj.BusNumList)
                if obj.BusNumList(k) == busNum
                    break;
                end
            end
            obj.BusNumList(k) = obj.MARKER;
        end
    end
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
