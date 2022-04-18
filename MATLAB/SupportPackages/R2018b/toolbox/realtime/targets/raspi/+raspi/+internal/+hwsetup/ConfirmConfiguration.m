classdef ConfirmConfiguration < matlab.hwmgr.internal.hwsetup.VerifyHardwareSetup
    % ConfirmConfiguration - Screen implementation to confirm the
    % connection to Raspberry Pi board.
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    %
    properties(Access={?matlab.hwmgr.internal.hwsetup.VerifyHardwareSetup,...
            ?hwsetuptest.util.TemplateBaseTester})
        
        % Connect to wireless network CheckBox
        % ConnWirelessCheckBox
        % Got valid IP for raspi.
        RaspiAvailable
    end
    
    methods
        function obj = ConfirmConfiguration(workflow)
            % Call to class constructor
            obj@matlab.hwmgr.internal.hwsetup.VerifyHardwareSetup(workflow)
            
            % Set Title
            obj.Title.Text = message('raspi:hwsetup:ConfirmConfiguration_Title').getString;
            
            hb = raspi.internal.BoardParameters('Raspberry Pi');
            ipaddr = hb.getParam('hostname');
            % Check if ipaddr is empty or is valid
            if ~isempty(ipaddr)
                try
                    obj.Workflow.HardwareInterface.checkValidIp(ipaddr, 'IP address');
                catch
                    ipaddr = '';
                end
            else
                ipaddr = '';
            end
             
            hostname = hb.getParam('BoardName');
            username = hb.getParam('username');
            password = hb.getParam('password');
            
            % Set the DeviceInfoTable
            if strcmp(obj.Workflow.BoardName, message('raspi:hwsetup:RaspberryPiZeroW').getString)
                %Display USB & WLAN ip address
                obj.DeviceInfoTable.Labels = {message('raspi:hwsetup:ConfirmConfiguration_Label1ZeroW').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label2ZeroW').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label2').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label3').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label4').getString};
                if obj.Workflow.WLANConnected
                    wlanIPaddr = obj.Workflow.WLANIPAddress;
                else
                    wlanIPaddr = 'Not Connected';
                end
                obj.DeviceInfoTable.Values = {ipaddr,wlanIPaddr,hostname,username,password};
                obj.DeviceInfoTable.Position = [20 230 320 130];
            else
                obj.DeviceInfoTable.Labels = {message('raspi:hwsetup:ConfirmConfiguration_Label1').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label2').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label3').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label4').getString};
                obj.DeviceInfoTable.Values = {ipaddr,hostname,username,password};  
                obj.DeviceInfoTable.Position = [20 230 320 130];
            end
            
            obj.RaspiAvailable = ipaddr;
            
            % Set the Test Connection Button
            obj.TestConnButton.Text = message('raspi:hwsetup:ConfirmConfiguration_TestConnection').getString;
            obj.TestConnButton.ButtonPushedFcn = @obj.testConnection;
            obj.TestConnButton.Position = [20 200 120 22];
            
            % Set the StatusTable
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {message('raspi:hwsetup:ConfirmConfiguration_StatusTitle').getString};
            obj.StatusTable.Position = [20 150 430 30];
            obj.StatusTable.Enable = 'off';
            
            if isunix
                if ismac
                    % rearrange widgets for mac
                    obj.StatusTable.ColumnWidth = [20 405];
                    obj.DeviceInfoTable.ColumnWidth = 325;
                else
                    obj.TestConnButton.shiftVertically(-10);
                    obj.TestConnButton.addWidth(25);
                    obj.StatusTable.Position(2) = obj.StatusTable.Position(2) -10;
                end
            end
            % Set the HelpText
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConfirmConfiguration_WhatToConsider').getString;
            if strcmp(obj.Workflow.BoardName, message('raspi:hwsetup:RaspberryPiZeroW').getString)
                obj.HelpText.WhatToConsider = [obj.HelpText.WhatToConsider, ...
                   message('raspi:hwsetup:ConfirmConfiguration_WhatToConsiderPiZeroW').getString];
            end
            
            obj.HelpText.AboutSelection = '';
            obj.HelpText.Additional = ['<br>',...
                message('raspi:hwsetup:Note').getString, ...
                message('raspi:hwsetup:ConfirmConfiguration_Note1').getString '<br>',...
                message('raspi:hwsetup:ConfirmConfiguration_Note2').getString];
        end
        
        function out = getPreviousScreenID(obj) %#ok<*MANU>
            out = 'raspi.internal.hwsetup.ConnectHardware';
        end
        
        function out = getNextScreenID(obj)
            out = 'raspi.internal.hwsetup.SetupComplete';
            % Go to Wireless config page for Zero W
            if ~isempty(obj.RaspiAvailable) && strcmp(obj.Workflow.BoardName, message('raspi:hwsetup:RaspberryPiZeroW').getString) && ~obj.Workflow.WirelessScanInit
                out = 'raspi.internal.hwsetup.ScanAndConnect';
            end
            
        end
        
        function restoreScreen(obj)
            obj.enableScreen();
        end
        
        function reinit(obj)
            %Set device info
            hb = raspi.internal.BoardParameters('Raspberry Pi');
            ipaddr = hb.getParam('hostname');
            % Check if ipaddr is empty or is valid
            if ~isempty(ipaddr)
                try
                    obj.Workflow.HardwareInterface.checkValidIp(ipaddr, 'IP address');
                catch
                    ipaddr = '';
                end
            else
                ipaddr = '';
            end
            
            hostname = hb.getParam('BoardName');
            username = hb.getParam('username');
            password = hb.getParam('password');
            
            % Set the DeviceInfoTable
            if strcmp(obj.Workflow.BoardName, message('raspi:hwsetup:RaspberryPiZeroW').getString)
                %Display USB & WLAN ip address
                obj.DeviceInfoTable.Labels = {message('raspi:hwsetup:ConfirmConfiguration_Label1ZeroW').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label2ZeroW').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label2').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label3').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label4').getString};
                if obj.Workflow.WLANConnected
                    wlanIPaddr = obj.Workflow.WLANIPAddress;
                else
                    wlanIPaddr = 'Not Connected';
                end
                obj.DeviceInfoTable.Values = {ipaddr,wlanIPaddr,hostname,username,password};
                obj.DeviceInfoTable.Position = [20 230 320 130];
            else
                obj.DeviceInfoTable.Labels = {message('raspi:hwsetup:ConfirmConfiguration_Label1').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label2').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label3').getString,...
                    message('raspi:hwsetup:ConfirmConfiguration_Label4').getString};
                obj.DeviceInfoTable.Values = {ipaddr,hostname,username,password};
                obj.DeviceInfoTable.Position = [20 230 320 130];
            end
            
            obj.RaspiAvailable = ipaddr;
            
            obj.StatusTable.Status = {''};
        end
 
        function testConnection(obj, ~, ~)
            obj.StatusTable.Enable = 'on';
            obj.HelpText.WhatToConsider = [message('raspi:hwsetup:ConfirmConfiguration_TestPass').getString,...
                '<br>', message('raspi:hwsetup:ConfirmConfiguration_TestFail1').getString];
            % Clear the Icon before disabling the screen
            obj.StatusTable.Status = {''};
            
            obj.disableScreen({'DeviceInfoTable', 'StatusTable', 'CancelButton'});
            restoreOnCleanup = onCleanup(@obj.restoreScreen);
            
            % Get the board parameters
            hb = raspi.internal.BoardParameters('Raspberry Pi');
            hostname = getParam(hb,'hostname');
            username = getParam(hb,'username');
            password = getParam(hb,'password');
            
            % Change host name to RNDIS static IP for PI Zero W
            if strcmp(obj.Workflow.BoardName, message('raspi:hwsetup:RaspberryPiZeroW').getString)
                hostname = '192.168.9.2';
            end
            
            % Attempt to connect to the Raspberry Pi Board
            isConnected = false;
            steps = 3;
            obj.StatusTable.Status = {''};
            
            for step = 1:steps
                obj.StatusTable.Steps = {message('raspi:hwsetup:ConfirmConfiguration_StatusItem1', num2str(step)).getString};
                isConnected = obj.Workflow.HardwareInterface.testSSHConnectionLaunchUDPDaemon(hostname,username,password);
                if isConnected
                    if isempty(obj.RaspiAvailable)
                        ipaddr = obj.getIPfromHostName(hostname,username,password);
                        obj.DeviceInfoTable.Values{1} = ipaddr;
                        obj.RaspiAvailable = ipaddr;
                        setParam(hb,'hostname',ipaddr);
                    end
                    break;
                end
            end
            
            if ~isConnected
                % Try to discover the host on the local LAN
                obj.StatusTable.Steps = {message('raspi:hwsetup:ConfirmConfiguration_StatusItem2').getString};
                obj.StatusTable.Status = {''};
                
                RpiDiscovered = obj.Workflow.HardwareInterface.discoverRpiIP();
                if RpiDiscovered
                    % Update the IP address if discovered IP is not same
                    discoveredIP = getParam(hb,'hostname');
                    if ~strcmp(discoveredIP, hostname)
                        boardname = hb.getParam('BoardName');
                        obj.DeviceInfoTable.Values = {discoveredIP,boardname,username,password};
                    end
                    obj.StatusTable.Steps = {message('raspi:hwsetup:TestConnectionSuccessful').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                else
                    obj.StatusTable.Steps = {message('raspi:hwsetup:TestConnectionFailed').getString};
                    obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                    obj.HelpText.WhatToConsider = [message('raspi:hwsetup:ConfirmConfiguration_TestPass').getString,...
                        '<br>', message('raspi:hwsetup:ConfirmConfiguration_TestFail2').getString];
                end
            else
                obj.StatusTable.Steps = {message('raspi:hwsetup:TestConnectionSuccessful').getString};
                obj.StatusTable.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
            end
        end
        
        function checkBoxValueChange(obj)
            
        end
        
%         function enableWirelessScanCheckBox(obj)
%             % This option will be available only for Pi Zero W and has
%             % obtained a valid ip via USB Gadget connection.
%             if isempty(obj.RaspiAvailable)
%                 obj.ConnWirelessCheckBox.Value = 0;
%                 obj.ConnWirelessCheckBox.Enable = 'off';
%             else
%                 obj.ConnWirelessCheckBox.Enable = 'on';
%             end
%         end
        
    end% methods end
    methods(Static)
        function ipAddr = getIPfromHostName(hostname,username,password)
            try
                sshConnect = matlabshared.internal.ssh2client(hostname,username,password);
                ipAddr = strtrim(execute(sshConnect,'hostname -I | awk ''{print $1}'''));
            catch
                ipAddr = '';
            end
            clear sshConnect;
        end
    end
end