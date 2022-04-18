classdef ConnectHardware < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % ConnectHardware - Screen implementation to enable users to connect
    % the Raspberry Pi board to the host
    
    %   Copyright 2016-2017 The MathWorks, Inc.
    
    properties
        DetectBoardTimeOut = 180;
        DetectNICTimeout = 30;
    end
    
    properties(Access = private)
        BusySpinner
    end
    
    methods
        function obj = ConnectHardware(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:});
            
            % Set the Title Text
            obj.Title.Text = message('raspi:hwsetup:ConnectHardwareTitle').getString;
            
            instruction1 = message('raspi:hwsetup:ConnectHardware_Instruction1').getString;
            
            if ismac
                instruction1 = message('raspi:hwsetup:ConnectHardware_Instruction1_MAC').getString;
            end
            % Set the Instructions
            if strcmp(obj.Workflow.BoardName, message('raspi:hwsetup:RaspberryPiZeroW').getString)
                obj.ConfigurationInstructions.Text = ...
                    [message('raspi:hwsetup:ConnectHardwareDescription').getString newline ...
                    instruction1 newline...
                    message('raspi:hwsetup:ConnectHardware_Instruction2PiZeroW').getString];
                
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectHardware_WhatToConsiderPiZeroW').getString;
                obj.HelpText.Additional = '';
                % Set position for image widget
                obj.ConfigurationImage.Position = [20 5 360 220];% image has offset so, setting top as 5 pixel
            else
                obj.ConfigurationInstructions.Text = ...
                    [message('raspi:hwsetup:ConnectHardwareDescription').getString newline ...
                    instruction1 newline...
                    obj.getNetworkConfigConnectionInstructions(obj.Workflow.BoardName,obj.Workflow.NetworkConfiguration) newline...
                    message('raspi:hwsetup:ConnectHardware_Instruction3').getString];
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectHardware_WhatToConsider', ...
                    obj.getActivityLED(obj.Workflow.BoardName)).getString;
                obj.HelpText.Additional = message('raspi:hwsetup:ConnectHardware_AdditionalInfo').getString;
                
                % Set position for image widget
                obj.ConfigurationImage.Position = [20 5 360 240];% image has offset so, setting top as 5 pixel
            end

            % Set the ImageFile
            obj.ConfigurationImage.ImageFile = fullfile(obj.Workflow.ResourcesDir,...
                'connecthardware', obj.getConnectionDiagram(obj.Workflow.BoardName,obj.Workflow.NetworkConfiguration));
            
            if isunix
                if ~ismac
                    obj.ConfigurationInstructions.addWidth(15);
                end
            end
            obj.HelpText.AboutSelection = '';
        end
        
        function reinit(obj)
            obj.BusySpinner.Visible = 'off';
            % Update the Instructions if board or network configuration changes
            instruction1 = message('raspi:hwsetup:ConnectHardware_Instruction1').getString;
            if ismac
                instruction1 = message('raspi:hwsetup:ConnectHardware_Instruction1_MAC').getString;
            end
            
            if strcmp(obj.Workflow.BoardName, message('raspi:hwsetup:RaspberryPiZeroW').getString)
                obj.ConfigurationInstructions.Text = ...
                    [message('raspi:hwsetup:ConnectHardwareDescription').getString newline ...
                    instruction1 newline...
                    message('raspi:hwsetup:ConnectHardware_Instruction2PiZeroW').getString];
                
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectHardware_WhatToConsiderPiZeroW').getString;
                obj.HelpText.Additional = '';
                % Set position for image widget
                obj.ConfigurationImage.Position = [20 5 360 220];% image has offset so, setting top as 5 pixel
            else
                obj.ConfigurationInstructions.Text = ...
                    [message('raspi:hwsetup:ConnectHardwareDescription').getString newline ...
                    instruction1 newline...
                    obj.getNetworkConfigConnectionInstructions(obj.Workflow.BoardName,obj.Workflow.NetworkConfiguration) newline...
                    message('raspi:hwsetup:ConnectHardware_Instruction3').getString];
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectHardware_WhatToConsider', ...
                    obj.getActivityLED(obj.Workflow.BoardName)).getString;
                obj.HelpText.Additional = message('raspi:hwsetup:ConnectHardware_AdditionalInfo').getString;
                
                % Set position for image widget
                obj.ConfigurationImage.Position = [20 5 360 240];% image has offset so, setting top as 5 pixel
            end
            
            % Update the ImageFile
            obj.ConfigurationImage.ImageFile = fullfile(obj.Workflow.ResourcesDir,...
                'connecthardware', obj.getConnectionDiagram(obj.Workflow.BoardName,obj.Workflow.NetworkConfiguration));
            
        end
        
        function out = getPreviousScreenID(obj) %#ok<*MANU>
            out = 'raspi.internal.hwsetup.WriteFirmware';
        end
        
        function out = getNextScreenID(obj)
            obj.disableScreen({'CancelButton'});
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Text = '';
            obj.BusySpinner.show()
            rPiFound = obj.configureNetwork();
            if strcmp(obj.Workflow.BoardName,message('raspi:hwsetup:RaspberryPiZeroW').getString) && rPiFound
                out = 'raspi.internal.hwsetup.ScanAndConnect';
            else
                out = 'raspi.internal.hwsetup.ConfirmConfiguration';
            end
            
            enableScreen = onCleanup(@()obj.enableScreen);
        end
        
        function rPiFound = configureNetwork(obj)
            % configureNetwork - Method to find the Raspberry Pi board on
            % the network
            obj.BusySpinner.Text = [message('raspi:setup:ConfiguringNetwork').getString num2str(obj.DetectBoardTimeOut) ' seconds'];
            
            % Find Board - Attempt to find the Raspberry Pi Board.
            tstart = tic;
            rPiFound = false;
            
            while toc(tstart) < obj.DetectBoardTimeOut
                % During boot, Raspberry Pi sends a UDP message (port = 18725)
                % to all NIC's on the host computer. findBoard() function
                % looks for the UDP messages from the R-Pi.
                try
                    obj.BusySpinner.Text = [message('raspi:hwsetup:ConnectHardwareFindBoard').getString [num2str(fix(obj.DetectBoardTimeOut - toc(tstart))) ' seconds']];
                catch
                    error(message('raspi:hwsetup:ConnectHardwareTerminated'));
                end
                rPiFound = obj.Workflow.HardwareInterface.findBoard(obj.Workflow.BoardName);
                if rPiFound
                    break;
                end
            end
            
            % If the board is not found and platform is Windows or MAC and
            % the selected Network Configuration is Direct Connection to
            % Host computer try to find the Pi using NICs
            if ~rPiFound
                if ispc || ismac
                    if isequal(...
                            obj.Workflow.NetworkConfiguration,...
                            message('raspi:hwsetup:SelectNetworkDirectConnection').getString)
                        % Get all NICs
                        nics = obj.Workflow.HardwareInterface.getNics();
                        if ~isempty(nics)
                            tstart = tic;
                            rPiNic = [];
                            obj.BusySpinner.Text =  message('raspi:setup:IdentifyingNic').getString;
                            
                            % Detect NIC connected to Raspberry Pi
                            while isempty(rPiNic) && toc(tstart) < obj.DetectNICTimeout
                                % Loop for 30s
                                if isprop(obj.Workflow.HardwareInterface, 'NICDetectAttempt')
                                    % This is for testing purpose only.
                                    obj.Workflow.HardwareInterface.NICDetectAttempt = 1;
                                end
                                try
                                    obj.BusySpinner.Text = [message('raspi:setup:IdentifyingNic').getString [num2str(fix(obj.DetectNICTimeout - toc(tstart))) ' seconds']];
                                catch
                                    error(message('raspi:hwsetup:ConnectHardwareTerminated'));
                                end
                                rPiNic = obj.Workflow.HardwareInterface.detectNics(nics);
                            end
                            
                            % If an NIC connected is not detected, let the
                            % user choose an NIC from the ones available.
                            % If only a single NIC is available that is
                            % selected by default.
                            if isempty(rPiNic)
                                rPiNic = obj.Workflow.HardwareInterface.chooseNic(nics);
                                % Attempt to detect the selcted NIC
                                tstart = tic;
                                retNic = [];
                                if isprop(obj.Workflow.HardwareInterface, 'NICDetectAttempt')
                                    % This is for testing purpose only.
                                    obj.Workflow.HardwareInterface.NICDetectAttempt = 2;
                                end
                                
                                % Configure NIC for DHCP and perform ping
                                obj.Workflow.HardwareInterface.configureNicForDhcp(rPiNic);
                                obj.BusySpinner.Text = message('raspi:setup:IdentifyingNic').getString;
                                while isempty(retNic) && toc(tstart) < obj.DetectNICTimeout
                                    % Loop for 30s
                                    try
                                        obj.BusySpinner.Text = message('raspi:setup:IdentifyingNic').getString;
                                    catch
                                        error(message('raspi:hwsetup:ConnectHardwareTerminated'));
                                    end
                                    
                                    retNic = obj.Workflow.HardwareInterface.detectNics(rPiNic);
                                end
                                if isempty(retNic)
                                    if ~obj.Workflow.HardwareInterface.loc_isConnected(rPiNic)
                                        % NIC is Disconnected
                                        error(message('raspi:setup:NicDisconnected', rPiNic.name));
                                    else
                                        % NIC not detected
                                        error(message('raspi:setup:NicNotDetected', rPiNic.name));
                                    end
                                end
                            end
                            % For Windows only - add static route
                            obj.Workflow.HardwareInterface.addStaticRoute(rPiNic);
                        else
                            % No NIC found
                            h = warndlg(getString(message('raspi:setup:NoNic')));
                        end
                    else
                        % Unable to detect a Raspberry Pi
                        h = warndlg(getString(message('raspi:setup:CouldNotDetectRpi')));
                    end
                end
                
            else
                hb = raspi.internal.BoardParameters('Raspberry Pi');
                obj.BusySpinner.Text = message('raspi:hwsetup:ConnectHardwareBoardDetected', hb.getParam('hostname')).getString;
                pause(3);
            end
            % Check that there is an entry in the ssh known host file for the
            % detected Raspberry Pi. If the entry is there, delete it.
            status = obj.Workflow.HardwareInterface.checkSSHentry(obj.Workflow.IPAddress);
            if status ~= 0
                h = warndlg(getString(message('raspi:setup:RaspberryPiConnectHardware_SSHWarning')));
            end
        end
    end
    
    methods(Static)
        function out = getNetworkConfigConnectionInstructions(board,nwconfig)
            % getNetworkConfigConnectionInstructions - Returns the Network
            % configuration specific connection instructions
            
            switch(nwconfig)
                case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem2').getString
                    if strcmp(board,'Raspberry Pi 3 Model B') || strcmp(board,'Raspberry Pi 3 Model B+')
                        out =  message('raspi:hwsetup:ConnectHardware_Instruction2_Wireless').getString;
                    else
                        out =  message('raspi:hwsetup:ConnectHardware_Instruction2_Wireless2').getString;
                    end
                case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem3').getString
                    % Direct connection
                    out =  message('raspi:hwsetup:ConnectHardware_Instruction2_Direct').getString;
                case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem4').getString
                    % Manual connection
                    out =  message('raspi:hwsetup:ConnectHardware_Instruction2_Manual').getString;
                otherwise
                    % Default is LAN
                    out =  message('raspi:hwsetup:ConnectHardware_Instruction2_LAN').getString;
            end
        end
        
        function out = getActivityLED(board)
            % getActivityLED - Returns the name of the activity LED based
            % on the Board selected
            
            switch board
                case 'Raspberry Pi Model B'
                    out = '''OK/ACT''';
                otherwise
                    out = '''ACT''';
            end
        end
        
        function out = getConnectionDiagram(board,nwConfiguration)
            % getConnectionDiagram - Returns the name of the Image File
            % based on the selected board.
            if strcmp(nwConfiguration,message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem2').getString)
                % if connection is wireless
                switch board
                    case {'Raspberry Pi 3 Model B','Raspberry Pi 3 Model B+'}
                        out = 'raspberrypi3_modelb+_connections_wlan.png';
                    case 'Raspberry Pi Model B'
                        out = 'raspberrypi_modelb_connections_wlan.png';
                    otherwise
                        out = 'raspberrypi_modelb+_connections_wlan.png';
                end
            else
                % else if wired connection:
                switch board
                    case 'Raspberry Pi Model B'
                        out ='raspberrypi_modelb_connections.png';
                    case 'Raspberry Pi Zero W'
                        out = 'raspberrypi_zerow_connections.png';
                    otherwise
                        out = 'raspberrypi_modelb+_connections.png';
                end
            end

        end
        
    end
end