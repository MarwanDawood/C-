classdef MACHardwareModule < raspi.internal.hwsetup.HardwareInterface
    % MACHardwareModule - Class that covers all hardware specific
    % callbacks in MAC.
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    
    properties(Constant)
        FWUPDATETIMEOUT = 5400 % 90 minutes
    end
    methods
        
        function configureBoard(obj,boardName)
            obj.writeBoardName;
            obj.writeNetworkConfig;
            obj.writeIfList(boardName);
            obj.writeOtgConfig(boardName);
            obj.saveIPParams;
        end
        
        function writeIfList(obj,boardName)
            nic = obj.getNics();
            filename = obj.getFilePathForHostName(obj.NICListFileName);
            if isempty(filename)
                error(message('raspi:setup:UnableToAccessMemoryCard'));
            end
            
            fid = fopen(filename, 'w');
            if (fid < 0)
                error(message('raspi:setup:UnableToAccessMemoryCard'));
            end
            for i = 1:numel(nic)
                if isequal(nic(i).ip, '0.0.0.0')
                    nic(i).ip = '255.255.255.255';
                end
                fprintf(fid, '%s\n', nic(i).ip);
            end
            fprintf(fid, '%s\n', '255.255.255.255');
            %Add link-local broadcast IP address for Raspi Zero W
            if strcmp(boardName,message('raspi:hwsetup:RaspberryPiZeroW').getString)
                linkLocalBcast = '192.168.9.255';
                fprintf(fid, '%s\n', linkLocalBcast);
            end
            fclose(fid);
        end
        
        function killWriteImage(obj, ddcommand)
            ps_cmd = ['ps -ax -j | grep ''' ddcommand ''''];
            [~, ps_msg] = system(ps_cmd);
            ps_msgarray = strsplit(strtrim(ps_msg), newline);
            
            pattern ='(?<usernam00e>\w+)\s+(?<pid>\d+)\s+(?<ppid>\d+)\s+(?<gid>\d+)\s+(?<session>\d+)\s+(?<jobc>\d+)\s+(?<status>.{1,3})\s+(?<tt>((\w+)|(\?\?)))\s+(?<time>(\d)*:\d\d.\d\d)\s+(?<cmd>.+)';
            
            z = regexp(ps_msgarray,pattern,'names');
            pscommands = [z{:}];
            index = strcmp({pscommands.cmd},ddcommand);
            
            logCmd = [' -e ''do shell script "echo Cancelled >>  ' obj.LogFile '" with administrator privileges'''];
            if any(index)
                killcmd = ['/usr/bin/osascript -e ''do shell script "kill -9 ' pscommands(index).pid '" with administrator privileges''' , logCmd];
                [~, ~] = system(killcmd);
            end
        end
        
        function out = isFirmwareWriteTimeout(obj, val)
            out = obj.FWUPDATETIMEOUT < val;
        end
        
        function  cmd =  getImageWriteCmd(obj)
            % Limiting the blocksize to 8192 as too low or too high wont
            % serve the purpose.
            cmd = ['dd if=' obj.ImageFile ' of=' obj.SDCardDrive ' bs=8192'];
        end
        
        function [status, msg] = writeFirmware(obj)
            
            % Un-mount the partition, so that you will be allowed to
            % overwrite the disk.
            unmountcmd = ['-e ''do shell script "diskutil unmountDisk ' obj.SDCardDrive '" with administrator privileges'''];
            
            ddcommand = obj.getImageWriteCmd();
			% Write ddcommand and signalling loop to a shell script and then execute it.
			scriptString = [ddcommand ' >& ' obj.LogFile ' &' newline ...
							'ddpid=`pgrep -n -f "' ddcommand '"`' newline ...
							'sleep 10' newline ...
							'while kill -0 $ddpid' newline ...
							'do' newline ...
							'kill -INFO $ddpid' newline ...
							'sleep 5' newline ...
							'done' newline];
            scriptFile = tempname;
			fid = fopen(scriptFile,'w');
			if fid < 0
				status =  1;
				msg = message('raspi:hwsetup:WriteFirmwareScriptError').getString;
				return;
			end
			fprintf(fid,'%s',scriptString);
			fclose(fid);
			
            % Change the file permission
            chPermissionCmd = ['chmod +x ' scriptFile];
            [status, msg] = system(chPermissionCmd);
            if (status ~= 0)
                % Cannot proceed further. Return and throw error.
                return;
            end
			
            % Write command
            writecmd = ['/usr/bin/osascript ' unmountcmd ' -e ''do shell script "' scriptFile '" with administrator privileges''&'];
            [status, msg] = system(writecmd);            
        end
        
        function out = getFirmwareWritePercentComplete(obj)
            out = 0;
            fileInfo = dir(obj.LogFile);
            if ~isempty(fileInfo) && ~isequal(fileInfo.bytes,0)
                logMsgTxt = fileread(obj.LogFile);
				tailCmd = ['tail -n1 ' obj.LogFile];
                try
                    [~,logDataLastLine] = system(tailCmd);
                    logData = textscan(logDataLastLine,'%d bytes %s');
                catch
                    logData{1} = 0;
                end
                
                if ~isempty(logData{1})
                    bytesTrans = logData{1};
                else
                    bytesTrans = 0;
                end
                imageFileInfoInfo = dir(obj.ImageFile);
				out = (double(bytesTrans)*100.0)/imageFileInfoInfo.bytes;
                %Remount will take some to execute. Keep the progress bar at
                %99% to accomodate this time.
                if out > 99
                    out = 99;
                end
                if contains(logMsgTxt, num2str(imageFileInfoInfo.bytes))
                    driveMountname = [];
                    tstart_remount = tic;
                    while(isempty(driveMountname))
                        telapsed_remount = toc(tstart_remount);
                        if (telapsed_remount > 300)
                            break;
                        end
                        [~, msg] = system(['df -Hl | grep '''  obj.SDCardDrive '''']);
                        driveMountname = regexp(msg,'/Volumes/.*','match');
                    end
                    out = 100;
                elseif contains(logMsgTxt,'dd:')
                    error(message('raspi:hwsetup:ErrorWritingFirmware', logMsgTxt));
                end
            end
        end     
        
        function status = checkSSHentry(obj, ipAddress) %#ok<INUSL>
            if exist('~/.ssh/known_hosts','file')
                cmd = ['sed -i '''' ''/' ipAddress '/d''' ' ~/.ssh/known_hosts'];
                [status, ~] = system(cmd);
            else
                status = 0; % if known_hosts file not exists
            end
        end
        
        function addStaticRoute(obj, nic) %#ok<INUSD>
            % Nothing to do for MAC
        end
        
        function configureNicForDhcp(obj, nic) %#ok<INUSL>
            if ~nic.dhcpEnabled
                cmd = ['/usr/bin/osascript -e ''do shell script "networksetup -setdhcp ' nic.name '" with administrator privileges'''];
                [st, msg] = system(cmd);
                if (st ~= 0)
                    error('raspi:setup:ErrorWhileConfiguringNic', msg);
                end
            end
        end
        
        function rPiNics = detectNics(obj, nics)
            rPiNics = [];
            for i = 1:numel(nics)
                nicInfo = nics;
                thisNic = [];
                for j = 1:numel(nicInfo)
                    if isequal(nics(i).mac, nicInfo(j).mac)
                        thisNic = nicInfo(j);
                        break;
                    end
                end
                if ~isempty(thisNic) && obj.loc_isConnected(thisNic)
                    nics(i).ip = thisNic.ip;
                    cmd = ['ping -c 1 -S ' nics(i).ip ' 169.254.0.2'];
                    [st, msg] = system(cmd);
                    if (st == 0) && ~isempty(regexpi(msg, '\sTTL='))
                        rPiNics = nics(i);
                        break;
                    end
                end
            end
        end
        
        
        function nic = getNics(obj)
            nic = [];
            % Get all the network information available
            cmd = 'networksetup -listallhardwareports';
            [status, msg] = system(cmd);
            if (status ~= 0)
                warning(message('raspi:setup:ErrorWhileQueryingNic', msg));
                return;
            end
            
            % Extract NIC information returned by networksetup
            pattern = 'Hardware Port:\s(?<name>[\w\s-/]+)\s+Device:\s(?<device>\w+\-?\w+)\s+Ethernet Address:\s(?<mac>(\w\w:*)+)\s+';
            nicinfo = regexp(msg, pattern, 'names');
            
            % Eliminate the network configurations which are not
            % active.
            indx = [];
            for i = 1:numel(nicinfo)
                et_cmd = ['ifconfig -v ' nicinfo(i).device ' | grep "status"'];
                [~, nwstatus] = system(et_cmd);
                if strcmp(strtrim(nwstatus),'status: active')
                    indx(end+1) = i; %#ok<AGROW>
                end
            end
            
            % Error out if there is no NIC found.
            if isempty(indx)
                warning(message('raspi:setup:NoNic'));
                return;
            end
            
            nic = nicinfo(indx);
            
            for i = 1:numel(nic)
                nic(i).connected   = 1; %Set to 1 as status of network is already checked above.
                nic(i).dhcpEnabled = obj.loc_Isdhcpenabled(nic(i).name);
                nic(i).ip          = obj.loc_GetIpaddress(nic(i).name);
                nic(i).dhcpServer  = 1; % Filled with 1 as this information is not required
                nic(i).index       = i; % Filled with 1 as this information is not required
                nic(i).description = nic(i).name;
            end
        end
        
        function ret = getFilePathForHostName(obj, fileName)
            [st, msg] = system(['df -Hl | grep '''  obj.SDCardDrive '''']);
            if st
                ret = [];
            else
                driveMountname = regexp(msg,'/Volumes/.*','match');
                ret = fullfile(strtrim(driveMountname{:}), fileName);
            end
        end
        
        function [status, driveList] = getDriveList(obj)
            driveList = {};
            
            cmd = 'diskutil list';
            [status, msg] = system(cmd);
            if status ~= 0
                error(message('raspi:hwsetup:RemovableDriveQuery', msg));
            end
            
            % Parse drive list
            pattern ='(?<sectornumber>\d:)\s+(?<type>\w+)\s(?<name>\w*\s*\w*)\s+\*(?<size>\d+\.\d+)\s(?<units>\w+)\s+(?<identifier>\w+)';
            tmp = regexp(msg,pattern,'names');
            if ~isempty(tmp)
                driveListIdentifier = {tmp(strcmp({tmp.type},'FDisk_partition_scheme')).identifier};
                if ~isempty(driveListIdentifier)
                    driveSize = {tmp(strcmp({tmp.type},'FDisk_partition_scheme')).size};
                    driveSizeUnits = {tmp(strcmp({tmp.type},'FDisk_partition_scheme')).units};
                    driveList = cellfun(@obj.getDriveMountName, driveListIdentifier, driveSize, driveSizeUnits, 'UniformOutput', false);
                    if isempty(driveList{1})
                        driveList = {};
                    end
                end
            end
        end % end getDriveList 
    end
    
    methods(Static)
        function drivelist = getDriveMountName(driveListIdentifier, driveSize, driveSizeUnits)
            [~, msg] = system(['df -Hl | grep '''  driveListIdentifier 's1' '''']); % append the sector1 and filter the SD card with sector 1 only.
            drivename = char(regexp(msg,'/Volumes/.*','match'));
            mountname = strtrim(drivename);
            if ~isempty(mountname)
                drivelist = [mountname ' (' driveSize driveSizeUnits ', ''/dev/' driveListIdentifier ''')'];% mountname, driveListIdentifier, driveSize,driveSizeUnits];
            else
                drivelist = [];
            end
        end
        
        
        function msg = firmwareTimeOutError()
            msg = 'Exceeds 90 minutes time, click "Write" to try again';
        end
        
        function ipaddress = loc_GetIpaddress(interfacename)
            
            cmd = ['networksetup -getinfo ' '"' interfacename '"'];
            [~, msg] = system(cmd);
            val = regexp(msg,'IP address:\s(?<ipaddress>(\d+\.?)+)\s+','names');
            if isempty(val)
                ipaddress = '0.0.0.0';
            else
                ipaddress = val.ipaddress;
            end
            
        end
    end
end