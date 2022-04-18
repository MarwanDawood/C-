classdef servo < raspi.internal.ServoBase & matlab.mixin.CustomDisplay
   %   Attach a servo motor to specified pin on Raspberry Pi board.
    %
    %   Syntax:
    %   s = servo(r,pin)
    %   s = servo(r,pin,Name,Value)
    %
    %   Description:
    %   s = servo(r,pin)            Creates a servo motor object connected to the specified pin on the Raspberry Pi board.
    %   s = servo(r,pin,Name,Value) Creates a servo motor object with additional options specified by one or more Name-Value pair arguments.
    %
    %   Example:
    %       r = raspi();
    %       s = servo(r,18);
    %
    %   Example:
    %       r = raspi();
    %       s = servo(r,18,'MinPulseDuration',1e-3,'MaxPulseDuration',2e-3);
    %
    %   Input Arguments:
    %   r   - raspi 
    %   pin - Digital pin number
    %
    %   Name-Value Pair Input Arguments:
    %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value.
    %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
    %
    %   NV Pair:
    %   'MinPulseDuration' - The pulse duration for the servo at its minimum position (numeric,
    %                     default 1.00e-3 seconds.
    %   'MaxPulseDuration' - The pulse duration for the servo at its maximum position (numeric,
    %                     default 2.0e-3 seconds.
    %
    
    % Copyright 2015-2018 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Pin
    end
    
    properties (Access = private)
        Map = containers.Map
    end
    
    methods
        function obj = servo(hw,pin,varargin)
            if ~isa(hw,'raspi.internal.raspiBase')
                error(message('raspi:utils:UnexpectedHwObject'));
            end
            obj.Hw = hw;
            i_checkPin(obj.Hw,pin);
            obj.Pin = pin;
            obj.PinNumber = obj.Pin;
            
            % Parse NV pairs
            try
                p = inputParser;
                addParameter(p,'MinPulseDuration',1e-3);
                addParameter(p,'MaxPulseDuration',2e-3);
                parse(p,varargin{:});
            catch
                error(message('raspi:utils:InvalidNVPropertyName',...
                    'servo','''MinPulseDuration'', ''MaxPulseDuration'''));
            end
            obj.MinPulseDuration = p.Results.MinPulseDuration;
            obj.MaxPulseDuration = p.Results.MaxPulseDuration;

            % Check if pin is being used
            if isUsed(obj,obj.Pin)
                error(message('raspi:utils:ServoInUse',obj.Pin));
            end
            
            % Initialize servo
            initServo(obj);
            markUsed(obj,obj.Pin);
        end
    end
    
    methods (Access = private)
        function delete(obj)
            try
                if obj.Initialized
                    markUnused(obj,obj.Pin);
                    terminateServo(obj);
                end
            catch 
                % do not throw errors/warnings on destruction
            end
        end
        
        function S = saveobj(~)
            S = [];
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:SaveNotSupported','servo'));
        end
        
        function ret = isUsed(obj,pin)
            addr = obj.Hw.DeviceAddress;
            ret = isKey(obj.Map, addr) && ...
                ismember(pin, obj.Map(addr));
        end
        
        function markUsed(obj,pin)
            addr = obj.Hw.DeviceAddress;
            if isKey(obj.Map, addr)
                obj.Map(addr) = union(obj.Map(addr), pin);
            else
                obj.Map(addr) = pin;
            end
        end
        
        function markUnused(obj,pin)
            addr = obj.Hw.DeviceAddress;
            if isKey(obj.Map, addr)
                obj.Map(addr) = setdiff(obj.Map(addr), pin);
            end
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            % Display main options
            fprintf('                 Pin: %d\n',obj.Pin);
            fprintf('    MinPulseDuration: %.2e (s)\n',obj.MinPulseDuration);
            fprintf('    MaxPulseDuration: %.2e (s)\n',obj.MaxPulseDuration);  
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
            out = raspi.internal.servo.empty();
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:LoadNotSupported', ...
                'servo','servo'));
        end
    end
end

%% Internal functions
function i_checkPin(hw,pin)
validateattributes(pin, {'numeric'}, {'scalar','integer'},'', 'pin');
if ~any(hw.AvailableDigitalPins == pin)
    error(message('raspi:utils:UnexpectedDigitalPinNumber'));
end
end

