classdef CustomSetupComplete < matlab.hwmgr.internal.hwsetup.LaunchExamples
    %CustomSetupComplete This is an Raspberrypi specific implementation of a
    %Launch Examples screen. This screen will be displayed at the end of
    %the Raspberrypi Setup to give the installer an option to open the examples
    %page for Raspberrypi
    
    % Copyright 2017 The MathWorks, Inc.
    
    methods
        function obj = CustomSetupComplete(workflow)
            obj@matlab.hwmgr.internal.hwsetup.LaunchExamples(workflow);
            obj.customizeScreen();
        end
        
        function id = getPreviousScreenID(~)
            id = 'raspi.internal.hwsetup.RebootRaspi';
        end
        
        function customizeScreen(obj)
            obj.Description.Text = message('raspi:hwsetup:SetupCompleteDescription').getString;
            obj.Description.Position = [20 330 430 40];
            
            %if the LaunchCheckbox is empty then there are no examples to
            %display. Set the ShowExamples property as is appropriate.
            if ~isempty(obj.LaunchCheckbox)
                obj.LaunchCheckbox.Position = [20 300 430 20];
                obj.LaunchCheckbox.ValueChangedFcn = @obj.checkboxCallback;
                obj.LaunchCheckbox.Value=obj.Workflow.ShowExamples;
            else
                obj.Workflow.ShowExamples = false;
            end
            
        end
    end
    
    methods(Access = 'private')
        function checkboxCallback(obj, src, ~)
            obj.Workflow.ShowExamples = src.Value;
        end
    end
    
end

