classdef SelectLinuxImage < matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup
    %   SelectedImage - Screen provides an option to choose the Linux OS to be setup on Raspberry Pi
    %   Copyright 2017-2018 The MathWorks, Inc.

    properties (Access=private)
        AboutText
    end
    
    methods
        function obj = SelectLinuxImage(varargin)
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup(varargin{:});
            obj.Title.Text = message('raspi:hwsetup:SelectLinuxImageTitle').getString;
            obj.Description.Text = message('raspi:hwsetup:SelectLinuxImageDesc').getString;
            obj.Description.Position = [20 250 430 100];
            obj.Description.addHeight(20);
            % Set the Drop-down Items
            obj.SelectionRadioGroup.Title = message('raspi:hwsetup:SelectLinuxImageRadioTitle').getString;
            obj.SelectionRadioGroup.Items = {message('raspi:hwsetup:SelectLinuxImageSel_1').getString,...
                message('raspi:hwsetup:SelectLinuxImageSel_2').getString};
            obj.SelectionRadioGroup.Position = [20 230 1000 80];
            obj.HelpText.AboutSelection = message('raspi:hwsetup:SelectLinuxImageAbtSel_1').getString;
            
            if strcmp(varargin{:}.BoardName,message('raspi:hwsetup:RaspberryPiZeroW').getString)
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:CustomSetupWhatToConsider_1_ZeroW').getString;
            else
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:CustomSetupWhatToConsider_1').getString;
            end
            
            obj.SelectionRadioGroup.SelectionChangedFcn = @obj.selectWorkflow;
            obj.SelectedImage.ImageFile = '';
        end
        
        function out = getPreviousScreenID(~)
            out = 'raspi.internal.hwsetup.SelectBoard';
        end
        
        function selectWorkflow(obj, ~, ~)
            if obj.SelectionRadioGroup.ValueIndex == 1
                % Use MathWorks Default Image
                obj.HelpText.AboutSelection = message('raspi:hwsetup:SelectLinuxImageAbtSel_1').getString;
                if strcmp(obj.Workflow.BoardName,message('raspi:hwsetup:RaspberryPiZeroW').getString)
                    obj.HelpText.WhatToConsider = message('raspi:hwsetup:CustomSetupWhatToConsider_1_ZeroW').getString;
                else
                    obj.HelpText.WhatToConsider = message('raspi:hwsetup:CustomSetupWhatToConsider_1').getString;
                end
            else
                % Customize Linux image
                obj.HelpText.AboutSelection = message('raspi:hwsetup:SelectLinuxImageAbtSel_2').getString;
                obj.HelpText.WhatToConsider = message('raspi:hwsetup:CustomSetupWhatToConsider_2').getString;
            end
        end
        
        function out = getNextScreenID(obj)
            % If the Custom linux image is selected, the next screen would
            % point to 'Enter Login Credentials'
            if isequal(obj.SelectionRadioGroup.ValueIndex,2)
                out = 'raspi.internal.hwsetup.ConnectforCustomization';
            else
                % Download the raspbian img
                out = 'raspi.internal.hwsetup.DownloadRaspbian';
            end
        end
        
        function restoreValues(obj)
            obj.enableScreen();
        end
        
        function reinit(obj)
            % Reinit screen using the radiobutton selection
            obj.selectWorkflow;
        end
    end
    
end
