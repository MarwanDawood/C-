classdef ManualNetworkConfiguration < matlab.hwmgr.internal.hwsetup.TemplateBase
    % ManualNetworkConfiguration  - Screen implementation to enable users to manually
    % configure network settings
    
    %   Copyright 2016 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % HostNameLabel - Text describing the host name
        HostNameLabel
        % HostNameLabel - Text describing the host name
        HostNameEditText
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
    end
    methods
        function obj = ManualNetworkConfiguration(varargin)
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(varargin{:})
            
            % Create the widgets and parent them to the content panel
            obj.HostNameLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.HostNameEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.ConfigureNetworkRadioGroup = matlab.hwmgr.internal.hwsetup.RadioGroup.getInstance(obj.ContentPanel);
            obj.IPAddressLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.NetworkMaskLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.DefaultGatewayLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.IPAddressEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.NetworkMaskEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.DefaultGatewayEditText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            
            % Set the Title Text
            obj.Title.Text = message('raspi:hwsetup:ManualNetConfigTitle').getString;
            
            % Set the HostNameLabel Text
            obj.HostNameLabel.Text = message('raspi:hwsetup:ManualNetConfigHostNameLabel').getString;
            
            % set position for Radio-group that contains auto-Manual Selection
            % Position = [left bottom width height]
            obj.ConfigureNetworkRadioGroup.Position = [20 200 500 130];
            
            % Set the ConfigureNetworkRadioGroup Title
            obj.ConfigureNetworkRadioGroup.Title = message('raspi:hwsetup:ManualNetConfigIPAssignmentRGTitle').getString;
            
            % Set the Label properties Text
            obj.IPAddressLabel.Text = message('raspi:hwsetup:ManualNetConfigIPAddressLabel').getString;
            obj.NetworkMaskLabel.Text = message('raspi:hwsetup:ManualNetConfigNetworkMaskLabel').getString;
            obj.DefaultGatewayLabel.Text = message('raspi:hwsetup:ManualNetConfigDefaultGatewayLabel').getString;
            
            % Set Background color
            obj.HostNameLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.IPAddressLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.NetworkMaskLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.DefaultGatewayLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.ConfigureNetworkRadioGroup.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            % Set radio-group items
            obj.ConfigureNetworkRadioGroup.Items = ...
                {message('raspi:hwsetup:ManualNetConfigAutomaticIP').getString, ...
                message('raspi:hwsetup:ManualNetConfigManualIP').getString};
            
            % Set the HelpForSelection property to update the HelpText
            % when RadioGroup selection changes
            obj.HelpForSelection = {message('raspi:hwsetup:ManualNetConfigAutomaticIPAboutSelection').getString,...
                message('raspi:hwsetup:ManualNetConfigManualIPAboutSelection').getString};
            
            % Set position for Host Name related widgets
            obj.HostNameLabel.shiftVertically(280);
            obj.HostNameEditText.shiftHorizontally(-180);
            obj.HostNameEditText.shiftVertically(50);
            obj.HostNameEditText.addWidth(150);
            
            
            
            % Set positions for IP address, NetworkMask, and DefaultGateway related
            % widgets
            obj.IPAddressLabel.shiftVertically(125);
            obj.NetworkMaskLabel.shiftVertically(100);
            obj.DefaultGatewayLabel.shiftVertically(75);
            
            obj.NetworkMaskLabel.addWidth(30);
            obj.DefaultGatewayLabel.addWidth(30);
            
            obj.IPAddressEditText.shiftHorizontally(-180);
            obj.IPAddressEditText.shiftVertically(-100);
            obj.IPAddressEditText.addWidth(150);
            
            obj.NetworkMaskEditText.shiftHorizontally(-180);
            obj.NetworkMaskEditText.shiftVertically(-125);
            obj.NetworkMaskEditText.addWidth(150);
            
            obj.DefaultGatewayEditText.shiftHorizontally(-180);
            obj.DefaultGatewayEditText.shiftVertically(-150);
            obj.DefaultGatewayEditText.addWidth(150);
            
            % Platform specific change
            if isunix
                if ~ismac
                    obj.HostNameLabel.addWidth(30);
                    obj.IPAddressLabel.addWidth(30);
                    obj.NetworkMaskLabel.addWidth(30);
                    obj.DefaultGatewayLabel.addWidth(30);
                    
                    obj.HostNameEditText.shiftHorizontally(20);
                    obj.IPAddressEditText.shiftHorizontally(20);
                    obj.NetworkMaskEditText.shiftHorizontally(20);
                    obj.DefaultGatewayEditText.shiftHorizontally(20);
                end
            end
            
            % Set EditText widget's text alignment
            obj.HostNameEditText.TextAlignment = 'left';
            obj.IPAddressEditText.TextAlignment = 'left';
            obj.NetworkMaskEditText.TextAlignment = 'left';
            obj.DefaultGatewayEditText.TextAlignment = 'left';
            
            % Set default values from workflow properties
            obj.HostNameEditText.Text = obj.Workflow.HostName;
            obj.IPAddressEditText.Text = obj.Workflow.IPAddress;
            obj.NetworkMaskEditText.Text = obj.Workflow.NetworkMask;
            obj.DefaultGatewayEditText.Text = obj.Workflow.Gateway;
            
            % Set callback for ConfigureNetworkRadioGroup widget
            obj.ConfigureNetworkRadioGroup.SelectionChangedFcn = @obj.autoManualSelection;
            % Set callback for HostNameEditText widget
            obj.HostNameEditText.ValueChangedFcn = @obj.setHostName;
            % Set callback for IPAddressEditText widget
            obj.IPAddressEditText.ValueChangedFcn = @obj.setIPAddress;
            % Set callback for NetworkMaskEditText widget
            obj.NetworkMaskEditText.ValueChangedFcn = @obj.setNetworkMask;
            % Set callback for DefaultGatewayEditText widget
            obj.DefaultGatewayEditText.ValueChangedFcn = @obj.setDefaultGateway;
            
            % Helptext
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:ManualNetConfigHostNameWhatToConsider').getString;
            obj.HelpText.AboutSelection = obj.HelpForSelection{obj.Workflow.IPAssignment};
            
            % Remember the selected RadioGroup item
            obj.ConfigureNetworkRadioGroup.ValueIndex = obj.Workflow.IPAssignment;
        end
        
        function reinit(obj)
            % Remember the selected and modified items
            obj.ConfigureNetworkRadioGroup.ValueIndex = obj.Workflow.IPAssignment;
            obj.HelpText.AboutSelection = obj.HelpForSelection{obj.Workflow.IPAssignment};
            
            obj.HostNameEditText.Text = obj.Workflow.HostName;
            obj.IPAddressEditText.Text = obj.Workflow.IPAddress;
            obj.NetworkMaskEditText.Text = obj.Workflow.NetworkMask;
            obj.DefaultGatewayEditText.Text = obj.Workflow.Gateway;
        end
        
        function out = getNextScreenID(obj)
            % Set HostName to update HardwareInterface class
            obj.setHostName;
            if obj.isManualConfig
                % Validate only if manual is selected.
                obj.setIPAddress;
                obj.setNetworkMask;
                obj.setDefaultGateway;
            end
            % Set IPAddress details to hardwareinterface class for static
            % IP
            obj.Workflow.HardwareInterface.setStaticIPDetails(obj.Workflow);
            out = 'raspi.internal.hwsetup.SelectDrive';
        end
        
        function out = getPreviousScreenID(obj) %#ok<MANU>
            errorhandle = findall(0,'type','figure','Tag', message('raspi:hwsetup:HWSetupValidationErrorTag').getString);
            if ~isempty(errorhandle)
                close(errorhandle);
            end
            out = 'raspi.internal.hwsetup.SelectNetwork';
        end
    end
    
    % Overridden methods
    methods(Access = protected)
        function customenableScreen(obj)
            % call parent enableScreen method that, enables all widgets in
            % the screen
            obj.enableScreen();
            % Check for Auto or manual and disable the widgets.
            obj.autoManualSelection();
        end
        
        function autoManualSelection(obj, ~, ~)
            obj.Workflow.IPAssignment = obj.ConfigureNetworkRadioGroup.ValueIndex;
            % Enable IP Address, Network mask, and Default gateway widgets
            % to make it editable
            if obj.isManualConfig
                obj.IPAddressEditText.Enable = 'on';
                obj.NetworkMaskEditText.Enable = 'on';
                obj.DefaultGatewayEditText.Enable = 'on';
                obj.Workflow.DhcpChoice = 1;% static IP
                obj.HelpText.AboutSelection = obj.HelpForSelection{obj.ConfigureNetworkRadioGroup.ValueIndex};
            else%Automatic
                % Disable IP Address, Network mask, and Default gateway widgets
                % to make it non-editable
                obj.IPAddressEditText.Enable = 'off';
                obj.NetworkMaskEditText.Enable = 'off';
                obj.DefaultGatewayEditText.Enable = 'off';
                obj.Workflow.DhcpChoice = 0;
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
        
        function setHostName(obj, ~, ~)
            % Disable the screen and re-enable after validation
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.customenableScreen); % re-enable on cleanup
            hostName = obj.HostNameEditText.Text;
            if ~ischar(hostName)
                error(message('raspi:hwsetup:InvalidArgument', 'raspi:hwsetup:ManualNetConfigHostNameLabel'));
            end
            hostName = strtrim(hostName);
            if ~isrow(hostName)
                hostName = hostName.';
            end
            tmp = regexp(hostName, '^([a-zA-Z\d\-]){1,63}$', 'match', 'once');
            if isempty(tmp) || ~isequal(tmp, hostName)
                drawnow; % This can be removed after testing Kyle's changes
                % drawnow is required to synchronize calls from getNextScreen callback and
                % ValueChanged callback from EditText. Without pause, sometimes the
                % GUI to bring errordlg (pop up window if validation fails)
                % from ValueChangedCbk is delayed causing an error free scenario which
                % takes to the next screen and then error dlg comes up.
                errorhandle = findall(0,'type','figure','Tag', message('raspi:hwsetup:HWSetupValidationErrorTag').getString);
                if isempty(errorhandle)
                    error(message('raspi:hwsetup:InvalidHostName'));
                else
                    close(errorhandle);
                    error(message('raspi:hwsetup:InvalidHostName'));
                end
            else
                obj.Workflow.HostName = hostName;
            end
        end
        
        function setIPAddress(obj, ~, ~)
            % Disable the screen and re-enable after validation
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.enableScreen); % re-enable on cleanup
            ipAddress = obj.IPAddressEditText.Text;
            status =  obj.Workflow.HardwareInterface.checkValidIp(ipAddress, obj.IPAddressLabel.Text);
            if ~status
                obj.Workflow.IPAddress = ipAddress;
            end
        end
        
        function setNetworkMask(obj, ~, ~)
            % Disable the screen and re-enable after validation
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.enableScreen); % re-enable on cleanup
            networkMask = obj.NetworkMaskEditText.Text;
            status =  obj.Workflow.HardwareInterface.checkValidIp(networkMask, obj.NetworkMaskLabel.Text);
            if ~status
                obj.Workflow.NetworkMask = networkMask;
            end
        end
        
        function setDefaultGateway(obj, ~, ~)
            % Disable the screen and re-enable after validation
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.enableScreen); % re-enable on cleanup
            gateway = obj.DefaultGatewayEditText.Text;
            status =  obj.Workflow.HardwareInterface.checkValidIp(gateway, obj.DefaultGatewayLabel.Text);
            if ~status
                obj.Workflow.Gateway = gateway;
            end
        end
        
    end% end private methods
    
end % end class

