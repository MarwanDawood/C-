classdef raspiDesktop < raspi.internal.raspiBase
    %RASPIDESKTOP Access Raspberry Pi hardware peripherals in desktop MATLAB
    %
    % obj = RASPI(DEVICEADDRESS, USERNAME, PASSWORD) creates a RASPI object
    % connected to the Raspberry Pi hardware at DEVICEADDRESS with login
    % credentials USERNAME and PASSWORD. The DEVICEADDRESS can be an
    % IP address such as '192.168.0.10' or a hostname such as
    % 'raspberrypi-MJONES.foo.com'.
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess = private)
        DeviceAddress
        Port
    end
    
    properties (Access = private)
        Timeout
    end
    
    properties (Access = private)
        Initialized = false
    end
    
    methods (Hidden)
        function obj = raspiDesktop(varargin)
            % Create a connection to Raspberry Pi hardware.
            narginchk(0,4);
            
            hb = raspi.internal.BoardParameters('Raspberry Pi');
            if nargin < 1
                hostname = hb.getParam('hostname');
                if isempty(hostname)
                    error(message('raspi:utils:InvalidDeviceAddress'));
                end
            else
                hostname = varargin{1};
                if isstring(hostname)
                    hostname = char(hostname);
                end
            end
            if nargin < 2
                username = hb.getParam('username');
                if isempty(username)
                    error(message('raspi:utils:InvalidUsername'));
                end
            else
                username = varargin{2};
                if isstring(username)
                    username = char(username);
                end
            end
            if nargin < 3
                password = hb.getParam('password');
                if isempty(password)
                    error(message('raspi:utils:InvalidPassword'));
                end
            else
                password = varargin{3};
                if isstring(password)
                    password = char(password);
                end
            end
            if nargin < 4
                port = raspi.internal.getServerPort;
            else
                port = varargin{4};
            end
            
            % Validate and store device address
            try
                ipNode = matlabshared.internal.ipnode(hostname, port);
                credentials = matlabshared.internal.credentials(username, password);
            catch ME
                throwAsCaller(ME);
            end
             
            % Create an SSH client
            if ~isequal(hostname,'localhost')
                try
                    ssh = matlabshared.internal.ssh2client(ipNode.Hostname, credentials.Username, credentials.Password);
                catch
                    error(message('raspi:utils:InvalidCredential',ipNode.Hostname));
                end
                %Check if the required version of the server is available.
                %If yes, kill any server running and launch the required server
                %If no, update the server and launch the server
                raspi.internal.launchServer(ipNode.Hostname,credentials.Username,credentials.Password);
            else
                ssh = ''; % ssh not used by localhost
            end
            
            % Create NNReq client
            % Set timeout as 10.5s to avoid race around with serial timeout.
            timeout = 10500;
            nnreq=matlabshared.internal.NNReqClient(['tcp://' ipNode.Hostname ':' char(string(ipNode.Port))],timeout);
            
            obj = obj@raspi.internal.raspiBase(ipNode.Hostname, ssh, nnreq);
            
            obj.DeviceAddress = ipNode.Hostname;
            obj.Port = ipNode.Port;
            obj.Timeout = timeout;
            % Store board parameters for a future session
            hb.setParam('hostname', obj.DeviceAddress);
            hb.setParam('username', credentials.Username);
            hb.setParam('password', credentials.Password);
        end
    end
    
    methods(Hidden)        
        function delete(obj)
            delete@raspi.internal.raspiBase(obj);
        end
        
        function displayObject(obj)
            % Display main options
            fprintf('         DeviceAddress: %-30s\n',['''',obj.DeviceAddress,'''']);
            fprintf('                  Port: %-30d\n',obj.Port);
            displayObject@raspi.internal.raspiBase(obj);
        end
    end
    
    methods (Static, Hidden)
        function obj = loadobj(saveInfo)
            try
                obj = raspi.internal.raspiDesktop(saveInfo.Address);
            catch EX
                warning(EX.identifier, '%s;', EX.message);
                obj = raspi.empty;
            end
        end
    end
end
