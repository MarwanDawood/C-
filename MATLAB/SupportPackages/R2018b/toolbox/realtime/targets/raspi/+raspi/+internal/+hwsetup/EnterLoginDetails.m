classdef EnterLoginDetails < matlab.hwmgr.internal.hwsetup.TemplateBase
    %   Copyright 2017 The MathWorks, Inc.
    % ENTERLOGINDETAILS - Template to enable the creation of screen that
    % lets users enter the login details of a remote Linux system that can
    % be accessed through SSH (Secure Shell) protocol.
    %
    % ENTERLOGINDETAILS  Properties
    %   Title(Inherited)    Title for the screen specified as a Label widget
    %   DeviceAddressLabel  Text Label for the device IP address
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Description - Description for the screen (Label)
        Description
        DeviceAddressLabel
        DeviceAddressText
        DeviceUsernameLabel
        DeviceUsernameText
        DevicePasswordLabel
        DevicePasswordText
        TestConnButton
    end
    
    properties (Access=protected)
        ConnectionSucccess = false;
        Waitbar
    end
        
    
    methods
        function obj = EnterLoginDetails(workflow)
            % Call to class constructor
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(workflow)
            % Set Title
            obj.Title.Text = 'Connect the hardware board';
            % Set "What to consider"
            obj.HelpText.WhatToConsider = '<What to consider while connecting through SSH';
            % Set "About"
            obj.HelpText.AboutSelection = '<About the selection>';
            
            % Set Description
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.Description.Text = '<Description here>';
            obj.Description.Position = [20 280 430 100];
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;

            % Device address label
            obj.DeviceAddressLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.DeviceAddressLabel.Text = '<Device address label here>';
            obj.DeviceAddressLabel.Position = [20 290 160 20];
            obj.DeviceAddressLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            % Device address edit box
            obj.DeviceAddressText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.DeviceAddressText.Position = [165 290 105 20];
            obj.DeviceAddressText.TextAlignment = 'left';
%             obj.DeviceAddressText.ValueChangedFcn = @obj.checkDeviceAddress;
%             checkDeviceAddress(obj, obj.DeviceAddressText, '');
            
            % Username label
            obj.DeviceUsernameLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.DeviceUsernameLabel.Text = '<Device username label here>';
            obj.DeviceUsernameLabel.Position = [20 260 160 20];          
            obj.DeviceUsernameLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            % Username edit box
            obj.DeviceUsernameText = matlab.hwmgr.internal.hwsetup.EditText.getInstance(obj.ContentPanel);
            obj.DeviceUsernameText.Position = [165 260 105 20];
            obj.DeviceUsernameText.TextAlignment = 'left';
            
            % Password label
            obj.DevicePasswordLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);          
            classType = 'javax.swing.JPasswordField';
            obj.DevicePasswordText= javaObjectEDT(classType);
            position = [165 230 105 20];
            obj.ContentPanel.Tag = 'paneltag';
            parent=findall(0,'Tag','paneltag');
            panelpeer = findobj(parent,'Tag','paneltag');
            
            [obj.DevicePasswordText, containerComponent] = javacomponent(obj.DevicePasswordText, position, panelpeer);
            
            % set the Password label text
            obj.DevicePasswordLabel.Text =  '<Device password label here>';
            
            obj.DevicePasswordLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            obj.DevicePasswordLabel.Position = [20 230 160 20];
            
            obj.DevicePasswordText.show;
            containerComponent.Visible = 'on';
                        
            % Set the Test Connection Button
            obj.TestConnButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel);
            obj.TestConnButton.Text = 'Test connection';
%             obj.TestConnButton.ButtonPushedFcn = '';
            obj.TestConnButton.Position = [20 180 100 20];
        end
        
        function checkDeviceAddress(obj, wid, ~)
            % if the DeviceAddress, Username, Password is empty - disable
            % 'Next >' button
            if isempty(wid.Text)
                obj.NextButton.Enable = 'off';
            else
                obj.NextButton.Enable = 'on';
            end
        end
    end
end