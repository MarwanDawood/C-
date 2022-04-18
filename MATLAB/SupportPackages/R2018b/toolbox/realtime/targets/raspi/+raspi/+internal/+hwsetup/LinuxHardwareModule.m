classdef LinuxHardwareModule < raspi.internal.hwsetup.HardwareInterface
    % LinuxHardwareModule - Class that covers all hardware specific
    % callbacks in Linux.
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    
    properties(Constant)
        FWUPDATETIMEOUT = 5400 % 90 minutes
    end
    
    properties(Access=private)
        FwUpdateHelper
    end
    
    methods
        function obj = LinuxHardwareModule()
            obj@raspi.internal.hwsetup.HardwareInterface();
            obj.FwUpdateHelper = matlabshared.internal.FwUpdateHelper();
        end
        
        function delete(obj)
            % Code has not reached Bhwmhr
            if isobject(obj.FwUpdateHelper)
                obj.FwUpdateHelper.delete();
            end
        end
        
        function configureBoard(obj, boardName)
            
            obj.writeBoardName;
            obj.writeNetworkConfig;
            obj.writeIfList(boardName);
            obj.writeOtgConfig(boardName);
            
            % Unmount SD Card
            % Check if SD card is mounted
            [mountstatus, ~] = obj.isdrivePartitionMounted(obj.SDCardDrive);
            if ~mountstatus
                % Try to unmount the SD card from mountpoint and delete the
                % mountpoint
                mountpoint = obj.getFilePathForHostName();
                unmountcmd = ['umount ' mountpoint,...
                    ' -l'];
                deletemountpointcmd = ['rm -rf ' mountpoint];
                [~, ~] =  obj.FwUpdateHelper.exec(unmountcmd);
                [~, ~] =  obj.FwUpdateHelper.exec(deletemountpointcmd);
            end
            
            obj.saveIPParams;
        end
        
        function writeIfList(obj,boardName)
            nic = obj.getNics();
            filename = obj.getFilePathForHostName(obj.NICListFileName);
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
        
        function killWriteImage(obj, cmd)
            % get the PID of 'dd' command
            dd_pid = obj.getPIDddcommandLinux(cmd);
            if ~isempty(dd_pid)
                killcmd = ['kill -9 ' dd_pid];
                logcmd = ['echo Cancelled >> ', obj.LogFile];
                [~, ~] = obj.FwUpdateHelper.exec(killcmd);
                [~, ~] = obj.FwUpdateHelper.exec(logcmd);
            end
        end
        
        function  cmd =  getImageWriteCmd(obj)
            % FwUpdateHelperApp is launched from
            % shared_linuxservicesRoot, ($SPPKGINSTALLROOT\toolbox\target\supportpackages\shared_linuxservices)
            % "pwd" will give the same thing. From there we derive the
            % relative path of image say raspbian_jessie_lite_5_27_2016_2gb.img
       
% 			imageFileDir = '../../../../raspbian/';
%             imageFileTmp =[imageFileDir obj.FirmwareName];
            imageFileTmp = obj.ImageFile;
            % Limiting the blocksize to 8192 as too low or too high wont
            % serve the purpose.
            cmd = ['dd if=' imageFileTmp ' of=' obj.SDCardDrive ' bs=8192 '];
        end
        
        function [status, msg] = writeFirmware(obj)
            
            % Any USB filesystem is unmounted in Linux by default.
            % Still unmount the drive in case the user has mounted it.
            
            % First check if the drive is mounted.
            
            % Get the name of the drive
            drivename = char(regexp(obj.SDCardDrive, '/dev/\w+', 'match'));
            % 'df -hl' to check the all mounted partitions
            chkmntcmd  = ['df -hl | grep "^' drivename '"'];
            [status, chkmntmsg] = system(chkmntcmd);
            if ~status
                % If the drive is mounted then unmount all partitions
                % and write image using 'dd' command
                mountedPartitions = regexp(chkmntmsg, '/dev/\w+', 'match');
                
                unmountcmd = ['umount -f ' mountedPartitions{1}];
                for i = 2:numel(mountedPartitions)
                    unmountcmd  = [unmountcmd ' && umount -f ' mountedPartitions{i}];%#ok<AGROW>
                end
                
                
                [unmountstatus, unmountmsg] = obj.FwUpdateHelper.exec(unmountcmd);
                unmountmsg = char(unmountmsg);
                if (unmountstatus ~= 0)
                    error(message('raspi:hwsetup:ErrorWritingFirmware', unmountmsg));
                end
            end
            
            % 'dd' command for writing image to drive.
            ddcommand = obj.getImageWriteCmd();
          
            writecmd = [ddcommand ' 2>' obj.LogFile '&'];
            
            [status, msg] = obj.FwUpdateHelper.exec(writecmd);
        end
        
        function out = isFirmwareWriteTimeout(obj, val)
            out = obj.FWUPDATETIMEOUT < val;
        end
        
        function out = getFirmwareWritePercentComplete(obj)
            out = 0;
            obj.sendLogSignal;
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
                %sync will take some to execute. Keep the progress bar at
                %99% to accomodate this time.
                if out > 99
                    out = 99;
                end
                if contains(logMsgTxt,num2str(imageFileInfoInfo.bytes))
                    system('sync');
                    % Need to mount the drive partition present in Linux
                    % after writing image
                    obj.FwUpdateHelper.exec(['partprobe ' obj.SDCardDrive]);
                    obj.mountDrivePartition();
                    out = 100;
                elseif contains(logMsgTxt,'dd:')
                    error(message('raspi:hwsetup:ErrorWritingFirmware', logMsgTxt));
                end
            end
        end
        
        function out = hasddProcessStarted(obj)
            ddcommand = obj.getImageWriteCmd();
            dd_pid = obj.getPIDddcommandLinux(ddcommand);
            out = ~isempty(dd_pid);
        end
        
        function sendLogSignal(obj)
            ddcommand = obj.getImageWriteCmd();
            dd_pid = obj.getPIDddcommandLinux(ddcommand);
            log_cmd = ['kill -USR1 ' dd_pid];
            obj.FwUpdateHelper.exec(log_cmd);
        end
        
        function status = checkSSHentry(obj, ipAddress) %#ok<INUSL>
            if exist('~/.ssh/known_hosts','file')
                cmd = ['ssh-keygen -R ' ipAddress];
                [status, ~] = system(cmd);
            end
        end
        
        function addStaticRoute(obj, nic) %#ok<*INUSD>
            %Nothing to do for Linux
        end
        
        function configureNicForDhcp(obj, nic)
            %Nothing to do for Linux
        end
        
        function rPiNics = detectNics(obj, nics) %#ok<STOUT>
            
            % Nothing to do for Linux
        end
        
        
        function nic = getNics(obj)
            nic = [];
            % Get the network interface names of type Ethernet connected to host Linux
            cmd = 'ip addr show';
            [status, msg] = system(cmd);
            if (status ~= 0)
                warning(message('raspi:setup:ErrorWhileQueryingNic', msg));
                return;
            end
            
            % Extract the NIC name, state (UP, DOWN, UNKNOWN), and
            % type (ether, loopback, etc)
            
            splitExp = ['[\dabcdef][\dabcdef]:[\dabcdef][\dabcdef]:',...
                '[\dabcdef][\dabcdef]:[\dabcdef][\dabcdef]:',...
                '[\dabcdef][\dabcdef]:[\dabcdef][\dabcdef]\s+brd',...
                '\s+[\dabcdef][\dabcdef]:[\dabcdef][\dabcdef]:',...
                '[\dabcdef][\dabcdef]:[\dabcdef][\dabcdef]:',...
                '[\dabcdef][\dabcdef]:[\dabcdef][\dabcdef]'];
            
            [msgCell, matches] = strsplit(strtrim(msg), splitExp, 'Delimiter', 'RegularExpression');
            pattern = '\d+:\s+(?<name>\w*):\s+.+state\s+(?<state>\w*)\s+.+link/(?<type>\w*)';
            tmp = regexp(msgCell, pattern, 'names');
            nicinfo = [tmp{:}]; % convert from cell array to struct array
            
            % Find mac address of NICs
            macExp = ['(?<macaddr>[\dabcdef][\dabcdef]:[\dabcdef][\dabcdef]:',...
                '[\dabcdef][\dabcdef]:[\dabcdef][\dabcdef]:',...
                '[\dabcdef][\dabcdef]:[\dabcdef][\dabcdef])\s+brd'];
            tmp1 = regexp(matches, macExp, 'names');
            tmp1 = [tmp1{:}];
            for i = 1: numel(nicinfo)
                nicinfo(i).mac = tmp1(i).macaddr;
            end
            % Eliminate the NICs which are not active
            indx = [];
            for i = 1: numel(nicinfo)
                if strcmp(nicinfo(i).type,'ether') && strcmp(nicinfo(i).state,'UP')
                    indx(end+1) = i;  %#ok<AGROW>
                end
            end
            
            % Warn if no NIC found
            if isempty(indx)
                warning(message('raspi:setup:NoNic'));
                return;
            end
            
            nic = nicinfo(indx);
            
            for i = 1:numel(nic)
                nic(i).connected   = 1; %Set to 1 as status of network is already checked above.
                nic(i).dhcpEnabled = 1; %Filled with 1 as this information is not used for Linux
                nic(i).ip          = obj.loc_GetIpaddress(nic(i).name);
                nic(i).dhcpServer  = 1; % Filled with 1 as this information is not required
                nic(i).index       = i; % Filled with 1 as this information is not required
                nic(i).description = 'Ethernet';
            end
        end
        
        % Mount the SD card after image writing
        function mountDrivePartition(obj)
            % Need to mount the drive partition present in Linux
            % after writing image
            drivePartition =  obj.getDrivePartitionPostImageWriteLinux(obj.SDCardDrive);
            
            % Create mountpoint then mount FAT32 partition (first
            % partition) to it
            mountpoint = '/mnt/boot';
            mntpointstatus = exist(mountpoint,'dir');
            if mntpointstatus == 7
                % -o umask=0 mounts the drive with read/write permissions
                mountcmd = ['mount ' drivePartition ' ' mountpoint ' -o umask=0'];
            else
                % -o umask=0 mounts the drive with read/write permissions
                mountcmd = ['mkdir ' mountpoint ' && mount ' drivePartition ' ' mountpoint ' -o umask=0'];
                
            end
            % Mount Partition
            [~, ~] =  obj.FwUpdateHelper.exec(mountcmd);
        end
        
        function ret = getFilePathForHostName(obj, varargin)
            [status, msg] = obj.isdrivePartitionMounted(obj.SDCardDrive);
            if status
                % Mount the drive partition if it is not already
                % mounted
                obj.mountDrivePartition();
                ret_dir = '/mnt/boot';
            else
                % msg will be of the below format
                % /dev/sdd1  60M   20M   41M  34% /media/boot
                % need to extract the mountpoint say '/media/boot'
                tmp = regexp(msg, '%\s+.*\w', 'match'); % split the string from '%' and after
                driveMountName = regexp(tmp{:}, '/\w.*\w', 'match'); % match the string that begins with '/' word and ends with word
                ret_dir = strtrim(driveMountName{:});
            end
            if nargin > 1
                % If arguments are obj + filename
                fileName = varargin{1};
                ret = fullfile(ret_dir, fileName);
            else
                ret = ret_dir;
            end
        end
        
        function [status, driveList] = getDriveList(obj)
            % Check with latest implementation using FwUpdateHelper
            driveList = {};
            
            % Create a FwUpdateHelper object. This starts FwUpdateHelperApp utility with
            % hidden named pipes on Linux to pass system commands
            % that need "sudo"
            [~, pid] = system('pidof FwUpdateHelperApp');
            if isempty(pid)
                st = obj.FwUpdateHelper.init;
                
                if st
                    obj.FwUpdateHelper.delete;
                    init_msg = message('raspi:hwsetup:RaspberryPiDriveLinux_NoCardInserted').getString;
                    error(message('raspi:hwsetup:RemovableDriveQuery', init_msg));
                end
            end
            %             end
            
            % 'sudo fdisk -l | grep "FAT32"' lists the FAT32 file
            % systems (SD cards > 2Gb are FAT32) in linux
            cmd = 'fdisk -l | grep "FAT32"';
            
            % find the FAT file systems available by sending the
            % system command to FwUpdateHelperApp
            [status, msg]= obj.FwUpdateHelper.exec(cmd);
            
            if status
                msg = message('raspi:hwsetup:RemovableDriveDetectionFailed').getString;
                error(message('raspi:hwsetup:RemovableDriveQuery', msg));
            elseif isempty(msg)
                driveList = {};
                return
            end
            
            % Parse drive list
            % get the drivePartition name in the form of say
            % /dev/mmcblk0p1 or /dev/sdd1 where p1 and 1 are
            % partition numbers respectively
            tmp = regexp(msg,'/dev/\w+','match');
            if ~isempty(tmp)
                driveList = cell(size(tmp)); % create an empty cell of size same as 'tmp'
                
                % get the complete drive name with size for each
                % cell member of 'tmp'
                for i = 1:numel(tmp)
                    driveList{i} = obj.getDriveInfoLinux(tmp{i});
                end
            end
        end % end getDriveList
    end
    
    methods(Static)
        
        function [status, msg] = isdrivePartitionMounted(drive)
            % Check if drive partition is mounted
            % get the drive name with partition number after image writing is done.
            % Usually after image writing only first partition is present say
            % '/dev/sdd1' or '/dev/mmcblk0p1'
            if contains(drive, '/mmcblk')
                drivePartition = [drive 'p1'];
            elseif contains(drive, '/sd')
                drivePartition = [drive '1'];
            end
            
            [status, msg] = system(['df -hl | grep ''' drivePartition '''']);
            
        end
        
        function msg = firmwareTimeOutError()
            msg = 'Exceeds 90 minutes time, click "Write" to try again';
        end
        
        function driveInfoLinux = getDriveInfoLinux(drivePartitionName)
            % Drive can be either /dev/sd* or /dev/mmcblk*, say /dev/sdd1 or
            % /dev/mmcblk0p1 where 1 or p1 indicate partition number. Need to get the
            % complete drive name by removing partition. Also get the size of the drive.
            if ~isempty(regexp(drivePartitionName,'/dev/mmcblk','match'))
                tmp = regexp(drivePartitionName,'p\d+', 'split'); % remove the partition number say p1
            elseif ~isempty(regexp(drivePartitionName,'/dev/sd','match'))
                tmp = regexp(drivePartitionName,'\d', 'split'); % remove the partition number say 1
            else
                tmp = {drivePartitionName};
            end
            
            driveName = tmp{1};
            % Find the size of the whole drive using 'lsblk'. Need to get only the
            % disk name say sdd or mmcblk0
            diskCell = regexp(driveName,'/dev/', 'split');
            diskName = diskCell{2};
            cmd = ['lsblk | grep -w ''' diskName ''''];
            [status, msg] = system(cmd);
            
            if ~status
                driveSize = char(regexp(msg,'\d+.\d+[GM]','match')); %size can be in Gigabytes(G) or Megabytes(M)
            else
                driveSize = 'unknown size';
            end
            % display the drive name as say, /dev/mmcblk0(7.9G) or /dev/sdd(7.9G)
            driveInfoLinux = [driveName '(' driveSize ')'];
        end
        
        function drivePartition = getDrivePartitionPostImageWriteLinux(drive)
            % Get the drive name with partition number after image writing is done.
            % Usually after image writing only first partition is present say
            % '/dev/sdd1' or '/dev/mmcblk0p1'
            if contains(drive, '/mmcblk')
                drivePartition = [drive 'p1'];
            elseif contains(drive, '/sd')
                drivePartition = [drive '1'];
            end
        end
        
        function dd_pid = getPIDddcommandLinux(ddcommand)
            
            ps_cmd = ['pidof ' ddcommand];
            [~, dd_pid] = system(ps_cmd);
        end
        
        function ipaddress = loc_GetIpaddress(interfacename)
            
            cmd = ['ip addr show ' interfacename ' | grep ''inet '''];
            [~, msg] = system(cmd);
            pattern = 'inet\s+(?<ipaddress>.+)/';
            tmp = regexp(msg, pattern, 'names');
            ip = strtrim(tmp.ipaddress);
            
            if ~isempty(ip)
                ipaddress = ip;
            else
                ipaddress = '0.0.0.0';
            end
        end
        
    end
end