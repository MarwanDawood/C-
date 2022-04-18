classdef RaspberryPiWorkflow < matlab.hwmgr.internal.hwsetup.Workflow
    %  Copyright 2016-2018 The MathWorks, Inc.

    properties(Constant)
        % Properties inherited from Workflow class
        BaseCode = 'RASPPIIO';
    end
    
    properties
        % Properties inherited from Workflow class
        Name = 'Raspberry Pi';
        FirstScreenID
    end
    
    properties
        % ResourcesDir - Directory where image files and other resources
        % are located
        ResourcesDir
        % BoardName - Name of the board that user has which will be
        % configured to work with the support package
        BoardName
        % NetworkConfiguration - Mode of connection between the hardware
        % and host machine
        NetworkConfiguration
        % choice
        NetworkConfigChoice = 0;  % For Windows and Mac: 0 = LAN/WAN, 1 = Direct, 2 = manual; For Linux:0 = LAN/WAN, 1 = manual
        %Dhcp
        DhcpChoice     = 0;       % For manual config: 0 = DHCP, 1 = Static
        % HardwareInterface - Interface to the hardware callbacks
        HardwareInterface
        % IP Address - IP Address for the Raspberry Pi
        IPAddress = '169.254.0.2';
        % NetworkMask - NetworkMask for the Raspberry Pi
        NetworkMask    = '255.255.0.0';
        % Gateway - Gateway for the Raspberry Pi
        Gateway        = '169.254.0.1';
        % Configure wlan
        ConfigWLAN = 0;
        % SSID Name
        SSIDName = '';
        % Passphrase string
        Passphrase = '';
        % WiFiSecurity
        WiFiSecurity = '';
        % WLAN IP Address - IP Address for the Raspberry Pi WLAN interface
        WLANIPAddress = '192.168.1.2';
        % WLANNetworkMask - NetworkMask for the Raspberry Pi WLAN interface
        WLANNetworkMask    = '255.255.255.0';
        % WLANGateway - Gateway for the Raspberry Pi WLAN interface
        WLANGateway        = '192.168.1.1';
        % WLANStaticIP - wlan ip settings. 0 == Automatic, 1 == Static IP
        WLANStaticIP = 0;
        % WLANConnected
        WLANConnected = false;
        % WirelessScanInit for Pi Zero W
        WirelessScanInit = false;
        % USB Gadget IP Address - IP Address for the Raspberry Pi Zero W USB interface
        USBGadgetIPAddress = '169.254.0.4';
        % USBGadgetNetworkMask - NetworkMask for the Raspberry Pi Zero W USB interface
        USBGadgetNetworkMask    = '255.255.0.0';
        % USBGadgetGateway - Gateway for the Raspberry Pi Zero W USB interface
        USBGadgetGateway        = '169.254.0.1';
        % USBGadgetStaticIP - USB Gadget ip settings. 0 == Automatic, 1 == Static IP
        USBGadgetStaticIP = 0;
        % list of drives with sd card
        DriveList = {};
        % selected drive or default selected if numel(drivelist) = 1
        Drive = '';
        %IPAssignment
        IPAssignment = 1 % default Automatic - 1
        %HostName
        HostName = 'raspberrypi'
        %ShowExamples
        ShowExamples = true;
        %Host Name for Customization
        CustomDeviceHostName
        %IP address for customization
        CustomDeviceAddress
        %Username for Customization
        CustomDeviceUSRName
        %Password for Customization
        CustomDevicePsswd
    end
    
    methods
        function obj = RaspberryPiWorkflow(varargin)
            % RaspberryPiWorkflow - The Workflow class constructor creates
            % Workflow object for the Raspberry Pi Hardware Setup App.
            %
            % w = matlab.hwmgr.internal.hwsetup.register.RaspberryPiWorkflow() creates a
            % workflow object with a defaults
            %
            % logFile = [tempname '.txt'];
            % logger = matlab.hwmgr.internal.logger.Logger(logFile);
            % w = matlab.hwmgr.internal.hwsetup.Workflow('logger', logger);
            % creates a workflow object with a temporary log file.
            %
            % hwinterface = raspiTest.RaspiTestHWInterface;
            % matlab.hwmgr.internal.hwsetup.register.RaspberryPiWorkflow('hardwareInterface',
            % hwinterface); creates a workflow object with test hardware
            % interface class
            
            % Call base class
            obj@matlab.hwmgr.internal.hwsetup.Workflow(varargin{:})
            % Parse the hardwareInterface input parameter
            p = inputParser;
            addParameter(p, 'hardwareInterface', []);
            % Ignore parameters defined by the base class
            p.KeepUnmatched = true;
            p.parse(varargin{:});
            obj.HardwareInterface = p.Results.hardwareInterface;
            
            if isempty(obj.HardwareInterface)
                obj.HardwareInterface = raspi.internal.hwsetup.HardwareInterface.getInstance();
            end
            obj.Name = 'Raspberry Pi';
            obj.FirstScreenID = 'raspi.internal.hwsetup.SelectBoard';
            obj.ResourcesDir = fullfile(raspi.internal.getRaspiRoot, 'resources');
            
            % Set defaults where applicable
            obj.NetworkConfiguration = message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem1').getString;
            obj.BoardName = 'Raspberry Pi 3 Model B';
        end
    end
    
end