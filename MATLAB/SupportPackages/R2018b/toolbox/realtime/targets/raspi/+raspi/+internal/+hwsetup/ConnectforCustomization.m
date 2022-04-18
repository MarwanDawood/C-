classdef ConnectforCustomization < raspi.internal.hwsetup.EnterLoginDetails
    % ConnectforCustomization - Get the Login credentials of the Raspberry Pi
    %   Copyright 2017-2018 The MathWorks, Inc.
    
    
    properties(Hidden)
        StatusTable
        connectionSuccess = false;
    end
    
    methods
        function obj = ConnectforCustomization(workflow)
            % Call to class constructor
            obj@raspi.internal.hwsetup.EnterLoginDetails(workflow)
            % Set Title
            obj.Title.Text = message('raspi:hwsetup:ConnectForCustomiztionTitle').getString;
            % Set "What to consider"
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectForCustomiztionWhatToConsider').getString;
            % Set "About"
            obj.HelpText.AboutSelection = '';
            obj.Description.Text = message('raspi:hwsetup:ConnectForCustomiztionDesc').getString;
            % Device address label
            obj.DeviceAddressLabel.Text =  message('raspi:hwsetup:ConnectForCustomiztionHostName').getString;
            obj.DeviceUsernameLabel.Text =  message('raspi:hwsetup:ConnectForCustomiztionUsrName').getString;
            obj.DevicePasswordLabel.Text =  message('raspi:hwsetup:ConnectForCustomiztionPsswd').getString;
            
            % Set the Test Connection Button
            obj.TestConnButton.Text = message('raspi:hwsetup:ConnectForCustomiztionButtonTitle').getString;
            obj.TestConnButton.ButtonPushedFcn = @obj.testConnection;
            obj.TestConnButton.Position = [20 170 143 22];
            obj.TestConnButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.TestConnButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            % Set the StatusTable
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {message('raspi:hwsetup:ConnectForCustomiztionPingStatus').getString;...
                message('raspi:hwsetup:ConnectForCustomiztionSSHStatus').getString;...
                message('raspi:hwsetup:ConnectForCustomiztionSudoStatus').getString;...
                message('raspi:hwsetup:ConnectForCustomiztionInternetStatus').getString};
            obj.StatusTable.Position = [20 60 400 100];
            obj.StatusTable.ColumnWidth = [20 408];
            obj.StatusTable.Enable = 'off';
            
            %Disable Next till sucessful test connection
            obj.NextButton.Enable = 'off';
        end
        
        function restoreValues(obj)
            obj.TestConnButton.Enable = 'on';
            obj.enableScreen();
            obj.connectionSuccess = false;
            obj.NextButton.Enable = 'off';
        end
        
        function out = getPreviousScreenID(~)
            out = 'raspi.internal.hwsetup.SelectLinuxImage';
        end
        
        function out = getNextScreenID(obj)
            if obj.connectionSuccess
                out = 'raspi.internal.hwsetup.DisplayPackageList';
            end
        end
        
        function restoreScreen(obj)
            obj.enableScreen();
            if ~(obj.connectionSuccess)
                  obj.NextButton.Enable = 'off';
            end
            
        end
        
        function reinit(obj)
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {message('raspi:hwsetup:ConnectForCustomiztionPingStatus').getString;...
                message('raspi:hwsetup:ConnectForCustomiztionSSHStatus').getString;...
                message('raspi:hwsetup:ConnectForCustomiztionSudoStatus').getString;...
                message('raspi:hwsetup:ConnectForCustomiztionInternetStatus').getString};
            obj.StatusTable.Enable = 'off';
            obj.connectionSuccess= false;
            obj.NextButton.Enable = 'off';
        end
        
        function testConnection(obj, ~, ~)
            %If this is a test environment, skip any checks and proceed
            %with a success scenario.
            obj.StatusTable.Enable = 'on';
            if ispref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest')&&...
                    (getpref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest') == 1)
                obj.connectionSuccess = true;
                obj.StatusTable.Steps = {message('raspi:hwsetup:ConnectForCustomiztionPingPass').getString;...
                    message('raspi:hwsetup:ConnectForCustomiztionSSHPass').getString;...
                    message('raspi:hwsetup:ConnectForCustomiztionSudoStatus').getString;...
                    message('raspi:hwsetup:ConnectForCustomiztionInternetPass').getString};
                obj.StatusTable.Status(1) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                obj.StatusTable.Status(2) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                obj.StatusTable.Status(3) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                obj.StatusTable.Status(4) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
            else
                %Validate the device address and username to be non-empty
                validateattributes(obj.DeviceAddressText.Text,{'char'}, {'nonempty'}, '', 'Device Address');
                validateattributes(obj.DeviceUsernameText.Text,{'char'}, {'nonempty'}, '', 'Device Username');
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectForCustomiztionWhatToConsider').getString;
                % Clear the Icon before disabling the screen
                obj.StatusTable.Steps = {message('raspi:hwsetup:ConnectForCustomiztionPingStatus').getString;...
                    message('raspi:hwsetup:ConnectForCustomiztionSSHStatus').getString;...
                    message('raspi:hwsetup:ConnectForCustomiztionSudoStatus').getString;...
                    message('raspi:hwsetup:ConnectForCustomiztionInternetStatus').getString};
                obj.StatusTable.Status(:) = {''};
                
                obj.disableScreen({'DeviceInfoTable', 'StatusTable', 'CancelButton'});
                restoreOnCleanup = onCleanup(@obj.restoreScreen);
                
                % Get the board parameters
                address = obj.DeviceAddressText.Text;
                username = obj.DeviceUsernameText.Text;
                password = obj.DevicePasswordText.Text;
                
                
                % Attempt to connect to the Raspberry Pi Board
                isConnected = false;
                obj.StatusTable.Status(1) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Busy};
                obj.StatusTable.Steps(1) = {message('raspi:hwsetup:ConnectForCustomiztionPing',address).getString};
                %Ping the hardware to know if the device address provided
                %is reachable
                pingSuccess = pingHardware(obj, address);
                if ~pingSuccess
                    %If ping fails, the IP address provided is not
                    %reachable. Display the corresponding message and set
                    %the corresponding state of the status.
                    obj.StatusTable.Steps(1) = {message('raspi:hwsetup:ConnectForCustomiztionPingFail').getString};
                    obj.StatusTable.Status(1)= {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                    obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectForCustomiztionPingFailDesc').getString;
                else
                    %If the ping is successful, verify that an SSH
                    %connection can be created between the hardware and the
                    %host machine.
                    %Set the state of Ping status
                    obj.StatusTable.Steps(1) = {message('raspi:hwsetup:ConnectForCustomiztionPingPass').getString};
                    obj.StatusTable.Status(1) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                    obj.StatusTable.Status(2) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Busy};
                    obj.StatusTable.Steps(2) = {message('raspi:hwsetup:ConnectForCustomiztionSSH',address).getString};
                    isConnected = obj.Workflow.HardwareInterface.testSSHConnection(address,username,password);
                    if ~isConnected
                        %If the SSH connection is not established, then the
                        %Login credentials are incorrect or SSH is disabled
                        %on Raspberry Pi. Display the corresponding address
                        %and the state.
                        obj.StatusTable.Steps(2) = {message('raspi:hwsetup:ConnectForCustomiztionSSHFail').getString};
                        obj.StatusTable.Status(2) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                        obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectForCustomiztionSSHFailDesc').getString;
                    else
                        %If an SSH connection is successfully established,
                        %Validate if the username provided has sudo previlige.
                        obj.StatusTable.Steps(2) = {message('raspi:hwsetup:ConnectForCustomiztionSSHPass').getString};
                        obj.StatusTable.Status(2) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                        obj.StatusTable.Status(3) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Busy};
                        obj.StatusTable.Steps(3) = {message('raspi:hwsetup:ConnectForCustomiztionSudo').getString};
                        raspiObj = raspi.internal.hwsetup.Raspbian(address,username,password);
                        installobj = matlabshared.internal.SharedLinuxCustomizer(raspiObj);
                        if ~isUserASudoer(installobj)
                            %if isUserASudoer is false, the user does not
                            %have sudoer permission. We will error out here
                            %and will discontinue the customization
                            %process.
                            obj.StatusTable.Steps(3) = {message('raspi:hwsetup:ConnectForCustomiztionSudoFail').getString};
                            obj.StatusTable.Status(3) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                            obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectForCustomiztionSudoFailDesc').getString;
                        else
                            %check if the hardware has internet access.
                            %Internet access is required to download and
                            %install all the packages and libraries.
                            obj.StatusTable.Steps(3) = {message('raspi:hwsetup:ConnectForCustomiztionSudoPass').getString};
                            obj.StatusTable.Status(3) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                            obj.StatusTable.Status(4) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Busy};
                            obj.StatusTable.Steps(4) = {message('raspi:hwsetup:ConnectForCustomiztionInternet').getString};                            
                            if ~internetConnectionAvailable(installobj)
                                %If there is no internet access on the
                                %hardware, the customization process cannot
                                %continue. Display the corresponding message
                                %and update the status.
                                obj.StatusTable.Steps(4) = {message('raspi:hwsetup:ConnectForCustomiztionInternetFail').getString};
                                obj.StatusTable.Status(4) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                                obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConnectForCustomiztionInternetFailDesc').getString;
                            else
                                %If the ping verification, SSH verification and
                                %Internet access verification are all
                                %sucessful, update the status and assign the
                                %login credentials to the respective workflow
                                %class properties.
                                obj.StatusTable.Steps(4) = {message('raspi:hwsetup:ConnectForCustomiztionInternetPass').getString};
                                obj.StatusTable.Status(4) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass};
                                obj.Workflow.CustomDeviceAddress = address;
                                obj.Workflow.CustomDeviceUSRName = username;
                                obj.Workflow.CustomDevicePsswd = password;
                                %Through the SSH session find the HostName of
                                %the hardware. HostName would be used in the
                                %subsequent steps of customization.
                                ssh =  matlabshared.internal.ssh2client(address,username,password);
                                hostname = ssh.execute('hostname');
                                obj.Workflow.CustomDeviceHostName = hostname;
                            end
                        end
                    end
                end
                % update the connectionSucess property
                obj.connectionSuccess = isConnected;
                
            end
            
            %Enable the NextButton only when Test Connection results in a
            %success
            if obj.connectionSuccess
                obj.NextButton.Enable = 'on';
            else
                obj.NextButton.Enable = 'off';
            end
        end
        
        function success = pingHardware(~,ipaddr)
            success = false;
            arch = computer('arch');
            switch (arch)
                case {'win32','win64'}
                    pingcmd = ['ping -n 3 ' ipaddr];
                case {'glnxa64','maci64'}
                    pingcmd = ['ping -c 3 ' ipaddr];
                otherwise
                    error('Ping failed');
            end
            [st,msg] = system(pingcmd);
            if (st == 0) && ~isempty(regexpi(msg, '\sTTL='))
                success = true;
            end
        end
    end
end