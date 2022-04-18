
classdef RebootRaspi < matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup

%   RebootRaspi - Screen provides the ability to reboot Raspberry Pi
%   Copyright 2017-2018 The MathWorks, Inc.    
    properties (Access=private)
        AboutText
    end
    
    methods
        function obj = RebootRaspi(varargin)
            obj@matlab.hwmgr.internal.hwsetup.SelectionWithRadioGroup(varargin{:});
            obj.Title.Text = message('raspi:hwsetup:RebootRaspiTitle').getString;
            obj.Description.Text = message('raspi:hwsetup:RebootRaspiDesc').getString;
            obj.SelectionRadioGroup.Title = message('raspi:hwsetup:RebootRaspiChkBoxTitle').getString;
            obj.SelectionRadioGroup.Items = {message('raspi:hwsetup:RebootRaspiNow').getString,...
                message('raspi:hwsetup:RebootRaspiLater').getString};
            obj.SelectionRadioGroup.Position = [20 230 430 80];
            obj.HelpText.AboutSelection = message('raspi:hwsetup:RebootRaspiAbtSel_1').getString;
            obj.HelpText.WhatToConsider = '';
            obj.SelectionRadioGroup.SelectionChangedFcn = @obj.callback;
            obj.SelectedImage.ImageFile = '';
        end
        
        function out = getPreviousScreenID(~)
            out = 'raspi.internal.hwsetup.ConfigurePeripherals';
        end
        
        function callback(obj,~,~)
            if obj.SelectionRadioGroup.ValueIndex == 1
                obj.HelpText.AboutSelection = message('raspi:hwsetup:RebootRaspiAbtSel_1').getString;
            else
                obj.HelpText.AboutSelection = message('raspi:hwsetup:RebootRaspiAbtSel_2').getString;
            end
        end
        
        function rebootPi(obj)
            if ~(ispref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest')&&...
                    (getpref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest') == 1))
                if obj.SelectionRadioGroup.ValueIndex == 1
                    % Reboot Now
                    ssh = matlabshared.internal.ssh2client(obj.Workflow.CustomDeviceAddress,...
                        obj.Workflow.CustomDeviceUSRName, obj.Workflow.CustomDevicePsswd);
                    ssh.execute('sudo reboot 1 >$HOME/debug.log &');
                end
            end
        end
        
        function out = getNextScreenID(obj)
            rebootPi(obj);
            out = 'raspi.internal.hwsetup.CustomSetupComplete';
        end
        
        function restoreValues(obj)
            obj.enableScreen();
        end
    end
    
end
