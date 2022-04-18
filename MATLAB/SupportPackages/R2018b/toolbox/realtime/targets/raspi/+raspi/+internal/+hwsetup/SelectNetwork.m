classdef SelectNetwork < matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup
    % SelectNetwork - Screen implementation to enable users to choose
    % network configuration
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    
    properties
        % ImageFiles - Cell array of full paths to the image files. The
        % number of elements in ImageFiles should be equal to the number of
        % items in the pop-up menu (cell)
        ImageFiles = {};
        % HelpForSelection - Cell array strings/character-vectors for
        % providing more information about the selected item. This will be
        % rendered in the "About Your Selection" section in the HelpText
        % panel
        HelpForSelection = {};
        % HelpForWhatToConsider - Cell array strings/character-vectors for
        % providing more information about the selected item. This will be
        % rendered in the "What To Consider" section in the HelpText
        % panel
        HelpForWhatToConsider = {};
        image2;
    end
    
    methods
        function obj = SelectNetwork(varargin)
            % call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup(varargin{:});
            
            % Set Title
            obj.Title.Text = message('raspi:hwsetup:SelectNetworkTitle').getString;
            % Removed the Description text area
            obj.Description.Text = '';
            
            % Set SelectionRadioGroup Properties
            obj.SelectionRadioGroup.Title = message('raspi:hwsetup:SelectNetworkSelectionRadioGroupTitle').getString;
            obj.SelectionRadioGroup.Items = obj.getNetworkSelectionItems();
            % set callback
            obj.SelectionRadioGroup.SelectionChangedFcn = @obj.changeImage;
            %Position = [left bottom width height]
            obj.SelectionRadioGroup.Position = [20 250 1000 130];
            
            % Set SelectedImage Properties
            obj.SelectedImage.addWidth(-80);
            obj.SelectedImage.addHeight(10);
            
            % Set the default HelpText messages
            obj.HelpText.AboutSelection = message('raspi:hwsetup:SelectNetworkLANAboutSelection').getString;
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:SelectNetworkLANWhatToConsider').getString;
            
            % Set the HelpForSelection property to update the HelpText
            % when the Item in the DropDown changes
            if ispc || ismac
                obj.HelpForSelection = {message('raspi:hwsetup:SelectNetworkLANAboutSelection').getString,...
                    message('raspi:hwsetup:SelectConnectWirelessAboutSelection').getString,...
                    message('raspi:hwsetup:SelectNetworkDirectAboutSelection').getString,...
                    message('raspi:hwsetup:SelectNetworkManualAboutSelection').getString};
            else
                % No direct connection option for Linux
                obj.HelpForSelection = {message('raspi:hwsetup:SelectNetworkLANAboutSelection').getString,...
                    message('raspi:hwsetup:SelectConnectWirelessAboutSelection').getString,...
                    message('raspi:hwsetup:SelectNetworkManualAboutSelection').getString};
            end
           
            % Set the HelpForSelection property to update the HelpText
            % when the Item in the DropDown changes
            if ispc || ismac
                obj.HelpForWhatToConsider = {message('raspi:hwsetup:SelectNetworkLANWhatToConsider').getString,...
                    message('raspi:hwsetup:SelectConnectWirelessWhatToConsider').getString,...
                    message('raspi:hwsetup:SelectNetworkDirectWhatToConsider').getString,...
                    message('raspi:hwsetup:SelectNetworkManualWhatToConsider').getString};
            else
                % No direct connection option for Linux
                obj.HelpForWhatToConsider = {message('raspi:hwsetup:SelectNetworkLANWhatToConsider').getString,...
                    message('raspi:hwsetup:SelectConnectWirelessWhatToConsider').getString,...
                    message('raspi:hwsetup:SelectNetworkManualWhatToConsider').getString};
            end
            
            % Set the ImageFiles property to update the SelectedImage
            % when the Item in the DropDown changes
            imgDir = obj.Workflow.HardwareInterface.getImageDir(obj.Workflow, 'selectnetwork');
            obj.ImageFiles = {...
                fullfile(imgDir, 'raspberrypi_modelb_lan.png'),...
                fullfile(imgDir, 'raspberrypi_modelb_home_network.png'),...
                fullfile(imgDir, 'raspberrypi_modelb_wlan.png'),...  
                fullfile(imgDir, 'raspberrypi_modelb_direct_connection.png'),...
                fullfile(imgDir, 'raspberrypi_modelb+_lan.png'),...
                fullfile(imgDir, 'raspberrypi_modelb+_home_network.png'),...
                fullfile(imgDir, 'raspberrypi_modelb+_wlan.png'),...  
                fullfile(imgDir, 'raspberrypi_modelb+_direct_connection.png')};
            
            if obj.Workflow.NetworkConfigChoice == raspi.internal.hwsetup.NetworkConfigurationChoiceEnum.LocalorHome
                obj.image2 = matlab.hwmgr.internal.hwsetup.Image.getInstance(obj.ContentPanel);
                obj.image2.addWidth(5);
                obj.image2.addHeight(10);
                obj.image2.shiftHorizontally(125);
                obj.image2.shiftVertically(-58);
                obj.image2.Tag = 'setHomeConnection';
            end
            % set default images corresponding to local or home network.
            obj.setLocalorHomeNetworkImage();
            
            % get default board name (host name)
            obj.Workflow.HostName = obj.getDefaultBoardName();
            
        end
        
        function reinit(obj)
            %obj.SelectionRadioGroup.Items = obj.getNetworkSelectionItems();
            
            switch obj.Workflow.NetworkConfiguration
                case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem1').getString
                    % LAN or home network
                    obj.image2.Visible = 'on';
                    obj.setLocalorHomeNetworkImage();
                case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem2').getString
                    % Wireless
                    obj.setWirelessNetworkImage();
                case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem3').getString
                    % Direct connection
                    obj.setDirectNetworkImage();
                case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem4').getString
                    % Manual 
                    obj.setManualNetworkImage();
                otherwise
                    obj.setManualNetworkImage();
            end
        end
        
        function out = getNextScreenID(obj)
            [~, drives] = obj.Workflow.HardwareInterface.getDriveList();
            % call for getDiveList, even if next screen is manual configuration.
            % This will avoid calling getDriveList again from the manual config
            % screen.
            obj.Workflow.DriveList = drives;
            % set the wpa_supplicantText
            if obj.Workflow.NetworkConfigChoice ~= raspi.internal.hwsetup.NetworkConfigurationChoiceEnum.Wireless
                obj.Workflow.HardwareInterface.setWirelessDetails(obj.Workflow);
            end
            
            if obj.Workflow.NetworkConfigChoice  == raspi.internal.hwsetup.NetworkConfigurationChoiceEnum.Wireless
                out = 'raspi.internal.hwsetup.WirelessConfig';
            elseif obj.Workflow.NetworkConfigChoice  == raspi.internal.hwsetup.NetworkConfigurationChoiceEnum.Manual
                out = 'raspi.internal.hwsetup.ManualNetworkConfiguration';
            else 
                
                out = 'raspi.internal.hwsetup.SelectDrive';
                if isunix
                    if ~ismac
                        if obj.Workflow.NetworkConfigChoice  == raspi.internal.hwsetup.NetworkConfigurationChoiceEnum.Direct
                            % In Linux, Enum for Manual config is 2 since
                            % there is no direct connection.
                            out = 'raspi.internal.hwsetup.ManualNetworkConfiguration';
                        end
                    end
                end
            end
        end
        
        function out = getPreviousScreenID(obj) %#ok<MANU>
            out = 'raspi.internal.hwsetup.ValidateRaspbian';
        end
        
        function set.ImageFiles(obj, files)
            % ImageFiles property should be specified as a cell array of
            % strings or character vectors
            assert(iscellstr(files), 'ImageFiles property should be specified as a cell array of strings or character vectors');
            obj.ImageFiles = files;
        end
        
        function set.HelpForSelection(obj, helptext)
            % HelpForSelection property should be specified as a cell array of
            % strings or character vectors
            assert(iscellstr(helptext), 'HelpForSelection property should be specified as a cell array of strings or character vectors');
            obj.HelpForSelection = helptext;
        end
        
        function set.HelpForWhatToConsider(obj, helptext)
            % HelpForWhatToConsider property should be specified as a cell array of
            % strings or character vectors
            assert(iscellstr(helptext), 'HelpForWhatToConsider property should be specified as a cell array of strings or character vectors');
            obj.HelpForWhatToConsider = helptext;
        end
    end
    
    methods(Access = protected)
        function changeImage(obj, ~, ~)
            % CHANGEIMAGE - Callback for the DropDown that changes the
            % image file based on the index of the selected item in the
            % DropDown
            
            % Save the selected Board to the Workflow class - Not sure we
            % are going to use this, since we depend on NetworkConfiguration choice
            % (enum value). This comment can be deleted after confirmation
            obj.Workflow.NetworkConfiguration = obj.SelectionRadioGroup.Value;
            
            obj.Workflow.NetworkConfigChoice = obj.SelectionRadioGroup.ValueIndex - 1;
            obj.Workflow.ConfigWLAN = 0; % default value
            
            if ~isempty(obj.ImageFiles)
                if obj.SelectionRadioGroup.ValueIndex <= numel(obj.ImageFiles)
                    % If the ImageFiles array has been specified and the items
                    % in the array are greater than or equal to the index of
                    % the selected item, assign the SelectedImage property
                    switch obj.Workflow.NetworkConfiguration
                        case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem1').getString
                            % lan or home network
                            obj.Workflow.DhcpChoice = 0;% use DHCP
                            obj.setLocalorHomeNetworkImage();
                        case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem2').getString
                            % wireless
                            obj.setWirelessNetworkImage();
                            obj.Workflow.ConfigWLAN = 1;                            
                        case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem3').getString
                            % Direct connection
                            obj.Workflow.DhcpChoice = 1;% static IP
                            obj.setDirectNetworkImage();
                        case message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem4').getString
                            % Manual settings
                            obj.setManualNetworkImage();
                        otherwise
                            %display manual network image
                            obj.setManualNetworkImage();
                    end
                else
                    obj.SelectedImage.ImageFile = '';
                end
            end
            
            if ~isempty(obj.HelpForSelection)
                if  obj.SelectionRadioGroup.ValueIndex <= numel(obj.HelpForSelection)
                    % If the HelpForSelection has been specified and the items
                    % in the array are greater than or equal to the index of
                    % the selected item, assign the HelpText property
                    obj.HelpText.AboutSelection = ...
                        obj.HelpForSelection{obj.SelectionRadioGroup.ValueIndex};
                else
                    obj.HelpText.AboutSelection = '';
                end
            end
            
            if ~isempty(obj.HelpForWhatToConsider)
                if  obj.SelectionRadioGroup.ValueIndex <= numel(obj.HelpForWhatToConsider)
                    % If the HelpForWhatToConsider has been specified and the items
                    % in the array are greater than or equal to the index of
                    % the selected item, assign the HelpText property
                    obj.HelpText.WhatToConsider = ...
                        obj.HelpForWhatToConsider{obj.SelectionRadioGroup.ValueIndex};
                else
                    obj.HelpText.WhatToConsider = '';
                end
            end
        end
        
        function setLocalorHomeNetworkImage(obj)
            % Set SelectedImage Properties
            obj.SelectedImage.Position = [10 100 230 150]; % setting 1 of 2 image with same H and W
            obj.SelectedImage.Visible = 'on';
            %obj.SelectionRadioGroup.ValueIndex = 1;
            obj.image2.Visible = 'on';
            obj.image2.Position = [240 100 230 150]; % setting 2 of 2 image with same H and W
            
            if strcmp(obj.Workflow.BoardName, 'Raspberry Pi Model B')
                obj.SelectedImage.ImageFile = obj.ImageFiles{obj.SelectionRadioGroup.ValueIndex};
                obj.image2.ImageFile = obj.ImageFiles{obj.SelectionRadioGroup.ValueIndex + 1};
            else
                obj.SelectedImage.ImageFile = obj.ImageFiles{4 + obj.SelectionRadioGroup.ValueIndex};
                obj.image2.ImageFile = obj.ImageFiles{4 + obj.SelectionRadioGroup.ValueIndex + 1};
            end
        end
        
        function setWirelessNetworkImage(obj)
            % Set Wireless connection image
            obj.SelectedImage.Position = [20 50 400 240];
            obj.SelectedImage.shiftVertically(-15);
            obj.SelectedImage.Visible = 'on';
            obj.image2.ImageFile = '';
            
            %Change ImageFiles{} if user changed the board
            imgDir = obj.Workflow.HardwareInterface.getImageDir(obj.Workflow, 'selectnetwork');
            if strcmp(obj.Workflow.BoardName, 'Raspberry Pi 3 Model B') || strcmp(obj.Workflow.BoardName, 'Raspberry Pi 3 Model B+')
                obj.ImageFiles{7} = fullfile(imgDir, 'raspberrypi3_modelb+_wlan.png');
            else
                obj.ImageFiles{7} = fullfile(imgDir, 'raspberrypi_modelb+_wlan.png');
            end
            
            if strcmp(obj.Workflow.BoardName, 'Raspberry Pi Model B')
                obj.SelectedImage.ImageFile = obj.ImageFiles{obj.SelectionRadioGroup.ValueIndex + 1};
            else
                obj.SelectedImage.ImageFile = obj.ImageFiles{4 + obj.SelectionRadioGroup.ValueIndex + 1};
            end
            
        end
        
        function setDirectNetworkImage(obj)
            % Set SelectedImage Properties
            obj.SelectedImage.Position = [20 100 380 180]; % Only 1 image for Direct Network
            obj.SelectedImage.shiftVertically(-15);
            obj.SelectedImage.Visible = 'on';
            obj.image2.ImageFile = '';
            
            if strcmp(obj.Workflow.BoardName, 'Raspberry Pi Model B')
                obj.SelectedImage.ImageFile = obj.ImageFiles{obj.SelectionRadioGroup.ValueIndex + 1};
            else
                obj.SelectedImage.ImageFile = obj.ImageFiles{4 + obj.SelectionRadioGroup.ValueIndex + 1};
            end
        end
        
        function setManualNetworkImage(obj)
            obj.image2.ImageFile = '';
            obj.SelectedImage.ImageFile = '';
        end
        
    end% end protected methods
    
    methods(Static)
        function out = getNetworkSelectionItems()
            if ispc || ismac
                out = {message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem1').getString, ...
                    message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem2').getString, ...
                    message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem3').getString, ...
                    message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem4').getString};
            else % for Linux there is no direct connection option
                out = {message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem1').getString, ...
                    message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem2').getString, ...
                    message('raspi:hwsetup:SelectNetworkSelectionRadioGroupItem4').getString};
            end
        end
        
        % Returns a unique default hostname to be assigned to the board
        function boardName = getDefaultBoardName()
            symbols = ['a':'z' 'A':'Z' '0':'9'];
            rng('shuffle');
            nums = randi(numel(symbols), [1 10]);% Random name length = 10
            randomName = symbols(nums);
            boardName = ['raspberrypi-', randomName];
        end
    end% end static methods
    
end
