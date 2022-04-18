classdef hardware < matlabshared.internal.LinuxSystemInterface & ...
        matlab.mixin.CustomDisplay 
    %HARDWARE Access Linux hardware.
    
    % Copyright 2016 The MathWorks, Inc.
    
    properties (Dependent, GetAccess = public)
        DeviceAddress
    end
    
    properties (SetAccess = private, GetAccess = public)
        Port = 22
    end
    
    properties (Hidden)
        Ssh
    end
    
    properties (Hidden, Constant)
        % Constant used for storing board parameters
        BoardPref = 'Raspberry Pi';
    end
    
    
    methods (Hidden)
        function obj = hardware(hostname,username,password,port)
            % Create a connection to Raspberry Pi hardware.
            narginchk(0, 4);
            if nargin > 3
                % In case SSH port is not 22
                obj.Port = port;
            end
            
            % Create an SSH client
            if ~isequal(hostname,'localhost') && ...
                    ~isequal(hostname,'127.0.0.1')
                obj.Ssh = matlabshared.internal.ssh2client(hostname, ...
                    username, password, obj.Port);
            end
        end
    end
    
    methods
        % GET / SET methods
        function value = get.DeviceAddress(obj)
            value = obj.Ssh.Hostname;
        end
        
        function set.Port(obj,value)
            validateattributes(value,{'numeric'},...
                {'scalar','>=',1,'<=',2^16-1},'','Port');
            obj.Port = double(value);
        end
    end
    
    methods (Access = public)
        function openShell(obj)
            %OPENSHELL opens an interactive command shell to Raspberry Pi
            % hardware.
            openShell(obj.Ssh);
        end
    end
    
    methods (Access = public, Hidden)
        function saveInfo = saveobj(obj)
            saveInfo.DeviceAddress = obj.DeviceAddress; 
        end
    end
    
    methods (Static, Hidden)
        function obj = loadobj(saveInfo)
            try
                obj = raspberrypi(saveInfo.DeviceAddress);
            catch EX
                warning(EX.identifier, EX.message);
                obj = codertarget.raspberrypi.empty();
            end
        end
    end %methods (Static, Hidden)
end %classdef
