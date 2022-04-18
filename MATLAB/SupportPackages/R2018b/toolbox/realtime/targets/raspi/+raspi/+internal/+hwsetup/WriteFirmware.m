classdef WriteFirmware < matlab.hwmgr.internal.hwsetup.WriteToHardware
    % WriteFirmware - Screen implementation to enable users to write
    % firmware to the SD card
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    
    properties
        FirmwareUpdatePollInterval = 5; % 5 sec interval
        DDProcessIntervalInit = 300;
        DDProcessIntervalEnd = 310;
    end
    
    properties(Access=private)
        FwUpdateError = false;
        IsCancelled
    end
    
    methods
        function obj = WriteFirmware(varargin)
            % call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.WriteToHardware(varargin{:});
            
            % Set selected Drive
            obj.Workflow.HardwareInterface.setDrive(obj.Workflow.Drive);
            
            % Set hostname to preference
            obj.Workflow.HardwareInterface.setBoardName(obj.Workflow.HostName);
            
            % Set DHCP choice to preference
            obj.Workflow.HardwareInterface.setUseDhcp(obj.Workflow.DhcpChoice);
            
            % Set the Title Text
            obj.Title.Text = message('raspi:hwsetup:WriteFirmwareTitle').getString;
            
            writeTo = obj.getDriveVolumeText();
            
            obj.Description.Text = ...
                message('raspi:hwsetup:WriteFirmwareDescription', writeTo).getString;
            
            obj.WriteButton.Text = message('raspi:hwsetup:WriteFirmwareButtonText').getString;
            
            obj.WriteButton.ButtonPushedFcn = @obj.writeFirmware;
            
            % Set this to empty, since there is nothing to be selected
            obj.HelpText.AboutSelection = '';
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:WriteFirmwareWhatToConsider').getString;
            obj.HelpText.Additional = ['<h6>' message('raspi:hwsetup:WriteFirmware_Warning').getString '</h6>'];
            obj.HelpText.Additional = ['<br>',...
                message('raspi:hwsetup:Note').getString, ...
                message('raspi:hwsetup:WriteFirmware_Note2').getString '<br>' '<br>',...
                ['<h6>' message('raspi:hwsetup:WriteFirmware_Warning').getString '</h6>']...
                message('raspi:hwsetup:WriteFirmware_WarningText').getString];
            
            % Align widgets
            obj.WriteProgress.shiftVertically(50);
            obj.WriteButton.shiftVertically(50);
            obj.WriteButton.shiftHorizontally(-10);
            obj.WriteButton.addHeight(1); % Increase height to match with WriteProgress.
        end
        
        function out = getNextScreenID(obj)
            [~, drives] = obj.Workflow.HardwareInterface.getDriveList();
            if isunix
                [sdMount_s, sdMount_e] = regexp(obj.Workflow.Drive,'/dev/[a-z]+[0-9]+');
                sdMount = obj.Workflow.Drive(sdMount_s:sdMount_e);
                if ~contains(drives,sdMount)
                    error(message('raspi:hwsetup:KeepMemoryCardInserted'));
                end
            else
                out = ismember(drives, obj.Workflow.Drive);
                index = find(out, 1); % to improve performance
                if isempty(index)
                    error(message('raspi:hwsetup:KeepMemoryCardInserted'));
                end
            end
            obj.Workflow.HardwareInterface.configureBoard(obj.Workflow.BoardName);
            out = 'raspi.internal.hwsetup.ConnectHardware';
        end
        
        function reinit(obj)
            % Set selected Drive
            obj.Workflow.HardwareInterface.setDrive(obj.Workflow.Drive);
            
            % Set hostname to preference
            obj.Workflow.HardwareInterface.setBoardName(obj.Workflow.HostName);
            
            % Set DHCP choice to preference
            obj.Workflow.HardwareInterface.setUseDhcp(obj.Workflow.DhcpChoice);
            
        end
        
        function out = getPreviousScreenID(obj) %#ok<MANU>
            out = 'raspi.internal.hwsetup.SelectDrive';
        end
        
        function restoreScreen(obj)
            if ~isvalid(obj)
                % Return, if class handle is invalid
                return
            end
            obj.enableScreen();
            writeTo = obj.getDriveVolumeText();
            obj.Description.Text = ...
                message('raspi:hwsetup:WriteFirmwareDescription', writeTo).getString;
            
            if obj.FwUpdateError
                obj.WriteProgress.Indeterminate = false;
                obj.WriteProgress.Value = 0;
            else                
                obj.WriteProgress.Indeterminate = false;
                if (obj.WriteProgress.Value == 100)
                    obj.WriteButton.Enable = 'off';
                    obj.WriteButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.GREY;
            else
                     obj.WriteButton.Enable = 'on';
                end
                
            end
        end
        
        function restoreCancelCbk(obj)
            % re-assign original callback to CancelButton.
            if ~isvalid(obj)
                % When hwsetup window is closed, we have to kill
                % sdwriter.exe with out the class handle and return
                cmd = 'sdwriter.exe';
                [st, msg] = system(['tasklist /fi "Imagename eq ' cmd '" /fo csv']);
                if st == 0 && ~isempty(regexp(msg, cmd, 'once'))
                    [~,~] = system(['taskkill /F /T /IM ', cmd], ...
                        '-runAsAdmin');
                end
                return
            end
            obj.CancelButton.ButtonPushedFcn = {@matlab.hwmgr.internal.hwsetup.TemplateBase.finish, obj};
            if ~obj.IsCancelled
                % Kill the firmware update process on exit
                obj.Workflow.HardwareInterface.killWriteImage(...
                    obj.Workflow.HardwareInterface.getImageWriteCmd());
            end
        end
        
        function cancel(obj, ~, ~)
            % Cancels write firmware operation and reset the progress bar.
            % Restore the screen back by enabling all widgets.
            obj.Workflow.HardwareInterface.killWriteImage(...
                obj.Workflow.HardwareInterface.getImageWriteCmd());
            obj.restoreScreen();
            obj.WriteProgress.Value = 0;
            obj.IsCancelled = true;
        end
        
        function out = getDriveVolumeText(obj) %#ok<MANU>
            if ismac
                out =  lower(message('raspi:hwsetup:WriteFirmwareVolume').getString);
            else
                out = lower(message('raspi:hwsetup:WriteFirmwareDrive').getString);
            end
        end
        
        function writeFirmware(obj, ~, ~)
            [~, drives] = obj.Workflow.HardwareInterface.getDriveList();
            out = ismember(drives, obj.Workflow.Drive);
            index = find(out, 1); % to improve performance
            if isempty(index)
                error(message('raspi:hwsetup:KeepMemoryCardInserted_ToWriteFW'));
            end
            
            writeTo = obj.getDriveVolumeText();
            
            obj.Description.Text = ...
                [message('raspi:hwsetup:WriteFirmwareDescription', writeTo).getString ...
                newline message('raspi:hwsetup:WriteFirmwareStatusWriting').getString;];
            obj.WriteButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.GREY;
            obj.disableScreen({'Description','CancelButton'});
            obj.CancelButton.ButtonPushedFcn = @obj.cancel;
            % re-assign original callback to CancelButton.
            restoreCancel = onCleanup(@obj.restoreCancelCbk);
            
            % restore screen to enable all widgets
            restoreOnCleanup = onCleanup(@obj.restoreScreen);
            
            updatecount = 0;
            tstart = tic;
            isTimeOut = false;
            fwupdatePctComplete = 1;
            % Trigger the command to start writing Firmware on the SD Card
            obj.IsCancelled = false;
            [status, msg] = obj.Workflow.HardwareInterface.writeFirmware();
            if status
                obj.FwUpdateError = true;
                error(message('raspi:hwsetup:WriteFirmwareError', msg));
            end
            
            % Poll either till timeout of the write is complete
            while ~isTimeOut && ~isequal(fwupdatePctComplete, 100)
                telapsed = toc(tstart);
                updatecount = updatecount +1;
                % Pause is moved here to give enough time to update log
                % files and ErrorFile.
                % In addition pause is required to wait 5 Sec before
                % updating the wait bar.
                pause(obj.FirmwareUpdatePollInterval);
                
                % Get Firmware update percent complete
                % For *nix, percent complete function will return 0 if it
                % failed to read the dd log.
                writePct = obj.Workflow.HardwareInterface.getFirmwareWritePercentComplete;
                if writePct > fwupdatePctComplete
                    fwupdatePctComplete = writePct;
                end 
                if obj.IsCancelled
                    break % break here, so that progress bar is not updated
                else
                    obj.WriteProgress.Value = fwupdatePctComplete;
                end
                if ispc
                    timeOutParam = updatecount;
                else
                    timeOutParam = telapsed;
                    % Check if the 'dd' process has started after 5 minutes
                    if ~ismac && telapsed > obj.DDProcessIntervalInit && telapsed < obj.DDProcessIntervalEnd
                        if ~obj.Workflow.HardwareInterface.hasddProcessStarted()
                            obj.FwUpdateError = true;
                            dd_msg = message('raspi:hwsetup:Error_ddmsg').getString;
                            error(message('raspi:hwsetup:ErrorWritingFirmware', dd_msg));
                        end
                    end
                end
                % Throw error if the time-out has occurred
                isTimeOut = obj.Workflow.HardwareInterface.isFirmwareWriteTimeout(timeOutParam);
                if isTimeOut
                    obj.FwUpdateError = true;
                    error(message('raspi:hwsetup:ErrorWritingFirmware', obj.Workflow.HardwareInterface.firmwareTimeOutError()));
                end
            end
            
            if fwupdatePctComplete == 100 && ~obj.IsCancelled
                % Do not update progressbar if cancelled
                obj.WriteProgress.Value = 100;
                obj.HelpText.WhatToConsider = ...
                    message('raspi:hwsetup:WriteFirmwareWhatToConsiderAfterWrite').getString;
            end
        end
        
    end
end