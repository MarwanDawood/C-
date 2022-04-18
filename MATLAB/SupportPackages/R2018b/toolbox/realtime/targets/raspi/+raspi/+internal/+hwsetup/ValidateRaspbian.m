classdef ValidateRaspbian <  matlab.hwmgr.internal.hwsetup.ValidateLocation
    % ValidateRaspbian - Screen implementation to enable users to validate
    % the Raspbian img
    
    %   Copyright 2017-2018 The MathWorks, Inc.
    properties
        % Button to Validate Raspbian img
        ValidateButton
        % Status Table to show the status of validation
        StatusTable
    end
    
    methods
        
        function obj = ValidateRaspbian(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ValidateLocation(varargin{:});
            
            % Change browse button callback function
            obj.BrowseButton.ButtonPushedFcn = @obj.browseFile;
            
            % Create button widget and parent it to the content panel
            obj.ValidateButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel); % Button
            obj.StatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.StatusTable.Visible = 'off';
            obj.StatusTable.Enable = 'off';
            obj.StatusTable.Status = {''};
            obj.StatusTable.Steps = {''};
            obj.StatusTable.Position = [6000 250 50 250];
            
            % Set the Title Text
            obj.Title.Text = message('raspi:setup:Validate_Raspbian').getString;
            
            obj.Description.Text = message('raspi:setup:Validate_Description').getString;
            
            % Disable Next button
            obj.NextButton.Enable = 'off';
            
            %Set ValidateButton Properties
            obj.ValidateButton.Text = message('raspi:setup:Validate_Button').getString;
            obj.ValidateButton.Position = [20 250 200 20];
            obj.ValidateButton.ButtonPushedFcn = @obj.ExtractAndValidate;
            obj.ValidateButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.ValidateButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            obj.HelpText.WhatToConsider = message('raspi:setup:ValidateRaspbianWhatToCons').getString;
            % Set the default edit text 
            obj.ValidateEditText.Text = obj.Workflow.HardwareInterface.getDefaultDownloadFldr();
            obj.ValidateEditText.ValueChangedFcn = @obj.DisableNextButton;
        end
        
        function DisableNextButton(obj,~,~)
            obj.NextButton.Enable = 'off';
            % Provide info in status table to click on vlidate img
            obj.EnableStatusTable(matlab.hwmgr.internal.hwsetup.StatusIcon.Help);
        end
        
        function EnableStatusTable(obj,status)
            % Status table properties
            obj.StatusTable.ColumnWidth = [20 30];
            obj.StatusTable.Position= [20 150 280 70];

            obj.StatusTable.Visible = 'on';
            obj.StatusTable.Enable = 'on';
            
            if strcmp(status,'Pass')
                obj.StatusTable.Steps = {message('raspi:setup:ValidateStatusPass').getString};
            elseif strcmp(status,'Fail')
                obj.StatusTable.Steps = {message('raspi:setup:ValidateStatusFail').getString};
            elseif strcmp(status,'Busy')
                obj.StatusTable.Steps = {message('raspi:setup:ValidateStatusBusy').getString};
            elseif strcmp(status,'Warn')
                obj.StatusTable.Steps = {message('raspi:setup:ValidateStatusWarn').getString};
            elseif strcmp(status,'Help')
                obj.StatusTable.Steps = {message('raspi:setup:ValidateStatusHelp').getString};
            end
            
            obj.StatusTable.Status(1:numel(obj.StatusTable.Steps)) = {status};
        end
        
        function browseFile(obj, ~, ~)
            %Disable HW setup screen and open file browser
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.customenableScreen); % re-enable on cleanup
            
            fileSpec = '';
            fileSpecStr = '*zip;*img';
            fileSpec{end+1} = fileSpecStr;
            fileSpec{end+1} = '*.zip;*.img';
            if isequal(exist(obj.ValidateEditText.Text,'dir'),7)
                userDwldDir = obj.ValidateEditText.Text;
            else
                userDwldDir = obj.Workflow.HardwareInterface.getDefaultDownloadFldr();
            end
            [filename, pathname] = uigetfile(fileSpec, 'Select the downloaded Raspbian image ',userDwldDir);
            
            if filename % If the user cancel's the file browser, uigetdir returns 0.
                % When a new location is selected, then set that location value
                % back to show it in edit text area. (ValidateEditText.Text).
                obj.ValidateEditText.Text = fullfile(pathname,filename);
            end
        end
        
        function customenableScreen(obj)
            obj.enableScreen();
            %  Disable the next button since validation is pending.
            obj.DisableNextButton();
        end
        
        function status = zipFileValidation(obj,zipFileName)
            status = obj.Workflow.HardwareInterface.checkFirmwarezip(zipFileName);
            imgStatus = false;
            if status
                %Check whether an extracted img is available
                raspbianFldr = obj.Workflow.HardwareInterface.getRaspbianFolder;
                if isequal(exist(raspbianFldr,'dir'),7)
                    % Raspbian folder is available.
                    % Check for valid image.
                    imgStatus = obj.Workflow.HardwareInterface.checkFirmwareImg(raspbianFldr);
                end
                
                if ~imgStatus
                    % Invalid or no image in the raspbian folder.
                    try
                        obj.EnableStatusTable(matlab.hwmgr.internal.hwsetup.StatusIcon.Busy);
                        obj.disableScreen();
                        unzip(zipFileName,raspbianFldr);
                        obj.enableScreen();
                        obj.NextButton.Enable = 'off';
                    catch
                        % Invalid zip file
                        warndlg(getString(message('raspi:setup:InvalidZip')));
                        status = false;
                        obj.enableScreen();
                        obj.NextButton.Enable = 'off';
                        return;
                    end
                end
                status = obj.Workflow.HardwareInterface.checkFirmwareImg(raspbianFldr);
            else
                % zip file selected is not valid
                errordlg(getString(message('raspi:setup:InvalidZip')));
            end
        end
        
        function status = imgFileValidation(obj,filePath)
            status = obj.Workflow.HardwareInterface.checkFirmwareImg(filePath);
        end
        
        function status = ExtractAndValidate(obj,~,~)
            fileName = obj.ValidateEditText.Text;
            [filePath,~,ext] = fileparts(fileName);
            status = false;
            ext = lower(ext);
            switch ext
                case '.zip'
                    status = obj.zipFileValidation(fileName);
                case '.img'
                    status = obj.imgFileValidation(filePath);
                otherwise
                    % file selected is not valid
                    errordlg(getString(message('raspi:setup:InvalidZip'))); 
            end
            
            if status
                obj.EnableStatusTable(matlab.hwmgr.internal.hwsetup.StatusIcon.Pass);
                obj.NextButton.Enable = 'on';
            else
                obj.EnableStatusTable(matlab.hwmgr.internal.hwsetup.StatusIcon.Fail);
                obj.NextButton.Enable = 'off';
            end
        end
        
        function out = getNextScreenID(obj)
            % USB Gadget/Ethernet is the default connection mode for
            % Raspberry Pi Zero W. So skip the NW settings screen
            if strcmp(obj.Workflow.BoardName,message('raspi:hwsetup:RaspberryPiZeroW').getString)
                % Set wpa_supplicant.conf to default
                obj.Workflow.HardwareInterface.setWirelessDetails(obj.Workflow);
                % Set Network configuration as USB Gadget/Ethernet
                obj.Workflow.NetworkConfiguration = message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem5').getString;
                % call for getDiveList, this will autopopulate the drive name in the next screen.
                [~, drives] = obj.Workflow.HardwareInterface.getDriveList();
                obj.Workflow.DriveList = drives;
                out = 'raspi.internal.hwsetup.SelectDrive';
            else
                out = 'raspi.internal.hwsetup.SelectNetwork';
            end
        end
        
        function out = getPreviousScreenID(obj) %#ok<*MANU>
            out = 'raspi.internal.hwsetup.DownloadRaspbian';
        end
        
        function reinit(obj)
            
        end 
    end
end
