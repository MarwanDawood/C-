classdef joystick < handle
    % JOYSTICK Create a Joystick object.
    %
    % myjoystick = joystick(obj) creates a joystick object.
    
    % Copyright 2016-2018 The MathWorks, Inc. 
    properties (Constant)
        Name = 'Raspberry Pi Sense HAT Joystick';
    end
    
    properties(Hidden,Access = private)
        Map = containers.Map();
        Initialized = false;
        Opened = false;
        Hw
        evDevAddress
    end
    
    properties (Constant,Access = private)
        %JOYSTICK REQUESTS
        REQUEST_JOYSTICK_INIT = 7001;
        REQUEST_JOYSTICK_READ = 7002;
        AvailableButton = {'up','down','left','right','center'};
    end
    
    methods
        function obj = joystick(hw)
            validateattributes(hw,{'raspi.internal.raspiOnline','raspi.internal.raspiDesktop'},{'nonempty'},'','hardware')
            obj.Hw = hw;
            if isUsed(obj, obj.Name)
                error(message('raspi:utils:SenseHATInUse','joystick'));
            end
            joystickInit(obj);
            markUsed(obj,obj.Name);
            obj.Initialized = true;
        end
        
        %Joystick read
        function buttonpress = readJoystick(obj,varargin)
            % buttonpress = readJoystick(obj) reads the state of
            % the joystick. readJoystick returns a value between 0 and 5 
            % depending on the state of the joystick.
            % Possible states of the joystick are:
            % * 0 - joystick not pressed.
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
            sendRequest(obj.Hw,obj.REQUEST_JOYSTICK_READ,obj.evDevAddress);
            buttonpress = recvResponse(obj.Hw);
            if nargin > 1
                option = validatestring(varargin{1},obj.AvailableButton);
                switch option
                    case 'center'
                        buttonpress = (buttonpress == 1);
                    case 'left'
                        buttonpress = (buttonpress == 2);
                    case 'up'
                        buttonpress = (buttonpress == 3);
                    case 'right'
                        buttonpress = (buttonpress == 4);
                    case 'down'
                        buttonpress = (buttonpress == 5);
                end
            end
        end
    end
    
    methods (Access = protected)
        function joystickInit(obj)
            obj.Hw.sendRequest(obj.REQUEST_JOYSTICK_INIT);
            evDevName = char(recvResponse(obj.Hw));
            evDevName = strrep(evDevName,'/sys/class/input/','/dev/input/');
            evDevName = strrep(evDevName,'/device/name',char(0));
            obj.evDevAddress = evDevName;
        end

        function ret = isUsed(obj, name)
            if isKey(obj.Map, obj.Hw.DeviceAddress) && ...
                    ismember(name, obj.Map(obj.Hw.DeviceAddress))
                ret = true;
            else
                ret = false;
            end
        end
        
        function markUsed(obj, name)
            if isKey(obj.Map, obj.Hw.DeviceAddress)
                used = obj.Map(obj.Hw.DeviceAddress);
                obj.Map(obj.Hw.DeviceAddress) = union(used, name);
            else
                obj.Map(obj.Hw.DeviceAddress) = {name};
            end
        end
        
        function markUnused(obj, name)
            if isKey(obj.Map, obj.Hw.DeviceAddress)
                used = obj.Map(obj.Hw.DeviceAddress);
                obj.Map(obj.Hw.DeviceAddress) = setdiff(used, name);
            end
        end
    end
    
    methods
        function delete(obj)
            if obj.Initialized
                obj.markUnused(obj.Name)
            end
        end
    end
end
