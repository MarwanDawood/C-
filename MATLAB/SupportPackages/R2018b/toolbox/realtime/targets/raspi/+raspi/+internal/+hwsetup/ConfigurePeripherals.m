classdef ConfigurePeripherals < matlab.hwmgr.internal.hwsetup.TemplateBase
    % ConfigurePeripherals - Configure the peripherals on Raspberry pi
    % Copyright 2017-2018 The MathWorks, Inc.
    
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % Description - Description for the screen (Label)
        spiEnable
        i2cEnable
        uartEnable
        cameraEnable
        Description
        spiDropDown
        spiLabel
        i2cDropDown
        i2cLabel
        uartDropDown
        uartLabel
        cameraDropDown
        cameraLabel
        dropDownItems = {'Enabled','Disabled'};
        tempLoc;
    end
    
    
    
    methods
        function obj = ConfigurePeripherals(workflow)
            % Call to class constructor
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(workflow);
            % Create the widgets and parent them to the content panel
            obj.Title.Text = message('raspi:hwsetup:ConfigurePeripheralsTitle').getString;
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.Description.Text = message('raspi:hwsetup:ConfigurePeripheralsDesc').getString;
            obj.Description.Position=[20 260 400 120];
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:ConfigurePeripheralsConsider').getString;
            obj.HelpText.AboutSelection = '';
            obj.tempLoc = tempname;
            obj.displayStatus;
        end
        
        function [SelectionDropDown,SelectionLabel] = buildDropDown(obj,label,labelPos,DropDownPos,DropDownItems,ValueIndex)
            SelectionDropDown = matlab.hwmgr.internal.hwsetup.DropDown.getInstance(obj.ContentPanel);
            SelectionLabel = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            SelectionLabel.Text = label;
            SelectionLabel.Position = labelPos;
            SelectionLabel.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            SelectionDropDown.Position = DropDownPos;
            SelectionDropDown.Items = DropDownItems;
            SelectionDropDown.ValueIndex = ValueIndex;
        end
        
        function displayStatus(obj)
            % If the screens are run as part of Test, bypass 'checkRaspiPeripherals' and return true
            if ispref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest')&&...
                    (getpref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest') == 1)
                obj.spiEnable = uint8(1);
                obj.i2cEnable = uint8(1);
                obj.uartEnable = uint8(1);
                obj.cameraEnable = uint8(1);
            else
                [obj.spiEnable, obj.i2cEnable, obj.uartEnable, obj.cameraEnable] = checkRaspiPeripherals(obj);
            end
            % Display the status of each of the peripherals
            [obj.spiDropDown,obj.spiLabel] = obj.buildDropDown(message('raspi:hwsetup:EnableSPI').getString, [20 280 150 30],[180 280 150 30],obj.dropDownItems,obj.spiEnable);
            [obj.i2cDropDown,obj.i2cLabel] = obj.buildDropDown(message('raspi:hwsetup:Enablei2c').getString, [20 250 150 30],[180 250 150 30],obj.dropDownItems,obj.i2cEnable);
            [obj.uartDropDown,obj.uartLabel]= obj.buildDropDown(message('raspi:hwsetup:EnableUART').getString, [20 220 150 30],[180 220 150 30],obj.dropDownItems,obj.uartEnable);
            [obj.cameraDropDown,obj.cameraLabel] = obj.buildDropDown(message('raspi:hwsetup:EnableCamera').getString, [20 190 150 30],[180 190 150 30],obj.dropDownItems,obj.cameraEnable);            
        end
        
        function reinit(obj)
            obj.displayStatus;
        end
        
        function [spiEnabled,i2cEnabled,uartEnabled,cameraEnabled]=checkRaspiPeripherals(obj)
            %Create a SSH session
            ssh = matlabshared.internal.ssh2client(obj.Workflow.CustomDeviceAddress,...
                obj.Workflow.CustomDeviceUSRName, obj.Workflow.CustomDevicePsswd);
            %Copy the /boot/config.txt file
            if ~exist(obj.tempLoc,'dir')
                mkdir(obj.tempLoc);
            end
            ssh.scpGetFile('/boot/config.txt',fullfile(obj.tempLoc,'config.txt'));
            % Read the contents of the file
            config = fileread(fullfile(obj.tempLoc,'config.txt'));
            
            %Check status of SPI
            if ~contains(config,'#dtparam=spi')
                if contains(config,'dtparam=spi=on')
                    spiEnabled = 1;
                else
                    spiEnabled = 2;
                end
            else
                spiEnabled = 2;
            end
            
            %Check status of I2C
            if ~contains(config,'#dtparam=i2c_arm')
                if contains(config,'dtparam=i2c_arm=on')
                    i2cEnabled = 1;
                else
                    i2cEnabled = 2;
                end
            else
                i2cEnabled = 2;
            end
            
            %Check status of UART
            if ~contains(config,'#enable_uart')
                if contains(config,'enable_uart=1')
                    uartEnabled = 1;
                else
                    uartEnabled = 2;
                end
            else
                uartEnabled = 2;
            end
            
            %Check status of Camera
            if ~contains(config,'#start_x')
                if contains(config,'start_x=1')
                    cameraEnabled = 1;
                else
                    cameraEnabled = 2;
                end
            else
                cameraEnabled = 2;
            end
        end
        
        function setRaspiPeripherals(obj)
            cmdlineConfig = [];
            %Create a SSH connection
            ssh = matlabshared.internal.ssh2client(obj.Workflow.CustomDeviceAddress,...
                obj.Workflow.CustomDeviceUSRName, obj.Workflow.CustomDevicePsswd);
            %check if the tempLoc exixts
            if ~exist(obj.tempLoc,'dir')
                mkdir(obj.tempLoc);
            end
            
            % Check if files exist and then copy. This will avoid
            % unnecessary scp if the user moves next and back through the
            % hardware setup screens.
            if ~exist(fullfile(obj.tempLoc,'config.txt'),'file')
                %Copy the /boot/config.txt file
                ssh.scpGetFile('/boot/config.txt',fullfile(obj.tempLoc,'config.txt'));
            end
            
            if ~exist(fullfile(obj.tempLoc,'cmdline.txt'),'file')
                %Copy the /boot/cmdline.txt file to edit serial console
                %reidrect
                ssh.scpGetFile('/boot/cmdline.txt',fullfile(obj.tempLoc,'cmdline.txt'));
            end
            
            % Read the contents of the file
            config = fileread(fullfile(obj.tempLoc,'config.txt'));
            
            % enable SPI
            if (obj.spiDropDown.ValueIndex == 1)
                spienable = 'on';
            else
                spienable = 'off';
            end
            if contains(config,'#dtparam=spi=on')
                config = strrep(config,'#dtparam=spi=on',['dtparam=spi=' spienable]);
            end
            if contains(config,'#dtparam=spi=off')
                config = strrep(config,'#dtparam=spi=off',['dtparam=spi=' spienable]);
            end
            if contains(config,'dtparam=spi=off')
                config = strrep(config,'dtparam=spi=off',['dtparam=spi=' spienable]);
            end
            if contains(config,'dtparam=spi=on')
                config = strrep(config,'dtparam=spi=on',['dtparam=spi=' spienable]);
            end
            if ~contains(config,'#dtparam=spi=on')&&~contains(config,'#dtparam=spi=off')...
                    &&~contains(config,'dtparam=spi=off')&&~contains(config,'dtparam=spi=on')
                config = [config newline 'dtparam=spi=' spienable];
            end
            
            
            % enable I2C
            if (obj.i2cDropDown.ValueIndex == 1)
                i2cenable = 'on';
            else
                i2cenable = 'off';
            end
            
            if contains(config,'#dtparam=i2c_arm=on')
                config = strrep(config,'#dtparam=i2c_arm=on',['dtparam=i2c_arm=' i2cenable]);
            end
            if contains(config,'#dtparam=i2c_arm=off')
                config = strrep(config,'#dtparam=i2c_arm=off',['dtparam=i2c_arm=' i2cenable]);
            end
            if contains(config,'dtparam=i2c_arm=off')
                config = strrep(config,'dtparam=i2c_arm=off',['dtparam=i2c_arm=' i2cenable]);
            end
            if contains(config,'dtparam=i2c_arm=on')
                config = strrep(config,'dtparam=i2c_arm=on',['dtparam=i2c_arm=' i2cenable]);
            end
            if ~contains(config,'#dtparam=i2c_arm=on')&&~contains(config,'#dtparam=i2c_arm=off')&&...
                    ~contains(config,'dtparam=i2c_arm=off')&&~contains(config,'dtparam=i2c_arm=on')
                config = [config newline 'dtparam=i2c_arm=' i2cenable];
            end
            
            
            % enable UART
            if (obj.uartDropDown.ValueIndex == 1)
                uartenable = '1';
                %Edit cmdline.txt to stop console log redirect to uart
                cmdlineConfig = fileread(fullfile(obj.tempLoc,'cmdline.txt'));
                if contains(cmdlineConfig,'console=serial0,115200')
                    cmdlineConfig = strrep(cmdlineConfig,'console=serial0,115200','');
                end
            else
                uartenable = '0';
            end
            if contains(config,'#enable_uart=1')
                config = strrep(config,'#enable_uart=1',['enable_uart=' uartenable]);
            end
            if contains(config,'#enable_uart=0')
                config = strrep(config,'#enable_uart=0',['enable_uart=' uartenable]);
            end
            if contains(config,'enable_uart=0')
                config = strrep(config,'enable_uart=0',['enable_uart=' uartenable]);
            end
            if contains(config,'enable_uart=1')
                config = strrep(config,'enable_uart=1',['enable_uart=' uartenable]);
            end
            if ~contains(config,'#enable_uart=1')&&~contains(config,'#enable_uart=0')&&...
                    ~contains(config,'enable_uart=0')&&~contains(config,'enable_uart=1')
                config = [config newline 'enable_uart=' uartenable];
            end
            
            
            
            % enable CAMERA
            if (obj.cameraDropDown.ValueIndex == 1)
                cameraenable = '1';
            else
                cameraenable = '0';
            end
            
            if contains(config,'#start_x=0')
                config = strrep(config,'#start_x=0',['start_x=' cameraenable]);
            end
            if contains(config,'#start_x=1')
                config = strrep(config,'#start_x=1',['start_x=' cameraenable]);
            end
            if contains(config,'start_x=0')
                config = strrep(config,'start_x=0',['start_x=' cameraenable]);
            end
            if contains(config,'start_x=1')
                config = strrep(config,'start_x=1',['start_x=' cameraenable]);
            end
            if ~contains(config,'#start_x=0')&&~contains(config,'#start_x=1')&&...
                    ~contains(config,'start_x=0')&&~contains(config,'start_x=1')
                config = [config newline 'start_x=' cameraenable];
            end
            
            
            %Update the config.txt file
            fid = fopen(fullfile(obj.tempLoc,'config.txt'),'wb');
            fwrite(fid,config);
            fclose(fid);
            
            %Update the cmdline.txt file
            if ~isempty(cmdlineConfig)
                fid = fopen(fullfile(obj.tempLoc,'cmdline.txt'),'wb');
                fwrite(fid,cmdlineConfig);
                fclose(fid);
            end

            %copy the config file
            ssh.scpPutFile(fullfile(obj.tempLoc,'config.txt'),'/tmp/config.txt');
            %replcae with the file in boot
            ssh.execute('sudo cp /tmp/config.txt /boot/config.txt');
            %remove the files created
            delete(fullfile(obj.tempLoc,'config.txt'));
            ssh.execute('sudo rm -rf /tmp/config.txt');
            
            %copy the cmdline.txt file
            ssh.scpPutFile(fullfile(obj.tempLoc,'cmdline.txt'),'/tmp/cmdline.txt');
            %add exe premissions to cmdline.txt
            ssh.execute('sudo chmod +x /tmp/cmdline.txt');
            %replcae with the file in boot
            ssh.execute('sudo cp /tmp/cmdline.txt /boot/cmdline.txt');
            %remove the files created
            delete(fullfile(obj.tempLoc,'cmdline.txt'));
            ssh.execute('sudo rm -rf /tmp/cmdline.txt');
        end
        
        function out = getPreviousScreenID(~)
            out = 'raspi.internal.hwsetup.InstallPackages';
        end
        
        function out = getNextScreenID(obj)
            %Apply changes
            if ~(ispref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest')&&...
                    (getpref('Hardware_Connectivity_Installer_RaspberryPi','HWSetupTest') == 1))
                setRaspiPeripherals(obj);
            end
            out = 'raspi.internal.hwsetup.RebootRaspi';
            
        end
        
    end
end