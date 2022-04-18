classdef SelectBoard < matlab.hwmgr.internal.hwsetup.SelectionWithDropDown
    % SelectBoard - Screen implementation to enable users to select the
    % Raspberry Pi board.
    
    %   Copyright 2016-2017 The MathWorks, Inc.
    
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
    end
    
    methods
        function obj = SelectBoard(varargin)
            % call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithDropDown(varargin{:});
            
            % Set the Title Text
            obj.Title.Text = message('raspi:hwsetup:SelectBoardTitle').getString;
            
            % Set the Dropdown Items
            obj.SelectionDropDown.Items = {message('raspi:hwsetup:RaspberryPi3ModelBPlus').getString,...
                message('raspi:hwsetup:RaspberryPi3ModelB').getString,...
                message('raspi:hwsetup:RaspberryPi2ModelB').getString,...
                message('raspi:hwsetup:RaspberryPiZeroW').getString,...
                message('raspi:hwsetup:RaspberryPiModelBPlus').getString,...
                message('raspi:hwsetup:RaspberryPiModelB').getString,...
                };
            
            % Select the first entry in DropDown - Raspberry Pi 3 Model B
            obj.SelectionDropDown.ValueIndex = 1;
            obj.Workflow.BoardName = obj.SelectionDropDown.Value;
            
            obj.SelectionDropDown.ValueChangedFcn = @obj.changeImage;
            
            % Set the Label text
            obj.SelectionLabel.Text = message('raspi:hwsetup:SelectBoardLabel').getString;
            
            % Removed the Description text area
            obj.Description.Text = '';
            
            % Set the What To Consider section of the HelpText
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:SelectBoardWhatToConsider').getString;
            
            imgDir = obj.Workflow.HardwareInterface.getImageDir(obj.Workflow, 'selectboard');
            % Set the default Image to be displayed for Raspberry Pi 3 B +
            obj.SelectedImage.ImageFile = fullfile(imgDir, 'raspberrypi_3_model_b_plus.png');
            % Set the default About Selection HelpText for Raspberry Pi 3 Model B
            obj.HelpText.AboutSelection = message('raspi:hwsetup:RaspberryPiThreeBPlusInfo').getString;
            
            % Set the HelpForSelection property to update the HelpText
            % when the Item in the DropDown changes
            obj.HelpForSelection = {message('raspi:hwsetup:RaspberryPiThreeBPlusInfo').getString,...
                message('raspi:hwsetup:RaspberryPiThreeBInfo').getString,...
                message('raspi:hwsetup:RaspberryPiTwoBInfo').getString,...
                message('raspi:hwsetup:RaspberryPiZeroWInfo').getString,...
                message('raspi:hwsetup:RaspberryPiBPlusInfo').getString,...
                message('raspi:hwsetup:RaspberryPiBInfo').getString,...
                };
            
            % Set the ImageFiles property to update the SelectedImage
            % when the Item in the DropDown changes
            obj.ImageFiles = {...
                fullfile(imgDir, 'raspberrypi_3_model_b_plus.png'),...
                fullfile(imgDir, 'raspberrypi_3_model_b.png'),...
                fullfile(imgDir, 'raspberrypi_2_model_b.png'),...
                fullfile(imgDir, 'raspberrypi_0_w.png'),...
                fullfile(imgDir, 'raspberrypi_model_b+.png'),...
                fullfile(imgDir, 'raspberrypi_model_b.png'),...
                };
            
            % Align the widgets
            obj.SelectionLabel.shiftVertically(40);
            obj.SelectedImage.shiftVertically(60);
            p = obj.SelectedImage.Position;
            obj.SelectedImage.Position = [20 p(2) 360 240];
            if ispc
                obj.SelectionDropDown.shiftVertically(45);
                obj.SelectionDropDown.addWidth(-30);
                obj.SelectionDropDown.shiftHorizontally(15);
                
            else
                if ismac
                    obj.SelectionDropDown.shiftVertically(40);
                    obj.SelectionDropDown.addWidth(-10);
                    obj.SelectionDropDown.shiftHorizontally(5);
                else
                    obj.SelectionDropDown.shiftVertically(45);
                    obj.SelectionDropDown.shiftHorizontally(30);
                    obj.SelectionLabel.addWidth(20);
                    obj.SelectionDropDown.addWidth(-10);
                end
            end
            
            % get default board name (host name)
            obj.Workflow.HostName = obj.getDefaultBoardName();
            
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
        
        function changeImage(obj, ~, ~)
            % CHANGEIMAGE - Callback for the DropDown that changes the
            % image file based on the index of the selected item in the
            % dropdown
            
            % Save the selected Board to the Workflow class
            obj.Workflow.BoardName = obj.SelectionDropDown.Value;
            obj.Workflow.HardwareInterface.setUSBInterfaceDetails(obj.Workflow.BoardName);
            if ~isempty(obj.ImageFiles)
                if obj.SelectionDropDown.ValueIndex <= numel(obj.ImageFiles)
                    % If the ImageFiles array has been specified and the items
                    % in the array are greater than or equal to the index of
                    % the selected item, assign the SelectedImage property
                    obj.SelectedImage.ImageFile = ...
                        obj.ImageFiles{obj.SelectionDropDown.ValueIndex};
                else
                    obj.SelectedImage.ImageFile = '';
                end
            end
            
            if ~isempty(obj.HelpForSelection)
                if  obj.SelectionDropDown.ValueIndex <= numel(obj.HelpForSelection)
                    % If the HelpForSelection has been specified and the items
                    % in the array are greater than or equal to the index of
                    % the selected item, assign the HelpText property
                    obj.HelpText.AboutSelection = ...
                        obj.HelpForSelection{obj.SelectionDropDown.ValueIndex};
                else
                    obj.HelpText.AboutSelection = '';
                end
            end
        end
        
        function out = getNextScreenID(obj)%#ok<MANU>
            out = 'raspi.internal.hwsetup.SelectLinuxImage';
        end
    end
    
    methods(Static)
        
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