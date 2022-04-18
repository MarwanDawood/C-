classdef WindowsHardwareModule < raspi.internal.hwsetup.HardwareInterface
    % WindowsHardwareModule - Class that covers all hardware specific
    % callbacks in Windows.
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    
    properties(Constant)
        MAXUPDATECOUNT = 240; % Change timeout to 1200s to support class 4 SD cards
    end
    
    methods
        function writeIfList(obj,boardName)
            nic = mxgetnicinfo();
            indx = [];
            for i = 1:numel(nic)
                
                if ~isempty(nic(i).mac) && (length(nic(i).mac) >= 8) && ~isequal(nic(i).mac(1:8), '00-50-56') ...
                        && isempty(regexpi(nic(i).name, 'vmware')) && isempty(regexpi(nic(i).description, 'vmware'))  ...
                        && isempty(regexpi(nic(i).name, 'virtual')) && isempty(regexpi(nic(i).description, 'virtual'))
                    indx(end+1) = i; %#ok<AGROW>
                end
            end
            if isempty(indx)
                warning(message('raspi:setup:NoNic'));
                return;
            end
            nic = nic(indx);
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
            %Add link-local broadcast IP address for Raspi Zero W
            if strcmp(boardName,message('raspi:hwsetup:RaspberryPiZeroW').getString)
                linkLocalBcast = '192.168.9.255';
                fprintf(fid, '%s\n', linkLocalBcast);
            end
            fclose(fid);
        end
        
        function configureBoard(obj,boardName)
            obj.writeBoardName;
            obj.writeNetworkConfig;
            obj.writeIfList(boardName);
            obj.writeOtgConfig(boardName);
            obj.saveIPParams;
        end
        
        function killWriteImage(~, cmd)
            % We do not want the system call to error out. So we get dummy
            % outputs out of the system call (suppresses error).
            % Examples:
            % > tasklist /fi "Imagename eq sdwriter" /fo csv
            % INFO: No tasks are running which match the specified criteria.
            % > tasklist /fi "Imagename eq sdwriter.exe" /fo csv
            %   "Image Name","PID","Session Name","Session#","Mem Usage"
            %   "sdwriter.exe","10176","Console","1","5,492 K"
            [st, msg] = system(['tasklist /fi "Imagename eq ' cmd '" /fo csv']);
            if st == 0 && ~isempty(regexp(msg,cmd,'once'))
                [~,~] = system(['taskkill /F /T /IM ', cmd], ...
                    '-runAsAdmin');
            end
            
        end
        
        function out = isFirmwareWriteTimeout(obj, val)
            out = obj.MAXUPDATECOUNT < val;
        end
        
        function  cmd =  getImageWriteCmd(obj, ~)
            cmd = obj.SDWRITEREXE;
        end
        function [status, msg] = writeFirmware(obj)
            sdWriterPath = fullfile(raspi.internal.getRaspiRoot, ...
                'bin', computer('arch'));
            drive = strrep(obj.SDCardDrive,':',''); % drive path without colon
            
            cmd = ['start /B /D ', ...
                obj.doubleQuotes(sdWriterPath), ' ', obj.SDWRITEREXE...
                ' -d ', drive, ...
                ' -f ', obj.doubleQuotes(obj.ImageFile), ...
                ' -o ', obj.doubleQuotes(obj.LogFile), ...
                ' > ',  obj.doubleQuotes(obj.ErrorFile)];
            [status, msg] = system(cmd, '-runAsAdmin');
            
        end
        
        function out = getFirmwareWritePercentComplete(obj)
            errInfo  = dir(obj.ErrorFile);
            out = 0;
            if ~isempty(errInfo) && (errInfo.bytes > 0)
                errMsgTxt = fileread(obj.ErrorFile);
                error(message('raspi:hwsetup:ErrorWritingFirmware', ...
                    errMsgTxt));
            end
            
            fileInfo = dir(obj.LogFile);
            if ~isempty(fileInfo)
                if (fileInfo.bytes == obj.LOGFILESIZE)
                    out = 100;
                    return;
                end
                out = (fileInfo.bytes / obj.LOGFILESIZE)*100;
            end
        end
        
        function status = checkSSHentry(obj, ipAddress) %#ok<INUSD>
            % Nothing to do for Windows
            status = 0;
        end
        
        function addStaticRoute(obj, nic) %#ok<INUSL>
            cmd = ['netsh interface ipv4 add route prefix=169.254.0.0/16 ', ...
                'interface="', nic.name,'" metric=5'];
            [st, msg] = system(cmd, '-runAsAdmin');
            if (st ~= 0)
                warning(message('raspi:setup:CannotAddRoute', msg));
            end
        end
        
        function configureNicForDhcp(obj, nic) %#ok<INUSL>
            if ~nic.dhcpEnabled
                cmd = ['netsh interface ip set address "', nic.name '" dhcp'];
                [st, msg] = system(cmd, '-runAsAdmin');
                if (st ~= 0)
                    error('raspi:setup:ErrorWhileConfiguringNic', msg);
                end
            end
        end
        
        function rPiNics = detectNics(obj, nics)
            rPiNics = [];
            for i = 1:numel(nics)
                nicInfo = mxgetnicinfo();
                thisNic = [];
                for j = 1:numel(nicInfo)
                    if isequal(nics(i).mac, nicInfo(j).mac)
                        thisNic = nicInfo(j);
                        break;
                    end
                end
                if ~isempty(thisNic) && obj.loc_isConnected(thisNic)
                    nics(i).ip = thisNic.ip;
                    cmd = ['ping -n 1 169.254.0.2 -S ', nics(i).ip];
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
            % Find NIC's on the host computer
            % List physical interfaces in CSV format
            cmd = 'getmac /fo csv /v /nh';
            [st, msg] = system(cmd, '-runAsAdmin');
            if (st ~= 0)
                warning(message('raspi:setup:ErrorWhileQueryingNic', msg));
                return;
            end
            
            % Extract NIC information from CSV formatted data returned by
            % getmac
            pattern = '"(?<name>[^"]+)","(?<description>[^"]+)","(?<mac>[^"]+)","(?<device>[^"]+)"';
            nic = regexp(msg, pattern, 'names');
            if isempty(nic)
                warning(message('raspi:setup:NoNic'));
                return;
            end
            
            % Eliminate virtual, VMWare, Wi-Fi adapters. Note VMWAre
            % adapters have mach addresses of the form: 00-50-56-xx-yy-zz
            indx = [];
            for i = 1:numel(nic)
                if ~isempty(nic(i).mac) && (length(nic(i).mac) >= 8) && ~isequal(nic(i).mac(1:8), '00-50-56') ...
                        && isempty(regexpi(nic(i).name, 'vmware')) && isempty(regexpi(nic(i).description, 'vmware'))  ...
                        && isempty(regexpi(nic(i).name, 'virtual')) && isempty(regexpi(nic(i).description, 'virtual'))  ...
                        && isempty(regexpi(nic(i).name, 'wireless')) && isempty(regexpi(nic(i).description, 'wireless')) ...
                        && isempty(regexpi(nic(i).name, 'wi-fi')) && isempty(regexpi(nic(i).description, 'wi-fi'))
                    indx(end+1) = i; %#ok<AGROW>
                end
            end
            if isempty(indx)
                warning(message('raspi:setup:NoNic'));
                return;
            end
            nic = nic(indx);
            
            % Find out if DHCP, connected properties for all NIC's
            nicinfo = mxgetnicinfo();
            for i = 1:numel(nic)
                % Default to connected. This will be re-evaluated in a loop later
                thisNic = [];
                for j = 1:numel(nicinfo)
                    if isequal(nic(i).mac, nicinfo(j).mac)
                        thisNic = nicinfo(j);
                        break;
                    end
                end
                nic(i).connected   = obj.loc_isConnected(thisNic);
                nic(i).dhcpEnabled = thisNic.dhcpEnabled;
                nic(i).ip          = thisNic.ip;
                nic(i).dhcpServer  = thisNic.dhcpServer;
                nic(i).index       = thisNic.index;
            end
        end
        
        
        function ret = getFilePathForHostName(obj, fileName)
            % ':'(colon) is removed during WriteFirmware, so we need to add again
            % to access the filesystem
            ret = fullfile(obj.SDCardDrive, fileName);
        end
        
        function [status, driveList] = getDriveList(obj) %#ok<MANU>
            driveList = {};
            cmd = 'wmic logicaldisk get deviceid, drivetype, volumename';
            [status, msg] = system(cmd);
            if(status)
                % Cannot execute WMI script, catch the error message.
                error(message('raspi:hwsetup:WMIErrorMessage', msg));
            end
            % Pattern:
            % <DeviceID>\w: Assigns drive letter(alphanumeric) ending with colon(:) to
            % DeviceID. (e.g. G:)
            % <DriveType>[\w\-]: Assigns drivetype (alphanumeric) which follows drive letter 
            % and a non white space character to DriveType. (e.g. 2 is the drive type for removable disk)
            pattern = '(?<DeviceID>\w:)\s+(?<DriveType>[\w\-]*)\s+';
            % msg - character array is pattern matched to create structure
            % with DeviceID and DriveType fields, which contains drive
            % letter and disk type respectively.
            driveinfo = regexp(msg, pattern, 'names');
            removableDiskType = '2';
            out = contains({driveinfo.DriveType}, removableDiskType);
            index = find(out);
            if ~isempty(index)
                for i=1:numel(index)
                    driveList{i} = driveinfo(index(i)).DeviceID; %#ok<AGROW>
                end
            end
        end % end getDriveList
    end
    
    methods(Static)
        
        function msg = firmwareTimeOutError()
            msg = 'Firmware write has timed out, try again';
        end
        
        function ipaddress = loc_GetIpaddress(interfacename) %#ok<STOUT,INUSD>
            %Empty Implementation
        end
    end
end