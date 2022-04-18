classdef WirelessConfig < matlab.hwmgr.internal.hwsetup.TemplateBase
    % WirelessConfig  - Screen implementation to enable users to manually
    % configure Wireless connections.
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % SSIDLabel - Text describing the ssid param lable
        SSIDLabel
        % SSIDLabelEditText - Text describing the ssid
        SSIDLabelEditText
        % WifiSecurityLabel - Label
        WiFiSecurityLabel
        % WifiEncryption
        WiFiSecurityDropDown
        % WiFiSecurity
        WiFiSecurity
%         % HostNameLabel - Text describing the host name
%         HostNameLabel
%         % HostNameLabel - Text describing the host name
%         HostNameEditText        
        % Password label WPA Personal
        PasswordLabelWPAPers
        % Password edit text WPA Personal
        PasswordEditTextWPAPers        
        % Password label WEP
        PasswordLabelWEP
        % Password edit text WEP
        PasswordEditTextWEP        
        % WPA Enterprise authentication label
        WPAEnterpriseAuth1Label
        % WPA Enterprise authentication dropdown
        WPAEnterpriseAuth1DropDown
        % WPA Enterprise authentication label
        WPAEnterpriseAuth2Label
        % WPA Enterprise authentication dropdown
        WPAEnterpriseAuth2DropDown
        % UsernameLabelWPAEnterprise
        UsernameLabelWPAEnterprise
        % UsernameEditTextWPAEnterprise
        UsernameEditTextWPAEnterprise
        % PasswordLabelWPAEnterprise
        PasswordLabelWPAEnterprise
        % PasswordEditTextWPAEnterprise
        PasswordEditTextWPAEnterprise        
        % WPA Enterprise password hashValue
        hashValue = '';
        % ConfigureNetworkRadioGroup - Radio button group to display the list of items to choose
        % from (RadioGroup)
        ConfigureNetworkRadioGroup
        % IPAddressLabel - Text describing the IP address.
        IPAddressLabel
        % NetworkMaskLabel - Text describing the network mask
        NetworkMaskLabel
        % DefaultGatewayLabel - Text describing the default gateway
        DefaultGatewayLabel
        % IPAddressEditText - Text describing the IP address.
        IPAddressEditText
        % NetworkMaskEditText - Text describing the network mask
        NetworkMaskEditText
        % DefaultGatewayEditText - Text describing the default gateway
        DefaultGatewayEditText
        % HelpForSelection - Cell array strings/character-vectors for
        % providing more information about the selected item. This will be
        % rendered in the "About Your Selection" section in the HelpText
        % panel
        HelpForSelection = {};
        % RadioGrpLocation - RadioGroup location
        RadioGrpLocation
        % ConstrDone - Constructor done.
        ConstrDone = 0;
    end
    methods
        function obj = WirelessConfig(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:})
            
            % Create the widgets and parent them to the content panel
%             obj.HostNameLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
%             obj.HostNameEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);            
            obj.SSIDLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.SSIDLabelEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.WiFiSecurityLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.WiFiSecurityDropDown = matlab.hwmgr.internal.hwsetup.DropDown.getInstance(obj.ContentPanel);
            obj.ConfigureNetworkRadioGroup = matlab.hwmgr.internal.hwsetup.RadioGroup.getInstance(obj.ContentPanel);     
            
            % Set the Title Text
            obj.Title.Text = message('raspi:hwsetup:WirelessConfigTitle').getString;
            
            % Set the check box label
            %obj.ConfigWifiCheckBox.Text = 'Configure WiFi';
            
            % Set the SSIDLabel Text
            obj.SSIDLabel.Text = message('raspi:hwsetup:WirelessConfigSSIDLabel').getString;
            
            % set the WiFiSecurityLabel text
            obj.WiFiSecurityLabel.Text = message('raspi:hwsetup:WirelessConfigSecurityLabel').getString;
            
            % set the default security option
            obj.WiFiSecurity = message('raspi:hwsetup:WirelessSecurityDropDown1').getString;
            
%             % Set the HostNameLabel Text
%             obj.HostNameLabel.Text = message('raspi:hwsetup:ManualNetConfigHostNameLabel').getString;
                        
            % set Backgroundcolor
            obj.SSIDLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.WiFiSecurityLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
%             obj.HostNameLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
  
            % Set the HelpForSelection property to update the HelpText
            % when RadioGroup selection changes
            obj.HelpForSelection = ...
                {message('raspi:hwsetup:WiFiAutomaticIPAboutSelection').getString, ...
                message('raspi:hwsetup:WiFiManualIPAboutSelection').getString};
            
            % Position
            % Units: Pixels
            % Data type: 1x4 numeric array [left bottom width height]             
            obj.SSIDLabel.Position =                    [20 350 200 20]; 
            obj.SSIDLabelEditText.Position =            [105 350 200 20];
            obj.WiFiSecurityLabel.Position =            [20 320 200 20];
            obj.WiFiSecurityDropDown.Position =         [105 320 200 20];
%             obj.HostNameLabel.Position =                [20 170 200 20];
%             obj.HostNameEditText.Position =             [105 170 200 20];
            
            obj.RadioGrpLocation = 80;
            obj.ConfigureNetworkRadioGroup.Position =   [20 obj.RadioGrpLocation 500 100];
            % Set the ConfigureNetworkRadioGroup Title
            % TItle can't be empty 
            obj.ConfigureNetworkRadioGroup.Title = message('raspi:hwsetup:ManualNetConfigIPAssignmentRGTitle').getString;
            obj.ConfigureNetworkRadioGroup.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            % set radiogroup items
            obj.ConfigureNetworkRadioGroup.Items = ...
                {message('raspi:hwsetup:ManualNetConfigAutomaticIP').getString, ...
                message('raspi:hwsetup:ManualNetConfigManualIP').getString};
            
            
            % set edittext text alignment
            obj.SSIDLabelEditText.TextAlignment = 'left';
            
            % set default values from workflow properties
            obj.SSIDLabelEditText.Text = '<Enter SSID>';
            %message('raspi:hwsetup:WirelessConfigSSIDEditText').getString;
           
            % Set the Dropdown Items
            obj.WiFiSecurityDropDown.Items = {message('raspi:hwsetup:WirelessSecurityDropDown1').getString,...
                message('raspi:hwsetup:WirelessSecurityDropDown2').getString,...
                message('raspi:hwsetup:WirelessSecurityDropDown3').getString,...
                message('raspi:hwsetup:WirelessSecurityDropDown4').getString};
            
%             obj.HostNameEditText.TextAlignment = 'left';
%             obj.HostNameEditText.Text = obj.Workflow.HostName;
            
            % set callback
            % for Security User input
            obj.WiFiSecurityDropDown.ValueChangedFcn = @obj.changeSecurityOption;
            obj.ConfigureNetworkRadioGroup.SelectionChangedFcn = @obj.autoManualSelection;
            % for ssid name
            obj.SSIDLabelEditText.ValueChangedFcn = @obj.setSSIDName;
%             % for host name
%             obj.HostNameEditText.ValueChangedFcn = @obj.setHostName;
            % for IPAddress
            obj.IPAddressEditText.ValueChangedFcn = @obj.setIPAddress;
            % for NetworkMask
            obj.NetworkMaskEditText.ValueChangedFcn = @obj.setNetworkMask;
            % for DefaultGateway
            obj.DefaultGatewayEditText.ValueChangedFcn = @obj.setDefaultGateway;
            
            % helptext
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:WirelessConfigWhatToConsider').getString;
            obj.HelpText.AboutSelection = obj.HelpForSelection{obj.Workflow.IPAssignment};       
            
            obj.createWPAPersonalEntry();
            
            obj.ConstrDone = 1;
        end
        
        function changeSecurityOption(obj, ~, ~)
            % disable the screen and re-enable after validation
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.customenableScreen); % re-enable on cleanup
            obj.deleteWidgets();
            securityType = obj.WiFiSecurityDropDown.Value;
            %             workflow_property = remeberselection;
            switch securityType
                case message('raspi:hwsetup:WirelessSecurityDropDown1').getString
                    %WPA/WPA2 Personal
                    createWPAPersonalEntry(obj);
                    obj.WiFiSecurity = message('raspi:hwsetup:WirelessSecurityDropDown1').getString;
                case message('raspi:hwsetup:WirelessSecurityDropDown2').getString
                    %WPA/WPA2 Enterprise
                    createWPAEnterpriseEntry(obj);
                    obj.WiFiSecurity = message('raspi:hwsetup:WirelessSecurityDropDown2').getString;
                case message('raspi:hwsetup:WirelessSecurityDropDown3').getString
                    %WEP 128-bit Passphrase
                    createWEPEntry(obj);
                    obj.WiFiSecurity = message('raspi:hwsetup:WirelessSecurityDropDown3').getString;
                otherwise
                    %None
                    obj.WiFiSecurity = message('raspi:hwsetup:WirelessSecurityDropDown4').getString;
            end
        end
        
        function deleteWPAPersWidgets(obj)
            %delete widgets corresponding to wifi security options
            obj.PasswordLabelWPAPers.delete;
            obj.PasswordEditTextWPAPers.delete;         
        end
        
        function deleteWEPWidgets(obj)
            obj.PasswordLabelWEP.delete;
            obj.PasswordEditTextWEP.delete;           
        end
        
        function deleteWAPEnterpriseWidgets(obj)
            obj.WPAEnterpriseAuth1Label.delete;
            obj.WPAEnterpriseAuth1DropDown.delete;
            obj.WPAEnterpriseAuth2Label.delete;
            obj.WPAEnterpriseAuth2DropDown.delete;
            obj.UsernameLabelWPAEnterprise.delete;
            obj.UsernameEditTextWPAEnterprise.delete;
            obj.PasswordLabelWPAEnterprise.delete;
            obj.PasswordEditTextWPAEnterprise.delete;         
        end
        
        function deleteWidgets(obj)
            oldDropDown = obj.WiFiSecurity;
            switch oldDropDown
                case message('raspi:hwsetup:WirelessSecurityDropDown1').getString
                    obj.deleteWPAPersWidgets();
                case message('raspi:hwsetup:WirelessSecurityDropDown2').getString
                    obj.deleteWAPEnterpriseWidgets();
                case message('raspi:hwsetup:WirelessSecurityDropDown3').getString
                    obj.deleteWEPWidgets();
                otherwise
                    %None - nothing to delete
            end
        end
        
        function changeWPAEnterpriseCallback(obj, ~, ~)
            switch obj.WPAEnterpriseAuth1DropDown.Value
                case 'Protected EAP (PEAP)'
                    obj.WPAEnterpriseAuth2Label.Enable = 'on';
                    obj.WPAEnterpriseAuth2DropDown.Enable = 'on';
                case 'Tunneled TLS'
                    obj.WPAEnterpriseAuth2Label.Enable = 'on';
                    obj.WPAEnterpriseAuth2DropDown.Enable = 'on';
                case 'TLS'
                    obj.WPAEnterpriseAuth2Label.Enable = 'off';
                    obj.WPAEnterpriseAuth2DropDown.Enable = 'off';                    
                case 'LEAP'
                    obj.WPAEnterpriseAuth2Label.Enable = 'off';
                    obj.WPAEnterpriseAuth2DropDown.Enable = 'off';                    
                otherwise
                    %error    
            end
        end
        
        function createWPAEnterpriseEntry(obj)
            obj.WPAEnterpriseAuth1Label = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.WPAEnterpriseAuth1DropDown = matlab.hwmgr.internal.hwsetup.DropDown.getInstance(obj.ContentPanel);
            obj.WPAEnterpriseAuth2Label = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.WPAEnterpriseAuth2DropDown = matlab.hwmgr.internal.hwsetup.DropDown.getInstance(obj.ContentPanel);            
            obj.UsernameLabelWPAEnterprise = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.UsernameEditTextWPAEnterprise = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.PasswordLabelWPAEnterprise = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            %obj.PasswordEditTextWPAEnterprise = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            classType = 'javax.swing.JPasswordField';
            obj.PasswordEditTextWPAEnterprise = javaObjectEDT(classType);
            position = [105 195 200 20];
            [obj.PasswordEditTextWPAEnterprise, containerComponent] = javacomponent(obj.PasswordEditTextWPAEnterprise, position, obj.ContentPanel.findobj.Peer);
            
            % set the label texts
            obj.WPAEnterpriseAuth1Label.Text = 'EAP method:';
            % Set the Dropdown Items
            obj.WPAEnterpriseAuth1DropDown.Items = {'Protected EAP (PEAP)',...
                'Tunneled TLS',...
                'TLS', ...
                'LEAP', ...
                };
            obj.WPAEnterpriseAuth2Label.Text = 'Phase 2:';
            obj.WPAEnterpriseAuth2DropDown.Items = {'None',...
                'MSCHAPv2',...
                'GTC',...
                'MD5',...
                };            
            obj.UsernameLabelWPAEnterprise.Text = 'Username:';
            obj.PasswordLabelWPAEnterprise.Text = 'Password:';
            
            obj.UsernameEditTextWPAEnterprise.TextAlignment = 'left';
            obj.UsernameEditTextWPAEnterprise.Text = '<Enter Username>';
            %obj.PasswordEditTextWPAEnterprise.TextAlignment = 'left';
            %obj.PasswordEditTextWPAEnterprise.Text = '******';
            
            obj.WPAEnterpriseAuth1Label.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.WPAEnterpriseAuth2Label.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.UsernameLabelWPAEnterprise.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.PasswordLabelWPAEnterprise.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;            
            
            obj.WPAEnterpriseAuth1Label.Position =                   [20 285 200 20];
            obj.WPAEnterpriseAuth1DropDown.Position =                [105 285 200 20];
            obj.WPAEnterpriseAuth2Label.Position =                   [20 255 200 20];
            obj.WPAEnterpriseAuth2DropDown.Position =                [105 255 200 20];
            obj.UsernameLabelWPAEnterprise.Position =                [20 225 200 20];
            obj.UsernameEditTextWPAEnterprise.Position =             [105 225 200 20];
            obj.PasswordLabelWPAEnterprise.Position =                [20 195 200 20];
            %obj.PasswordEditTextWPAEnterprise.Position =    [105 195 200 20];
            
            obj.WPAEnterpriseAuth1DropDown.ValueChangedFcn = @obj.changeWPAEnterpriseCallback;
            
            obj.WPAEnterpriseAuth1Label.show;
            obj.WPAEnterpriseAuth1DropDown.show;
            obj.WPAEnterpriseAuth2Label.show;
            obj.WPAEnterpriseAuth2DropDown.show;
            obj.UsernameLabelWPAEnterprise.show;
            obj.UsernameEditTextWPAEnterprise.show;
            obj.PasswordLabelWPAEnterprise.show;
            %obj.PasswordEditTextWPAEnterprise.show;
            containerComponent.Visible = 'on';         
        end
        
        function createWEPEntry(obj)
            obj.PasswordLabelWEP = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            %obj.PasswordEditTextWEP = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            classType = 'javax.swing.JPasswordField';
            obj.PasswordEditTextWEP = javaObjectEDT(classType);
            position = [105 285 200 20];
            [obj.PasswordEditTextWEP, containerComponent] = javacomponent(obj.PasswordEditTextWEP, position, obj.ContentPanel.findobj.Peer);
            
            % set the Password label text
            obj.PasswordLabelWEP.Text = 'Password:';
            
            %obj.PasswordEditTextWEP.TextAlignment = 'left';
            %obj.PasswordEditTextWEP.Text = '******';
            
            obj.PasswordLabelWEP.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            obj.PasswordLabelWEP.Position = [20 285 200 20];
            %obj.PasswordEditTextWEP.Position = [85 285 200 20];
            
            obj.PasswordLabelWEP.show;
            %obj.PasswordEditTextWEP.show;
            containerComponent.Visible = 'on';      
        end
        function createWPAPersonalEntry(obj)
            obj.PasswordLabelWPAPers = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            %obj.PasswordEditTextWPAPers = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            classType = 'javax.swing.JPasswordField';
            obj.PasswordEditTextWPAPers = javaObjectEDT(classType);
            position = [105 285 200 20];
            obj.ContentPanel.Tag = 'raspi_paneltag';
            parent=findall(0,'Tag','raspi_paneltag');
            panelpeer = findobj(parent,'Tag','raspi_paneltag');
            [obj.PasswordEditTextWPAPers, containerComponent] = javacomponent(obj.PasswordEditTextWPAPers, position, panelpeer);
            
            % set the Password label text
            obj.PasswordLabelWPAPers.Text = 'Password:';
            
            %obj.PasswordEditTextWPAPers.TextAlignment = 'left';
            %obj.PasswordEditTextWPAPers.Text = '******';
            
            obj.PasswordLabelWPAPers.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            obj.PasswordLabelWPAPers.Position = [20 285 200 20];
            %obj.PasswordEditTextWPAPers.Position = [85 285 200 20];
            
            obj.PasswordLabelWPAPers.show;
            %obj.PasswordEditTextWPAPers.show;
            containerComponent.Visible = 'on';
        end
        
        function createManualIPAssignWidget(obj)
            obj.IPAddressLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.IPAddressLabel.Text = message('raspi:hwsetup:ManualNetConfigIPAddressLabel').getString;
            obj.IPAddressEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            
            obj.NetworkMaskLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.NetworkMaskLabel.Text = message('raspi:hwsetup:ManualNetConfigNetworkMaskLabel').getString;
            obj.NetworkMaskEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            
            obj.DefaultGatewayLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.DefaultGatewayLabel.Text = message('raspi:hwsetup:ManualNetConfigDefaultGatewayLabel').getString;
            obj.DefaultGatewayEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            
            obj.IPAddressLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.NetworkMaskLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.DefaultGatewayLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            obj.setIPAssignmentPosition();
            
            obj.IPAddressEditText.Text = '192.168.1.2';%obj.Workflow.IPAddress;
            obj.NetworkMaskEditText.Text = '255.255.255.0';%obj.Workflow.NetworkMask;
            obj.DefaultGatewayEditText.Text = '192.168.1.1';%obj.Workflow.Gateway; 
            
            obj.IPAddressEditText.TextAlignment = 'left';
            obj.NetworkMaskEditText.TextAlignment = 'left';
            obj.DefaultGatewayEditText.TextAlignment = 'left';            
            
            obj.IPAddressLabel.show;
            obj.IPAddressEditText.show;
            obj.NetworkMaskLabel.show;
            obj.NetworkMaskEditText.show;
            obj.DefaultGatewayLabel.show;
            obj.DefaultGatewayEditText.show;
            
        end
        
        function setIPAssignmentPosition(obj)
            location = obj.RadioGrpLocation;
            if obj.isManualConfig
                obj.IPAddressLabel.Position = [20 location 200 20];
                obj.IPAddressEditText.Position = [120 location 200 20];
                obj.NetworkMaskLabel.Position = [20 location-30 200 20];
                obj.NetworkMaskEditText.Position = [120 location-30 200 20];
                obj.DefaultGatewayLabel.Position = [20 location-60 200 20];
                obj.DefaultGatewayEditText.Position = [120 location-60 200 20];
            end
%              obj.ConfigureNetworkRadioGroup.Position = [18 location 220 60];
%              obj.ConfigureNetworkRadioGroup.ValueIndex = RadioButtonIndex;
        end
        
        function reinit(obj)
            % remember the selected and modified items
            
            %TO DO:
            %remove password entered.
            
        end
        
        function out = getNextScreenID(obj)
            % Set HostName to update hardwareinterface class
            obj.setSSIDName;
            obj.setPassphrase;
            if obj.isManualConfig
                obj.Workflow.WLANStaticIP = 1;
                % Validate only if manual is selected.
                obj.setIPAddress;
                obj.setNetworkMask;
                obj.setDefaultGateway;
            end
            % Set Wireless details to hardwareinterface class 
            obj.Workflow.HardwareInterface.setWirelessDetails(obj.Workflow);
            
            out = 'raspi.internal.hwsetup.SelectDrive';
        end
        
        function out = getPreviousScreenID(obj) %#ok<MANU>
%             errorhandle = findall(0,'type','figure','Tag', message('raspi:hwsetup:HWSetupValidationErrorTag').getString);
%             if ~isempty(errorhandle)
%                 close(errorhandle);
%             end
            out = 'raspi.internal.hwsetup.SelectNetwork';
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
        
        function autoManualSelection(obj, ~, ~)
            % disable the screen and re-enable
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.customenableScreen); % re-enable on cleanup            
            % Enable IP Address, Network mask, and Default gateway widgets
            % to make it editable
            if obj.isManualConfig
                obj.createManualIPAssignWidget();                
                obj.HelpText.AboutSelection = obj.HelpForSelection{obj.ConfigureNetworkRadioGroup.ValueIndex};
            else%Automatic
                % Disable IP Address, Network mask, and Default gateway widgets
                % to make it non-editable
                obj.IPAddressLabel.delete;
                obj.IPAddressEditText.delete;
                obj.NetworkMaskLabel.delete;
                obj.NetworkMaskEditText.delete;
                obj.DefaultGatewayLabel.delete;
                obj.DefaultGatewayEditText.delete;
                obj.HelpText.AboutSelection = obj.HelpForSelection{obj.ConfigureNetworkRadioGroup.ValueIndex};
            end
        end
        
        function out = isManualConfig(obj)
            if strcmp(obj.ConfigureNetworkRadioGroup.Value, ...
                    message('raspi:hwsetup:ManualNetConfigManualIP').getString)%Manual
                out = true;
            else
                out = false;
            end
        end

%         function setHostName(obj, ~, ~)
%             % Disable the screen and re-enable after validation
%             obj.disableScreen();
%             enableScreen = onCleanup(@()obj.customenableScreen); % re-enable on cleanup
%             hostName = obj.HostNameEditText.Text;
%             if ~ischar(hostName)
%                 error(message('raspi:hwsetup:InvalidArgument', 'raspi:hwsetup:ManualNetConfigHostNameLabel'));
%             end
%             hostName = strtrim(hostName);
%             if ~isrow(hostName)
%                 hostName = hostName.';
%             end
%             tmp = regexp(hostName, '^([a-zA-Z\d\-]){1,63}$', 'match', 'once');
%             if isempty(tmp) || ~isequal(tmp, hostName)
%                 drawnow; % This can be removed after testing Kyle's changes
%                 % drawnow is required to synchronize calls from getNextScreen callback and
%                 % ValueChanged callback from EditText. Without pause, sometimes the
%                 % GUI to bring errordlg (pop up window if validation fails)
%                 % from ValueChangedCbk is delayed causing an error free scenario which
%                 % takes to the next screen and then error dlg comes up.
%                 errorhandle = findall(0,'type','figure','Tag', message('raspi:hwsetup:HWSetupValidationErrorTag').getString);
%                 if isempty(errorhandle)
%                     error(message('raspi:hwsetup:InvalidHostName'));
%                 else
%                     close(errorhandle);
%                     error(message('raspi:hwsetup:InvalidHostName'));
%                 end
%             else
%                 obj.Workflow.HostName = hostName;
%             end
%         end
        
        function setSSIDName(obj, ~, ~)
            % disable the screen and re-enable after validation
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.customenableScreen); % re-enable on cleanup
            ssidName = strtrim(obj.SSIDLabelEditText.Text);
            
            % The length of the SSID information field is between 0 and 32 octets. 
            % A 0 length information field is used within Probe Request management frames to indicate the wildcard SSID. 
            % Section 7.3.2.1 of the 802.11-2007 specification            
            if numel(ssidName) > 32
                drawnow;
                % pause is required to synchronize calls from getNextScreen callback and
                % valuechanged callback from edit text. Without pause, sometimes the
                % GUI to bring errordlg (pop up window if validation fails)
                % from valuechangedcbk is delayed causing an error free scenario which
                % takes to the next screen and then error dlg comes up.
                errorhandle = findall(0,'type','figure','Tag', message('raspi:hwsetup:HWSetupValidationErrorTag').getString);
                if ~isempty(errorhandle)
                    close(errorhandle);
                end
                
                error(message('raspi:hwsetup:InvalidSSID'));
            else
                obj.Workflow.SSIDName = ssidName;
            end
        end
        
        function configText = getWPAEnterpriseConfig(obj)
            switch obj.WPAEnterpriseAuth1DropDown.Value
                case 'Protected EAP (PEAP)'
                    configText = '\teap=PEAP\n';
                case 'Tunneled TLS'
                    configText = '\teap=TTLS\n';
                otherwise
                    configText = '';
            end
            
            switch obj.WPAEnterpriseAuth2DropDown.Value
                case 'MSCHAPv2'
                    configText = [configText, ...
                        '\tphase2="auth=MSCHAPV2"\n', ...
                        ];
                case 'GTC'
                    configText = [configText, ...
                        '\tphase2="autheap=GTC"\n', ...
                        ];
                otherwise
                    configText = [configText, ...
                        '', ...
                        ];
            end
            
        end
        
        function setPassphrase(obj, ~, ~)
            securityType = obj.WiFiSecurityDropDown.Value;
            switch securityType
                case message('raspi:hwsetup:WirelessSecurityDropDown1').getString
                    obj.Workflow.Passphrase = [
                        '\tkey_mgmt=WPA-PSK\n', ...
                        '\tpsk="', ...
                        strtrim(char(obj.PasswordEditTextWPAPers.getText)), ...
                        '"\n', ...
                        ];
                case message('raspi:hwsetup:WirelessSecurityDropDown2').getString
                    if ~isempty(char(obj.PasswordEditTextWPAEnterprise.getText))
                        if ispc
                            obj.hashValue = matlabshared.internal.hashmd4Data(strtrim(char(obj.PasswordEditTextWPAEnterprise.getText)));
                        elseif ismac
                            %use openssl in mac
                            command = ['echo -n ',strtrim(char(obj.PasswordEditTextWPAEnterprise.getText)),' | iconv -t UTF-16LE | openssl md4'];
                            [~,cmdout] = system(command);
                            obj.hashValue = strtrim(cmdout);
                        else
                            %use openssl
                            command = ['echo -n ',strtrim(char(obj.PasswordEditTextWPAEnterprise.getText)),' | iconv -t utf16le | openssl md4'];
                            [status,cmdout] = system(command);
                            tmp = strtrim(cmdout(strfind(cmdout,'(stdin)='):end));
                            splitted = strsplit(tmp); 
                            obj.hashValue = splitted{end};
                        end
                        obj.PasswordEditTextWPAEnterprise.setText('');
                    end                  
                    obj.Workflow.Passphrase = [
                        '\tkey_mgmt=WPA-EAP\n', ...
                        obj.getWPAEnterpriseConfig, ...
                        '\tidentity="', obj.UsernameEditTextWPAEnterprise.Text, '"\n', ...
                        '\tpassword=hash:', obj.hashValue, '\n', ...
                        ];                   
                case message('raspi:hwsetup:WirelessSecurityDropDown3').getString
                    obj.Workflow.Passphrase = [
                        '\tkey_mgmt=NONE\n', ...
                        '\tpsk="', ...
                        strtrim(char(obj.PasswordEditTextWEP.getText)), ...
                        '"\n', ...
                        ];
                otherwise
                    %No security
                    obj.Workflow.Passphrase = '\tkey_mgmt=NONE\n';
            end
            obj.Workflow.WiFiSecurity = securityType;
        end
        
        function setIPAddress(obj, ~, ~)
            % disable the screen and re-enable after validation
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.enableScreen); % re-enable on cleanup
            ipAddress = obj.IPAddressEditText.Text;
            status =  obj.Workflow.HardwareInterface.checkValidIp(ipAddress, obj.IPAddressLabel.Text);
            if ~status
                obj.Workflow.WLANIPAddress = ipAddress;
            end
        end
        
        function setNetworkMask(obj, ~, ~)
            % disable the screen and re-enable after validation
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.enableScreen); % re-enable on cleanup
            networkMask = obj.NetworkMaskEditText.Text;
            status =  obj.Workflow.HardwareInterface.checkValidIp(networkMask, obj.NetworkMaskLabel.Text);
            if ~status
                obj.Workflow.WLANNetworkMask = networkMask;
            end
        end
        
        function setDefaultGateway(obj, ~, ~)
            % disable the screen and re-enable after validation
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.enableScreen); % re-enable on cleanup
            gateway = obj.DefaultGatewayEditText.Text;
            status =  obj.Workflow.HardwareInterface.checkValidIp(gateway, obj.DefaultGatewayLabel.Text);
            if ~status
                obj.Workflow.WLANGateway = gateway;
            end
        end
        
    end% end private methods
    
end % end class

