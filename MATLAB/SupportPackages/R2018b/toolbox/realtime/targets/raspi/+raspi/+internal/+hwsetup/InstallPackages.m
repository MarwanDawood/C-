classdef InstallPackages  < matlab.hwmgr.internal.hwsetup.WriteToHardware
    % InstallPackages - Screen provides the ability to install packages and libraries on Raspberry Pi
    %   Copyright 2017-2019 The MathWorks, Inc.
    properties
        InstallSuccess = false;
        RequiredPkgs
        RequiredLibs
        failedPkgsInstalls
        failedLibInstalls
        Table_pkgs
        Table_lib
        StatusTable_pkgs
        StatusTable_libs
        Description_libs
        Description_pkgs
    end
    
    methods
        function obj = InstallPackages(varargin)
            % Call to base class constructor
            obj@matlab.hwmgr.internal.hwsetup.WriteToHardware(varargin{:});
            % Create the widgets and parent them to the content panel
            obj.Title.Text = message('raspi:hwsetup:InstallPkgsTitle').getString;
            obj.Description.Text =message('raspi:hwsetup:InstallPkgsDesc').getString ;
            obj.Description.Position = [20 300 430 80];
            
            obj.HelpText.WhatToConsider =message('raspi:hwsetup:InstallPkgsConsider').getString;
            obj.HelpText.AboutSelection = '';
            
            obj.WriteButton.Text = message('raspi:hwsetup:InstallPkgsWriteButton_Install').getString;
            obj.WriteButton.ButtonPushedFcn = @obj.installLibandPackages;
            obj.WriteButton.Position = [350 270 86 22];
            obj.WriteProgress.Position = [20 270 300 22];
            
            %Create status table to display failed package installations
            obj.Description_pkgs = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.Description_pkgs.Text = 'Installation of the following packages failed';
            obj.Description_pkgs.Position = [20 240 430 20];
            obj.Description_pkgs.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.Description_pkgs.Visible = 'off';
             
            obj.StatusTable_pkgs = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable_pkgs.Status = {''};
            obj.StatusTable_pkgs.Steps = {''};
            obj.StatusTable_pkgs.Position = [20 120 200 120];
            obj.StatusTable_pkgs.ColumnWidth = [20 180];
            obj.StatusTable_pkgs.Visible = 'off';
           
            %Create status table to display failed package installations
            obj.Description_libs = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.Description_libs.Text ='Installation of the following libraries failed' ;
            obj.Description_libs.Position = [20 80 430 20];
            obj.Description_libs.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.Description_libs.Visible = 'off';
            
            obj.StatusTable_libs = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable_libs.Status = {''};
            obj.StatusTable_libs.Steps = {''};
            obj.StatusTable_libs.Position = [20 20 200 60];
            obj.StatusTable_libs.ColumnWidth = [20 180];
            obj.StatusTable_libs.Visible = 'off';
         
            
            obj.NextButton.Enable = 'off';
        end
        
        function installLibandPackages(obj,~,~)
            obj.WriteButton.Enable = 'off';
            obj.WriteProgress.Indeterminate = true;
            restoreScr = onCleanup(@()obj.restoreValues);
            obj.WriteButton.Enable = 'off';
            obj.WriteButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.GREY;
            obj.Description_pkgs.Visible = 'off';
            obj.StatusTable_pkgs.Status = {''};
            obj.StatusTable_pkgs.Steps = {''};
            obj.StatusTable_pkgs.Visible = 'off';
            obj.Description_libs.Visible = 'off';
            obj.StatusTable_libs.Status = {''};
            obj.StatusTable_libs.Steps = {''};
            obj.StatusTable_libs.Visible = 'off';
            raspbian = raspi.internal.hwsetup.Raspbian;
            obj.RequiredPkgs = raspbian.getRequiredPackages;
            obj.RequiredLibs = raspbian.getRequiredLibraries;
            obj.InstallSuccess = false;
            obj.failedLibInstalls = [];
            obj.failedPkgsInstalls = [];
            if ~(ispref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest')&&...
                    (getpref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest') == 1))
                %Install Packages
                obj.Description.Text = [message('raspi:hwsetup:InstallPkgsDesc').getString ...
                    newline newline message('raspi:hwsetup:InstallPkgsDesc_Pkgs').getString;];
                installPkgsSuccess = obj.installPackages();
                %Install Libs
                obj.Description.Text = [message('raspi:hwsetup:InstallPkgsDesc').getString ...
                    newline newline message('raspi:hwsetup:InstallPkgsDesc_Libs').getString;];
                installLibsSuccess = obj.installLibraries();
                %Setup Hardware
                obj.Description.Text = [message('raspi:hwsetup:InstallPkgsDesc').getString ...
                    newline newline message('raspi:hwsetup:InstallPkgsDesc_setup').getString;];
                obj.setupHardware();
                
                if installPkgsSuccess && installLibsSuccess
                    obj.InstallSuccess = true;
                    obj.Description.Text = [message('raspi:hwsetup:InstallPkgsDesc').getString ...
                        newline newline message('raspi:hwsetup:InstallPkgsDesc_pass').getString;];
                else
                    obj.InstallSuccess = false;
                    obj.Description.Text = [message('raspi:hwsetup:InstallPkgsDesc').getString ...
                        newline newline message('raspi:hwsetup:InstallPkgsDesc_fail').getString;];
                end
                
            else
                obj.InstallSuccess = true;                
            end
            obj.WriteProgress.Indeterminate = false;
            if  obj.InstallSuccess
                obj.WriteProgress.Value = 100;
                obj.WriteButton.Text = message('raspi:hwsetup:InstallPkgsWriteButton_Success').getString;
            else
                obj.WriteProgress.Value = 0;
                obj.WriteButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
                obj.WriteButton.Text = message('raspi:hwsetup:InstallPkgsWriteButton_Retry').getString;
                obj.displayFailedPkgsandLibs;
            end
         
            obj.enableScreen();            
            obj.NextButton.Enable = 'on';
        end
        
        function success = installPackages(obj)
            raspiObj = raspi.internal.hwsetup.Raspbian(obj.Workflow.CustomDeviceAddress,...
                obj.Workflow.CustomDeviceUSRName, obj.Workflow.CustomDevicePsswd);
            installobj = matlabshared.internal.SharedLinuxCustomizer(raspiObj);
            connectSuccess = installobj.connectHardware();
            if ~connectSuccess
                error(message('raspi:hwsetup:InstallPkgsConnectError'));
            end
            
            %check if all packages are installed
            status = installobj.isPackageInstalled(obj.RequiredPkgs);
            if isempty(find(status==0, 1))
                success = true;
            else
                %Perform an apt-get update before commencing the Installation
                %of packages
                installobj.updateAPTcache();
                
                installSuccess = installobj.installPackages(obj.RequiredPkgs);
                if isempty(find(installSuccess==0, 1))
                    success = true;
                else
                    obj.failedPkgsInstalls = find(installSuccess==0);
                    success = false;
                end
                
            end
        end
        
        function success = installLibraries(obj)
            sshobj = matlabshared.internal.ssh2client(obj.Workflow.CustomDeviceAddress,...
                obj.Workflow.CustomDeviceUSRName, obj.Workflow.CustomDevicePsswd);
            scpobj = matlabshared.internal.scpclient(obj.Workflow.CustomDeviceAddress,...
                obj.Workflow.CustomDeviceUSRName, obj.Workflow.CustomDevicePsswd);
            obj.failedLibInstalls = zeros(1,4);
            obj.failedLibInstalls(1) = raspi.internal.firmware.setupWiringPi(sshobj,scpobj);
            userland_install_status = raspi.internal.firmware.setupUserland(sshobj,scpobj);
            userland_update_status = raspi.internal.firmware.updateUserland(sshobj,scpobj);
            obj.failedLibInstalls(2) = userland_install_status && userland_update_status;
            obj.failedLibInstalls(3) = raspi.internal.firmware.setupPigpio(sshobj,scpobj);
            obj.failedLibInstalls(4) = raspi.internal.firmware.setupMQTTPaho(sshobj,scpobj);
            if isempty(find(obj.failedLibInstalls==0, 1))
                success = true;
            else
                success = false;
            end
        end
        
        function setupHardware(obj)
            sshobj = matlabshared.internal.ssh2client(obj.Workflow.CustomDeviceAddress,...
                obj.Workflow.CustomDeviceUSRName, obj.Workflow.CustomDevicePsswd);
            scpobj = matlabshared.internal.scpclient(obj.Workflow.CustomDeviceAddress,...
                obj.Workflow.CustomDeviceUSRName, obj.Workflow.CustomDevicePsswd);
            raspi.internal.firmware.setupSshDns(sshobj,scpobj);
            raspi.internal.firmware.setupUserGroups(sshobj,scpobj);
        end
        
        function out = getPreviousScreenID(~)
            out = 'raspi.internal.hwsetup.DisplayPackageList';
        end
        
        function out = getNextScreenID(~)
            out = 'raspi.internal.hwsetup.ConfigurePeripherals';
        end
        
        function restoreValues(obj)
            obj.enableScreen();
            obj.WriteProgress.Indeterminate = false;
            if obj.InstallSuccess
                obj.WriteProgress.Value = 100;
                obj.NextButton.Enable = 'on';
                obj.WriteButton.Text = message('raspi:hwsetup:InstallPkgsWriteButton_Success').getString;
                obj.WriteButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.GREY;
            else
                obj.WriteProgress.Value = 0;
                obj.NextButton.Enable = 'on';
                obj.WriteButton.Text = message('raspi:hwsetup:InstallPkgsWriteButton_Retry').getString;
            end
        end
        
        function displayFailedPkgsandLibs(obj)
            if ~isempty(obj.failedPkgsInstalls)
                obj.Description_pkgs.Visible = 'on';
                failedPkgs = cell(1,numel(obj.failedPkgsInstalls));
                failedPkgsStatus = cell(1,numel(obj.failedPkgsInstalls));
                for i = 1:numel(obj.failedPkgsInstalls)
                    failedPkgs{i} = obj.RequiredPkgs{obj.failedPkgsInstalls(i)};
                    failedPkgsStatus(i) = {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                end
                obj.StatusTable_pkgs.Steps = failedPkgs;
                obj.StatusTable_pkgs.Status = failedPkgsStatus ;
                obj.StatusTable_pkgs.Visible = 'on';
            end
            if any(obj.failedLibInstalls==0)
                
                obj.Description_libs.Visible = 'on';
                obj.Description_libs.Position = [20 90 460 20];
                libFailures = find(obj.failedLibInstalls==0);
                failedLibs = cell(1,numel(libFailures));
                failedLibsStatus = cell(1,numel(libFailures));
                for i = 1:numel(libFailures)
                    failedLibs{i} = obj.RequiredLibs{libFailures(i)};
                    failedLibsStatus(i)= {matlab.hwmgr.internal.hwsetup.StatusIcon.Fail};
                end
                obj.StatusTable_libs.Steps = failedLibs;
                obj.StatusTable_libs.Status = failedLibsStatus;
                obj.StatusTable_libs.Visible = 'on';
                if isempty(obj.failedPkgsInstalls)
                    obj.Description_libs.Position = [20 230 430 20];
                    obj.StatusTable_libs.Position = [20 170 200 60];
                end
            end
        end
    end
end

% LocalWords:  raspi hwsetup Pkgs
