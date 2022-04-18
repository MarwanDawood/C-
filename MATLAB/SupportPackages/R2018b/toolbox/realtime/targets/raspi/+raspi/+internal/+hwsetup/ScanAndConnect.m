classdef ScanAndConnect < matlab.hwmgr.internal.hwsetup.TemplateBase
    % ScanAndConnect  - Screen implementation to enable users to scan and
    % connect to a wireless network.
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Scan and connect radio group - Radio button group to select
        % yes/no for wireless connection
        % from (RadioGroup)
        ConfigureWirelessRadioGroup
        % IPAddressLabel - Text describing the IP address.
        % Scan button
        ScanButton 
        % SSIDLabel - Text describing the ssid param lable
        SSIDLabel
        % SSIDLabelDropDown - Select SSID 
        SSIDLabelDropDown
        HelpForSelection = {};
        % List of wireless networks available 
        wirelessNwList 
        % Security options for each wireless networks
        wirelessNwsecurity
        % WiFi Security Type of the selected network
        WiFiSecurityType
    end
    methods
        function obj = ScanAndConnect(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:})
            
            % Create the widgets and parent them to the content panel   
            obj.ConfigureWirelessRadioGroup = matlab.hwmgr.internal.hwsetup.RadioGroup.getInstance(obj.ContentPanel);
            
            % Set the Title Text
            obj.Title.Text = message('raspi:hwsetup:ScanAndConnectTitle').getString;       
            
            % Set the yes/No radio button
            obj.ConfigureWirelessRadioGroup.Position =   [20 280 500 100];
            
            % Set the ConfigureWirelessRadioGroup Title
            % TItle can't be empty 
            obj.ConfigureWirelessRadioGroup.Title = message('raspi:hwsetup:ScanAndConnectRadioGrp').getString;
            obj.ConfigureWirelessRadioGroup.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            % set radiogroup items
            obj.ConfigureWirelessRadioGroup.Items = ...
                {message('raspi:hwsetup:ConfigureWirelessSkip').getString, ...
                 message('raspi:hwsetup:ConfigureWirelessScan').getString};   
            
             % Set the HelpForSelection property to update the HelpText
             % when RadioGroup selection changes
             obj.HelpForSelection = ...
                 {message('raspi:hwsetup:WiFiAutomaticIPAboutSelection').getString, ...
                 message('raspi:hwsetup:WiFiManualIPAboutSelection').getString};
            
            % set callbacks
            % for Radio button
            obj.ConfigureWirelessRadioGroup.SelectionChangedFcn = @obj.skipScanSelection;
            
            % helptext
            obj.HelpText.AboutSelection = message('raspi:hwsetup:ConfigureWirelessSkip_AboutSelection').getString;
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConfigureWirelessSkip_WhatToConsider').getString;
            obj.Workflow.WirelessScanInit = true;
              
        end
        
        function skipScanSelection(obj, ~, ~)
            % Delete other widgets if skip is selected
            if strcmp(obj.ConfigureWirelessRadioGroup.Value,...
                    message('raspi:hwsetup:ConfigureWirelessSkip').getString)
                % Skip the scan & connect
                obj.deleteWidgets();
                obj.HelpText.AboutSelection = message('raspi:hwsetup:ConfigureWirelessSkip_AboutSelection').getString;
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConfigureWirelessSkip_WhatToConsider').getString;
                obj.NextButton.Enable = 'on';
            else
                % Scan and connect to wireless network
                obj.createScanWidgets();
                obj.HelpText.AboutSelection = message('raspi:hwsetup:ConfigureWireless_AboutSelection').getString;
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConfigureWireless_WhatToConsider').getString;
                obj.NextButton.Enable = 'off';
            end
        end
        
        function scanWirelessNetworks(obj, ~, ~)
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.customenableScreen); % re-enable on cleanup            
            hb = raspi.internal.BoardParameters('Raspberry Pi');
            ipaddr = hb.getParam('hostname');
            username = hb.getParam('username');
            password = hb.getParam('password');
            sshConnect = matlabshared.internal.ssh2client(ipaddr,username,password);
            
            % Start scan and populate the list
            status = execute(sshConnect,'/sbin/wpa_cli -i wlan0 flush; /sbin/wpa_cli -i wlan0 scan');
            if contains(status, 'OK')
                % Wait for results to populate.
                pause(1);
            else
                warndlg(message('raspi:hwsetup:ScanAndConnectError').string);
            end
            
            % Parse the scan results and get the list.
            execute(sshConnect,'/sbin/wpa_cli -i wlan0 scan_results | sed -e ''1,1d'' | cut -f 4,5 | sort -u > /tmp/scanResults');
            obj.wirelessNwList = strtrim(strsplit(strtrim(execute(sshConnect,'cat /tmp/scanResults | awk ''{$1="";print $0}''')),newline));
            obj.wirelessNwsecurity = strsplit(strtrim(execute(sshConnect,'cat /tmp/scanResults | cut -f 1')));
                       
            obj.SSIDLabelDropDown.Items = [obj.wirelessNwList, {'<Hidden Wireless network>'}];
            clear sshConnect;
            if isempty(obj.wirelessNwList)
                obj.NextButton.Enable = 'off';
            else
                obj.NextButton.Enable = 'on';
            end
        end
       
        
        function deleteWidgets(obj)
            % Delete widgets for scanning
            obj.ScanButton.delete;
            obj.SSIDLabel.delete;
            obj.SSIDLabelDropDown.delete;
        end
        
        
        
        function createScanWidgets(obj)
            obj.ScanButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.SSIDLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.SSIDLabelDropDown = matlab.hwmgr.internal.hwsetup.DropDown.getInstance(obj.ContentPanel);
            
            % Set the Button Text
            obj.ScanButton.Text = message('raspi:hwsetup:ScanAndConnectButton').getString;
            
            % Set the SSIDLabel Text
            obj.SSIDLabel.Text = message('raspi:hwsetup:WirelessConfigSSIDLabel').getString;
            
            % set Backgroundcolor
            obj.SSIDLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
                        
            % Position
            % Units: Pixels
            % Data type: 1x4 numeric array [left bottom width height]           
            obj.SSIDLabel.Position =                    [20 220 200 20];
            obj.SSIDLabelDropDown.Position =            [105 220 200 20];
            obj.ScanButton.Position =                   [320 215 110 25];
            
            % set default values from workflow properties
            obj.SSIDLabelDropDown.Items = {'<Select network>'};
            
            % Set callbacks
            % for scan button
            obj.ScanButton.ButtonPushedFcn  = @obj.scanWirelessNetworks;
            % for ssid name
            obj.SSIDLabelDropDown.ValueChangedFcn = @obj.setSSIDName;
        end
       
        
        function reinit(obj)
            % Clear the scan results
            if strcmp(obj.ConfigureWirelessRadioGroup.Value,...
                    message('raspi:hwsetup:ConfigureWirelessScan').getString)
                % set default values from workflow properties
                obj.SSIDLabelDropDown.Items = {'<Select network>'};
                obj.wirelessNwList = '';
                obj.wirelessNwsecurity = '';
                obj.NextButton.Enable = 'off';
            end
        end
        
        function out = getNextScreenID(obj)
            if strcmp(obj.ConfigureWirelessRadioGroup.Value,...
                    message('raspi:hwsetup:ConfigureWirelessSkip').getString)
                % Skip wireless configuration
                out = 'raspi.internal.hwsetup.ConfirmConfiguration';               
            else
                % Go to wireless configuration
                out = 'raspi.internal.hwsetup.WirelessConfigViaUSB';
                obj.setSSIDName;
            end
            % Set Wireless details to hardwareinterface class
            obj.Workflow.HardwareInterface.setWirelessDetails(obj.Workflow);
            
        end
        
        function out = getPreviousScreenID(obj)
            if strcmp(obj.Workflow.BoardName,message('raspi:hwsetup:RaspberryPiZeroW').getString)
                out = 'raspi.internal.hwsetup.ConnectHardware';
            else
                out = 'raspi.internal.hwsetup.ConfirmConfiguration';
            end
        end
    end
    
    % Overridden methods
    methods(Access = protected)
        function customenableScreen(obj)
            % call parent enableScreen method that, enables all widgets in
            % the screen
            obj.enableScreen();
            % check for Auto or manual and disable the widgets.
            %obj.autoManualSelection();
        end
        
        function setSSIDName(obj, ~, ~)
            % disable the screen and re-enable after validation
            ssidName = strtrim(obj.SSIDLabelDropDown.Value);
            obj.Workflow.SSIDName = ssidName;
            %Set security
            index = find(strcmp(ssidName,obj.wirelessNwList));
            if isempty(index)
                %Hidden wireless network
                % To Do: Add xml entry
                obj.Workflow.WiFiSecurity = 'HiddenNW';
            else
                security = obj.wirelessNwsecurity(index);
                obj.Workflow.WiFiSecurity =  security{1};
            end     
        end
        
    end% end private methods
    
end % end class

