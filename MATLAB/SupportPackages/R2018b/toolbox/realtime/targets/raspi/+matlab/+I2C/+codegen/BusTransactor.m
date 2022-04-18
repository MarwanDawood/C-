classdef BusTransactor < matlab.interface.BusTransactionInterface
    %BUSTRANSACTOR 
    %   
    
    % Copyright 2015 The MathWorks, Inc.
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
        MARKER = 10000
    end
    
    methods
        function obj = BusTransactor(hw)
            %BusTransactor Constructor
            obj.Hw = hw;
            obj.BusNumList = obj.MARKER * ones(1,8,'uint32');
        end
    end
    
    methods (Access = public)
        function openCommChannel(obj)
            coder.cinclude('I2C.h');
            %openBus Open an I2C bus for reading / writing
            if isBusOpened(obj,obj.Bus)
                return;
            end
            % int EXT_I2C_init(const unsigned int bus)
            y = int32(0);
            y = coder.ceval('EXT_I2C_init',uint32(obj.Bus));
            if y == 0
                %addToBusList(obj,uint32(obj.Bus));
            else
                fprintf('Error opening I2C device.\n');
            end
        end
        
        function closeCommChannel(obj)
            if ~isBusOpened(obj,uint32(obj.Bus))
                return;
            end
            % Close I2C device
            % extern int EXT_I2C_terminate(const unsigned int bus);
            coder.ceval('EXT_I2C_terminate',uint32(obj.Bus));
        end
        
        function data = read(obj,cnt,prec)
            %read Read a value from I2C device.
            if nargin < 3
                prec = 'uint8';
            end
            data = zeros(1,count,prec);
            % extern int EXT_I2C_read(const unsigned int bus,
            %    const uint8_T address, void *data, const int count);
            y = int32(0);
            y = coder.ceval('EXT_I2C_read',uint32(obj.Bus),...
                uint8(obj.Address),coder.wref(data),int32(cnt));
            if y ~= 0
                fprintf('Error: EXT_I2C_read\n');
            end
        end
        
        function write(obj,data,prec)
            %write Write data to I2C device.
            if nargin < 3
                prec = 'uint8';
            end
            data = cast(data,prec);
            %int EXT_I2C_write(const unsigned int bus, const uint8_T address,
            %    const void *data, const int count);
            y = int32(0);
            y = coder.ceval('EXT_I2C_write',uint32(obj.Bus),uint8(obj.Address),...
                coder.rref(data),int32(count));
            if y ~= 0
                fprintf('Error: EXT_I2C_write.\n');
            end
        end
        
        function data = readRegister(obj,reg,cnt,prec)
            %readRegister Read value from register.
            if nargin < 4
                prec = 'uint8';
            end
            if nargin < 3
                cnt = 1;
            end
            
            data = zeros(1,cnt,prec);
            %extern int EXT_I2C_readRegister(const unsigned int bus, const uint8_T address,
            %    const uint8_T register, void *data, const int count);
            y = int32(0);
            nbytes = int32(cnt * sizeof(prec));
            y = coder.ceval('EXT_I2C_readRegister',uint32(obj.Bus),...
                obj.Address,uint8(reg),coder.wref(data),nbytes);
            if y ~= 0
                fprintf('Error: EXT_I2C_readRegister\n');
            end
        end
        
        function writeRegister(obj,reg,data,prec)
            %writeRegister Write value to register.
            if nargin < 4
                prec = 'uint8';
            end
            regVal = cast(data,prec);
            %extern int EXT_I2C_writeRegister(const unsigned int bus, const uint8_T address,
            %    const uint8_T reg, const void *data, const int count);
            y = int32(0);
            nbytes = int32(numel(regVal));
            y = coder.ceval('EXT_I2C_writeRegister',uint32(obj.Bus),...
                obj.Address,uint8(reg),coder.rref(regVal),nbytes);
            if y ~= 0
                fprintf('Error: EXT_I2C_writeRegister.\n');
            end
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
                if obj.BusNumList(k) == obj.MARKER;
                    break;
                end
            end
            obj.BusNumList(k) = busNum;
        end
        
        function removeFromBusList(obj,busNum)
            for k = 1:numel(obj.BusNumList)
                if obj.BusNumList(k) == busNum;
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
