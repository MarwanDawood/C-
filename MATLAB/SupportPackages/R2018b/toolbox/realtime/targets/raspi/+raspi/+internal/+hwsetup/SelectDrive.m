classdef SelectDrive < matlab.hwmgr.internal.hwsetup.DeviceDetection
    % SelectDrive - Screen implementation to enable users to detect SD Card
    % for writing firmware
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    
    properties
        % no properties
    end
    
    methods
        function obj = SelectDrive(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.DeviceDetection(varargin{:});
            
            % Set the Title Text
            obj.Title.Text = obj.getTitleText();
            
            % Set the Description
            obj.Description.Text = obj.getDescriptionText();
            
            % Set the selection label for DropDown eg: drive
            obj.SelectionLabel.Text = obj.getSelectionLabelText();
            
            % Set DropDown items
            obj.SelectionDropDown.Items = obj.Workflow.DriveList;
            obj.SelectionDropDown.ValueChangedFcn = @obj.changeDrive;
            obj.Workflow.Drive = obj.SelectionDropDown.Items{1}; % default pick the first item
            
            % Set position for Label, DropDown and Refresh button
            obj.SelectionLabel.shiftVertically(-10);
            obj.SelectionDropDown.shiftVertically(-10);
            obj.RefreshButton.shiftVertically(-10);
            obj.Description.addHeight(5);
            if isunix
                if ismac
                    % Re-arrange widgets for mac
                    obj.SelectionDropDown.addWidth(95);
                    obj.RefreshButton.shiftHorizontally(90);
                else
                    obj.SelectionDropDown.shiftHorizontally(25);
                    obj.SelectionDropDown.addWidth(50);
                    obj.RefreshButton.shiftHorizontally(75);
                    obj.RefreshButton.shiftVertically(-10);
                    obj.RefreshButton.addWidth(15);
                    obj.RefreshButton.addHeight(10);
                end
            end
            
            % Increase the Height and Width of the Image before setting the
            % ImageFile
            obj.ConnectionImage.Position = [20 20 450 240]; % size of original image 450x240
            
            % Set the ImageFile
            obj.ConnectionImage.ImageFile = fullfile(obj.Workflow.ResourcesDir,...
                'selectdrive', obj.getConnectionDiagram(obj.Workflow.BoardName));
            
            % Set the HelpText
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:SelectDriveWhatToConsider').getString;
            obj.HelpText.AboutSelection = '';
            obj.HelpText.Additional = ['<br>',...
                message('raspi:hwsetup:Note').getString, ...
                message('raspi:hwsetup:SelectDriveAdditional').getString];
            
            % Set callback
            obj.RefreshButton.ButtonPushedFcn = @obj.RefreshDropDown;
            
            %  Make next button non selectable if select drive is empty
            obj.showHideNextButton();
        end
        
        function changeDrive(obj, ~, ~)
            obj.Workflow.Drive = obj.SelectionDropDown.Value;
        end
        
        function showHideNextButton(obj)
            % Disable Next button if SD card not detected
            if numel(obj.SelectionDropDown.Items) == 1 ...
                    && isempty(obj.SelectionDropDown.Items{1})
                obj.NextButton.Enable = 'off';
            else
                obj.NextButton.Enable = 'on';
            end
        end
        
        function reinit(obj)
            % Call to getDriveList
            [~, drivelist] = obj.Workflow.HardwareInterface.getDriveList();
            obj.SelectionDropDown.Items = drivelist; % Update the drop-down
            out = ismember(drivelist, obj.Workflow.Drive);
            index = find(out);

            if ~isempty(index)
            % Set DropDown pointing to selected drive                
                obj.SelectionDropDown.ValueIndex  = index;
            else
                obj.Workflow.DriveList = drivelist;
                obj.Workflow.Drive = obj.SelectionDropDown.Items{1};
            end
            
            % Set the Description
            obj.Description.Text = obj.getDescriptionText();
            
            % Set the ImageFile
            obj.ConnectionImage.ImageFile = fullfile(obj.Workflow.ResourcesDir,...
                'selectdrive', obj.getConnectionDiagram(obj.Workflow.BoardName));
            
            %  Make next button non selectable if select drive is empty
            obj.showHideNextButton();
        end
        
        function out = getPreviousScreenID(obj)
            if strcmp(obj.Workflow.BoardName,message('raspi:hwsetup:RaspberryPiZeroW').getString)
                out = 'raspi.internal.hwsetup.ValidateRaspbian';
            else
                switch obj.Workflow.NetworkConfiguration
                    case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem2').getString
                        out = 'raspi.internal.hwsetup.WirelessConfig';
                    case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem4').getString
                        out = 'raspi.internal.hwsetup.ManualNetworkConfiguration';
                    case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem5').getString
                        out = 'raspi.internal.hwsetup.SelectLinuxImage';
                    otherwise
                        out = 'raspi.internal.hwsetup.SelectNetwork';
                end
            end
        end
            
        function out = getNextScreenID(obj)
            % Check SD card write premissions and move to next screen.
            obj.Workflow.HardwareInterface.setDrive(obj.Workflow.Drive);
            obj.Workflow.HardwareInterface.checkWritePremission();
            out = 'raspi.internal.hwsetup.WriteFirmware';
        end
        
        function RefreshDropDown(obj, ~, ~)
            % Trigger the command to start writing Firmware on the SD Card
            % Disable the HW Setup Screen
            obj.disableScreen();
            enableScreen = onCleanup(@()obj.customenableScreen); % re-enable on cleanup
            [~, drivelist] = obj.Workflow.HardwareInterface.getDriveList();
            obj.SelectionDropDown.Items = drivelist;
            obj.Workflow.DriveList = obj.SelectionDropDown.Items;
            obj.Workflow.Drive = obj.SelectionDropDown.Items{1};
        end
        
        function customenableScreen(obj)
            % Call parent enableScreen method that, enables all widgets in
            % the screen
            obj.enableScreen();
            %  Make next button non selectable if select drive is empty
            obj.showHideNextButton();
        end
        
        function out = getDescriptionText(obj)
            board = obj.Workflow.BoardName;
            memorycardtype = obj.getMemoryCardType(board);
            if ~ismac
                % Windows and Linux
                out = message('raspi:hwsetup:SelectDriveDescription', memorycardtype).getString;
            else% Mac
                out = message('raspi:hwsetup:SelectVolumeDescription', memorycardtype).getString;
            end
        end
        
    end% end methods
    
    methods(Static)
        function out = getConnectionDiagram(board)
            if strcmp(board, 'Raspberry Pi Model B') % old raspi
                if ~ismac
                    % Windows and Linux
                    out = 'insert_sd_card.png';
                else
                    % for Mac
                    out = 'insert_sd_card_mac.png';
                end
            else
                if ~ismac
                    % Windows and Linux
                    out = 'insert_microsd_card.png';
                else
                    % Mac
                    out = 'insert_microsd_card_mac.png';
                end
            end
        end
        
        function out = getTitleText()
            if ~ismac
                % Windows and Linux
                out = message('raspi:hwsetup:SelectDriveTitle').getString;
            else% Mac
                out = message('raspi:hwsetup:SelectVolumeTitle').getString;
            end
        end
        
        function out = getSelectionLabelText()
            if ~ismac
                % Windows and Linux
                out = message('raspi:hwsetup:SelectDriveLabel').getString;
            else% Mac
                out = message('raspi:hwsetup:SelectVolumeLabel').getString;
            end
        end
        
        function out = getMemoryCardType(board)
            if strcmp(board, 'Raspberry Pi Model B') % old raspi
                out = 'SD';
            else
                out = 'MicroSD';
            end
        end
    end % end static methods
    
end% end class
