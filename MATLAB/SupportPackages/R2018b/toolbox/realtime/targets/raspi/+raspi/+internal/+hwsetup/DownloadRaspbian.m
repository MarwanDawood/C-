classdef DownloadRaspbian <  matlab.hwmgr.internal.hwsetup.ListTpTools
    % DownloadRaspbian - Screen implementation to enable users to download the required 3P softwares.
    
    %   Copyright 2018 The MathWorks, Inc.
    
    methods
        
        function obj = DownloadRaspbian(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ListTpTools(varargin{:});
            
            % Set the Title Text
            obj.Title.Text = message('raspi:setup:Raspbian_Download').getString;
            
            % Method that sets Raspbian info
            obj.SetRaspbianDetails(); 
            
            obj.Description.Text = message('raspi:setup:Raspbian_Description').getString;
            obj.Description.Visible = 'on';
            
            % Enable Next button
            obj.NextButton.Enable = 'on';
        end
        
        function SetRaspbianDetails(obj)
            obj.ListTpDownloadTable.Position = [20 220 440 100];
            raspbianName = obj.Workflow.HardwareInterface.getRaspbianName;
            raspbianVersion = obj.Workflow.HardwareInterface.getRaspbianVersion;
            raspbianDwldUrl = obj.Workflow.HardwareInterface.getRaspbianDownloadUrl;
            obj.ListTpDownloadTable.Name = {raspbianName};
            obj.ListTpDownloadTable.Version = {raspbianVersion};
            DownloadDetails = ['<a href="matlab:web(''' raspbianDwldUrl ''', ''-browser'')">' 'Download' '</a>'];
            obj.ListTpDownloadTable.Details = {DownloadDetails};
            obj.HelpText.WhatToConsider = message('raspi:setup:DownloadRaspbianWhatToCons').getString;
            raspbianGithub = obj.Workflow.HardwareInterface.getRaspbianGithub;
            aboutSelectionStr = [message('raspi:setup:DownloadRaspbianAboutSelection').getString raspbianGithub];
            obj.HelpText.AboutSelection = aboutSelectionStr;
            obj.ListTpDownloadTable.Visible = 'On';
        end
        
        function reinit(obj)
            % Method that sets Raspbian info
            obj.SetRaspbianDetails(); 
        end
        
        function out = getNextScreenID(~)
            out = 'raspi.internal.hwsetup.ValidateRaspbian';
        end
        
        function id = getPreviousScreenID(~)
            id = 'raspi.internal.hwsetup.SelectLinuxImage';
        end
        
    end
end