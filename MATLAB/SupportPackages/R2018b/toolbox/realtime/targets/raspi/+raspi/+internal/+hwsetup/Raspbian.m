classdef Raspbian <  matlabshared.internal.LinuxSystemInterface
    % Raspbian - Class which provides information about Raspbian OS
    % required for customization

    % Copyright 2017-2018 The MathWorks, Inc.
    properties (Dependent, GetAccess = public)
        DeviceAddress
    end
    
    properties (SetAccess = private, GetAccess = public)
        Port = 22
    end
    
    properties (Hidden)
        Ssh
        BuildDir
    end
    
    properties
        requiredPackages = {'libsdl1.2-dev';'alsa-utils';'espeak';...
            'i2c-tools';'libi2c-dev';'ssmtp';'ntpdate';'git-core';'v4l-utils';'cmake';'sense-hat';...
            'sox';'libsox-fmt-all';'libsox-dev';'libcurl4-openssl-dev';'libssl-dev'};
        requiredLibraries = {'userland';'wiringpi';'pigpio';'mqtt-paho'};
    end
    
    methods(Hidden)
        function obj = Raspbian(hostname, username, password, port)
            % Create a connection to Raspberry Pi hardware.
            narginchk(0, 4);
            if nargin > 3
                % In case SSH port is not 22
                obj.Port = port;
            end
            if nargin >=3
                % Create an SSH client
                if ~isequal(hostname,'localhost') && ...
                        ~isequal(hostname,'127.0.0.1')
                    obj.Ssh = matlabshared.internal.ssh2client(hostname, ...
                        username, password, obj.Port);
                end
            end
        end
    end
    
    methods
        function pkgs = getRequiredPackages(obj,varargin)
            pkgs = obj.requiredPackages;
        end
        function libs = getRequiredLibraries(obj,varargin)
            libs = obj.requiredLibraries;
        end
        
        function set.requiredPackages(obj,pkg)
            if iscell(pkg)
                if ~iscellstr(pkg)
                    error('shared_linuxservice:utils:InvalidPkgList',...
                        'Input must be a string or a cell array of strings representing Linux package names.');
                end
            else
                validateattributes(pkg,{'char'},{'nonempty','row'},...
                    'install','requiredPackages');
                pkg = {pkg};
            end
            obj.requiredPackages = [obj.requiredPackages;pkg];
        end
        
        function set.requiredLibraries(obj,lib)
            if iscell(lib)
                if ~iscellstr(lib)
                    error('shared_linuxservice:utils:InvalidPkgList',...
                        'Input must be a string or a cell array of strings representing Linux library names.');
                end
            else
                validateattributes(lib,{'char'},{'nonempty','row'},...
                    'install','requiredLibraries');
                lib = {lib};
            end
            obj.requiredLibraries = [obj.requiredLibraries;lib];
        end
        
    end
end