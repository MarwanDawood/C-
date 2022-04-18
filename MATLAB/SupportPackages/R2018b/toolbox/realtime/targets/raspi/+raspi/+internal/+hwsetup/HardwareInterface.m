classdef HardwareInterface < handle
    % HardwareInterface - Class that covers all hardware specific
    % callbacks.
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    
    properties(Access = protected)
        LogFile
        ErrorFile
        ImageFile
        FirmwareVersion
        FirmwareName
        FirmwareArchive
        FirmwareMd5Sum
        FirmwareArchiveMd5Sum
        FirmwareArchiveSize
        FirmwareSize
        MWRaspbianObj
        SDCardDrive    = '';
        UseDhcp
        HostName       = '';
        UserName       = '';
        Password       = '';
        BoardType      = '';
        BoardName      = 'raspberrypi';
        IPAddress      = '169.254.0.2';
        NetworkMask    = '255.255.0.0';
        Gateway        = '169.254.0.1';
        NetworkConfigFileName = 'interfaces';
        wpa_supplicantText = '';
        WiFiConfigFileName = 'wpa_supplicant.conf';
        WiFiInterfaceConfig = '';
        USBInterfaceConfig = '';
        NICListFileName = 'iflist.txt';
        BoardFileName = 'hostname';
        ConfigFileName = 'config.txt';
        kernelCmdFileName = 'cmdline.txt';
    end
    
    properties(Constant)
        SDWRITEREXE     = 'sdwriter.exe';
        FIRMWAREXMLNAME = 'firmware_info.xml';
        LOGFILESIZE = 1000;
        DISTRONAME = 'raspbian.instrset';
        PROGRESSUPDATEINTERVAL = 5;
        LOGFILENAME = 'img_writer_log.txt';
        DEFAULTIPADDRESS          = '10.10.10.1';
        DEFAULTPASSWORD           = 'raspberry';
        DEFAULTUSERNAME           = 'pi';
    end
    
    methods(Access=protected)
        
        function saveIPParams(obj)
            hp = raspi.internal.BoardParameters('Raspberry Pi');
            if obj.UseDhcp
                setParam(hp,'HostName', obj.BoardName);
            else
                setParam(hp,'HostName', obj.IPAddress);
            end
            setParam(hp,'Username', obj.DEFAULTUSERNAME);
            setParam(hp,'Password', obj.DEFAULTPASSWORD);
            setParam(hp,'BoardName', obj.BoardName);
        end
        
        function writeNetworkConfig(obj)
            interfaceTxt = [
                'auto lo\n', ...
                'iface lo inet loopback\n', ...
                '\n', ...
                'auto eth0 \n', ...
                ];
            
            if obj.UseDhcp
                interfaceTxt = [
                    interfaceTxt, ...
                    'iface eth0 inet manual\n', ...
                    '\n', ...
                    ];                   
            else
                interfaceTxt = [
                    interfaceTxt, ...
                    'iface eth0 inet static\n', ...
                    'address ', obj.IPAddress, '\n', ...
                    'netmask ', obj.NetworkMask, '\n',...
                    'gateway ', obj.Gateway, '\n',...
                    '\n', ...
                    ];                    
            end
            
            interfaceTxt = [
                interfaceTxt, ...
                obj.USBInterfaceConfig, ...
                obj.WiFiInterfaceConfig, ...
                ];
                       
            filename = obj.getFilePathForHostName(obj.NetworkConfigFileName);
            if isempty(filename)
                error(message('raspi:setup:UnableToAccessMemoryCard'));
            end
            
            fid = fopen(filename, 'w');
            if (fid < 0)
                error(message('raspi:setup:UnableToAccessMemoryCard'));
            end
            fprintf(fid, interfaceTxt);
            fclose(fid);
            
            %write wireless settings
            filename = obj.getFilePathForHostName(obj.WiFiConfigFileName);
            if isempty(filename)
                error(message('raspi:setup:UnableToAccessMemoryCard'));
            end
            fid = fopen(filename, 'w');
            if (fid < 0)
                error(message('raspi:setup:UnableToAccessMemoryCard'));
            end
            fprintf(fid, obj.wpa_supplicantText);
            fclose(fid);           
            
        end
        
        function writeBoardName(obj)
            if ~isequal(obj.BoardName, 'raspberrypi')
                filename = obj.getFilePathForHostName(obj.BoardFileName);
                if isempty(filename)
                    error(message('raspi:setup:UnableToAccessMemoryCard'));
                end
                
                fid = fopen(filename, 'w');
                if (fid < 0)
                    error(message('raspi:setup:UnableToAccessMemoryCard'));
                end
                fprintf(fid, obj.BoardName);
                fclose(fid);
            end
        end
        
        function writeOtgConfig(obj,boardType)
            fileNameConfig = obj.getFilePathForHostName(obj.ConfigFileName);
            fileNameCmd = obj.getFilePathForHostName(obj.kernelCmdFileName);
            
            raspiConfig = fileread(fileNameConfig);
            raspiCmd = fileread(fileNameCmd);
            raspiCmd = strtrim(raspiCmd);
            
            if strcmp(boardType,message('raspi:hwsetup:RaspberryPiZeroW').getString)
                %Enable USB OTG                
                if contains(raspiConfig,'#dtoverlay=dwc2')
                    raspiConfig = strrep(raspiConfig,'#dtoverlay=dwc2','dtoverlay=dwc2');
                end
                
                if ~contains(raspiConfig,'dtoverlay=dwc2')
                    raspiConfig = [raspiConfig, newline, 'dtoverlay=dwc2'];
                end
                
                if ~contains(raspiCmd,'modules-load=dwc2,g_ether')
                    raspiCmd = [raspiCmd, ' modules-load=dwc2,g_ether'];
                end      
            else
                %Disable the OTG to avoid module load error
                if contains(raspiConfig,'dtoverlay=dwc2')
                    raspiConfig = strrep(raspiConfig,'dtoverlay=dwc2','');
                end
                
                if contains(raspiCmd,'modules-load=dwc2,g_ether')
                    raspiCmd = strrep(raspiCmd, ' modules-load=dwc2,g_ether','');
                    raspiCmd = strtrim(raspiCmd);
                end  
            end
            
            %Update cmdline.txt & config.txt
            fid = fopen(fileNameConfig,'w');
            if (fid < 0)
                    error(message('raspi:setup:UnableToAccessMemoryCard'));
            end
            fwrite(fid,raspiConfig);
            fclose(fid);
            
            fid = fopen(fileNameCmd,'w');
            if (fid < 0)
                    error(message('raspi:setup:UnableToAccessMemoryCard'));
            end
            fwrite(fid,raspiCmd);
            fclose(fid);
        end
        
        function obj = HardwareInterface(varargin)
            obj.MWRaspbianObj = raspi.internal.hwsetup.MWRaspbian;
        end
        
        function loadFirmwareInfo(obj, firmwareXml)
            % Load support package information
            domNode = xmlread(firmwareXml);
            pkgrepository = domNode.getDocumentElement();
            firmware = pkgrepository.getElementsByTagName('Firmware');
            % Get attributes of the firmware
            %<Firmware name="%s" archive = "%s" archivesize="%d"
            %downloadurl="%s" firmwaresize="%d" ...
            obj.FirmwareVersion               = str2double(char(firmware.item(0).getAttribute('mwver')));
            obj.FirmwareName        = char(firmware.item(0).getAttribute('name'));
            obj.FirmwareArchive     = char(firmware.item(0).getAttribute('archive'));
            obj.FirmwareArchiveSize = str2double(char(firmware.item(0).getAttribute('archivesize')));
            obj.FirmwareMd5Sum      = char(firmware.item(0).getAttribute('firmwaremd5sum'));
            obj.FirmwareArchiveMd5Sum = char(firmware.item(0).getAttribute('archivemd5sum'));
            obj.FirmwareSize        = str2double(char(firmware.item(0).getAttribute('firmwaresize')));
        end
    end
    
    methods    
        
        function createLogFile(obj,raspbianFldr)
            if ispc
                obj.LogFile = fullfile(raspbianFldr, obj.LOGFILENAME);
            else
                % create the log file in *NIX systems in the temp folder
                % due to write permission issues in 3P download folder
                obj.LogFile = fullfile(tempdir, obj.LOGFILENAME);
            end
            obj.ErrorFile = fullfile(raspbianFldr,'sderr.txt');
            % Clean any left over cruft for logFile and errorFile
            if ispc && (exist(obj.LogFile , 'file') == 2)
                delete(obj.LogFile);
            end
            if (exist(obj.ErrorFile, 'file') == 2)
                delete(obj.ErrorFile);
            end
        end
        
        function status = checkFirmwareImg(obj,raspbianFldr)
            % Check if the firmware has been downloaded and if the
            % downloaded file is of the right size and checksum
            status = true;
            localXmlFile = fullfile(raspbianFldr, obj.FIRMWAREXMLNAME);
            if obj.isFirmwareFileExists(localXmlFile)
                try
                    obj.loadFirmwareInfo(localXmlFile);
                catch
                    status = false;
                    return;
                end
                
                % Check file size to validate whether zip got extracted
                % properly.
                obj.ImageFile = fullfile(raspbianFldr, obj.FirmwareName);
                
                if obj.checkFileSize(obj.ImageFile, obj.FirmwareSize) ~= 0
                    status = false;
                    return;
                end
                
                % Check md5 hash mentioned in xml matches with spkg version
                requiredMd5Hash = obj.MWRaspbianObj.getRaspbianChecksum;
                if ~strcmp(requiredMd5Hash,obj.FirmwareMd5Sum)
                    status = false;
                    warndlg(getString(message('raspi:setup:ImageNotMatching')));
                    return;
                end
            else
                status = false;
            end
            
            %Create log file for write firmware
            if status
                obj.createLogFile(raspbianFldr);
            end
            
        end
        
        function status = checkFirmwarezip(obj,fileName)
            status = false;
            if isequal(exist(fileName,'file'),2)
                expectedZipFileSize = obj.MWRaspbianObj.getRaspbianZipSize;
                fileInfo = dir(fileName);
                actualZipFileSize = fileInfo.bytes;
                status = isequal(expectedZipFileSize,actualZipFileSize);
            end
        end
        
        function out = getRaspbianFolder(obj) %#ok<*MANU>
            out = fullfile(raspi.internal.getRaspiBaseRoot,'raspbian');
        end
        
        function out = getDefaultDownloadFldr(obj)
            if ispc
                out = fullfile(getenv('USERPROFILE'),'Downloads');
            else
                out = fullfile(getenv('HOME'),'Downloads');
            end
        end
        
        function out = getRaspbianName(obj)
            out = obj.MWRaspbianObj.getRaspbianName;
        end
        
        function out = getRaspbianVersion(obj)
            out = obj.MWRaspbianObj.getRaspbianVersion;
        end
        
        function out = getRaspbianDownloadUrl(obj)
            out = obj.MWRaspbianObj.getRaspbianDownloadUrl;
        end
        
        function out = getRaspbianGithub(obj)
            out = obj.MWRaspbianObj.getRaspbianGithub;
        end
        
        function foundRpi = findBoard(obj, board)
            foundRpi = false;
            % Skip hostname check for Pi Zero W
            if strcmp(board,message('raspi:hwsetup:RaspberryPiZeroW').getString)
                raspiList = raspi.internal.findRaspi(board);
            else
                raspiList = raspi.internal.findRaspi(obj.BoardName);
            end
            if ~isempty(raspiList)
                hb = raspi.internal.BoardParameters('Raspberry Pi');
                hb.setParam('hostname', raspiList(1).IpAddress);
                hb.setParam('BoardName', raspiList(1).Hostname);
                foundRpi = true;
            end
        end
        
        function ret = loc_isConnected(obj, nic) %#ok<INUSL>
            ret = ~isempty(nic.ip) && ~isequal(nic.ip, '0.0.0.0');
        end
        
        function setDrive(obj, drivename)
            if ispc
                obj.SDCardDrive = drivename;
            else % for unix
                if ismac
                    [~, tokens] = regexp(drivename, '/Volumes/(.+)\s+\(.*(/dev/disk\d*)','match','tokens');
                    if ~isempty(tokens)
                        obj.SDCardDrive = tokens{1}{2};
                    end
                else
                    obj.SDCardDrive = char(regexp(drivename, '/dev/\w+','match'));
                end
            end
        end
        
        function setBoardName(obj, hostname)
            % set hostname rasberrypi_xyz to BoardName property to store in
            % preference in hostname, board name is confusing good idea to
            % change this in future
            obj.BoardName = hostname;
        end
        
        
        function setUseDhcp(obj, dhcpchoice)
            obj.UseDhcp = (dhcpchoice == 0);
        end
        
        function setStaticIPDetails(obj, workflowObject)
            obj.IPAddress = workflowObject.IPAddress;
            obj.NetworkMask = workflowObject.NetworkMask;
            obj.Gateway = workflowObject.Gateway;
        end
        
        function setUSBInterfaceDetails(obj, boardName)
            % Set auto config for usb0
            if strcmp(boardName, message('raspi:hwsetup:RaspberryPiZeroW').getString) 
                obj.USBInterfaceConfig = [
                    'auto usb0 \n', ...
                    'allow-hotplug usb0\n', ...
                    '\n', ...
                    ];
            else
                obj.USBInterfaceConfig = '';
            end
        end

        function setWirelessDetails(obj, workflowObject)
            % set wpa_supplicant to default
            % country should be set to enable wlan0 interface
            obj.wpa_supplicantText = [
                'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n', ...
                'update_config=1\n', ...
                'country=US\n', ...
                '\n', ...
                ];
            obj.WiFiInterfaceConfig = [
                'allow-hotplug wlan0\n', ...
                'iface wlan0 inet manual\n', ...
                'wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf\n', ...
                '\n', ...
                'allow-hotplug wlan1\n', ...
                'iface wlan1 inet manual\n', ...
                'wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf\n', ...
                ];
            
            if ~workflowObject.ConfigWLAN
                return;
            end
            
            %create the config file
            obj.WiFiInterfaceConfig = [
                'auto wlan0 \n', ...
                'allow-hotplug wlan0\n', ...
                'iface wlan0 inet manual\n', ...
                'wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf\n', ...
                '\n', ...
                'allow-hotplug wlan1\n', ...
                'iface wlan1 inet manual\n', ...
                'wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf\n', ...
                ];
            
            %add ssid
            obj.wpa_supplicantText = [obj.wpa_supplicantText,...
                'network={\n', ...
                '\tssid="',workflowObject.SSIDName,'"\n', ...
                '\tscan_ssid=1\n', ...
                ];
            
            obj.wpa_supplicantText = [obj.wpa_supplicantText,...
                workflowObject.Passphrase, ...
                '}\n', ...
                ];
            
            %Configure wlan0 interface to use dhcp/static ip
            if workflowObject.WLANStaticIP
                obj.WiFiInterfaceConfig = [
                    'auto wlan0 \n', ...
                    'allow-hotplug wlan0\n', ...
                    'iface wlan0 inet static\n', ...
                    'address ', workflowObject.WLANIPAddress, '\n', ...
                    'netmask ', workflowObject.WLANNetworkMask, '\n', ...
                    'gateway ', workflowObject.WLANGateway, '\n', ...
                    'wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf\n', ...
                    '\n', ...
                    'allow-hotplug wlan1\n', ...
                    'iface wlan1 inet manual\n', ...
                    'wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf\n', ...
                    ];
            end
        end
        
        function isConnected = testSSHConnectionLaunchUDPDaemon(obj, hostname, username, password) %#ok<INUSL>
            try
                % Establish an SSH connection to the board
                sshObj = matlabshared.internal.ssh2client(hostname, username, password);
                isConnected = true;
                % Launch the udp_ip if not
                cmdToExe = 'sudo /etc/network/if-up.d/udp_daemon';
                sshObj.execute(cmdToExe);
            catch
                isConnected = false;
            end
        end
        
        function isConnected = testSSHConnection(obj, hostname, username, password) %#ok<INUSL>
            try
                % Establish an SSH connection to the board
                matlabshared.internal.ssh2client(hostname, username, password);
                isConnected = true;
            catch
                isConnected = false;
            end
        end
        
        function discoveredRpi = discoverRpiIP(obj)
            discoveredRpi = false;
            raspiList = raspi.internal.discoverIpAddress(obj.HostName);
            if ~isempty(raspiList)
                for i = 1 : numel(raspiList)
                    if contains(raspiList(i).Hostname, obj.HostName)
                        idx = i;
                        break
                    end
                end
                hb = raspi.internal.BoardParameters('Raspberry Pi');
                hb.setParam('hostname', raspiList(idx).IpAddress);
                discoveredRpi = true;
            end
        end
        
        function dir = getImageDir(~, workflowObject, subfoldername)
            dir = fullfile(workflowObject.ResourcesDir, subfoldername);
        end
        
        function checkWritePremission(obj)
            testFile = 'driveWriteTest';
            testFileFullPath = obj.getFilePathForHostName(testFile);
            fileId = fopen(testFileFullPath,'w');
            if fileId < 0
                %No write access for SD card
                error(getString(message('raspi:setup:NoWritePremission')));
            else
                fclose(fileId);
                if exist(testFile, 'file')==2
                    delete(testFile);
                end
            end
        end
        
    end
    
    methods (Static)
        
        function out = getInstance()
            if ispc
                out = raspi.internal.hwsetup.WindowsHardwareModule();
            elseif ismac
                out = raspi.internal.hwsetup.MACHardwareModule();
            else
                out = raspi.internal.hwsetup.LinuxHardwareModule();
            end
            
        end
    end
    
    methods(Abstract)
        writeIfList(obj)
        [status, msg] = writeFirmware(obj)
        out = getFirmwareWritePercentComplete(obj)
        out = isFirmwareWriteTimeout(obj, val)
        status = checkSSHentry(obj, ipAddress)
        nic = getNics(obj)
        rPiNics = detectNics(obj, nics)
        configureNicForDhcp(obj, nic)
        addStaticRoute(obj, nic)
        cmd =  getImageWriteCmd(obj)
        killWriteImage(obj, cmd)
        configureBoard(obj, boardName)
        out = getFilePathForHostName(obj, filename)
        [status, driveList] = getDriveList(obj)
    end
    
    methods(Abstract, Static)
        msg = firmwareTimeOutError()
        ipaddress = loc_GetIpaddress(interfacename)
    end
    
    
    methods (Static)
        
        function status = checkFileSize(fullFileName, fileSize)
            status = -1; % Return under if file does not exist
            
            fileInfo = dir(fullFileName);
            if ~isempty(fileInfo)
                if (fileInfo.bytes == fileSize)
                    status = 0; % Perfect match
                elseif (fileInfo.bytes > fileSize)
                    status = 1; % Over
                else
                    status = -1; % Under
                end
            end
        end
        
        function ret = loc_Isdhcpenabled(interfacename)
            cmd = ['networksetup -getinfo ' '"' interfacename '"'];
            [~, msg] = system(cmd);
            
            if contains(msg,'DHCP Configuration')
                ret = 1;
            else
                ret = 0;
            end
        end
        
        function piNic = chooseNic(nic)
            if isequal(numel(nic),1)
                piNic = nic;
            else
                nicNames = cell(1, numel(nic));
                for i = 1:numel(nic)
                    nicNames{i} = [nic(i).name, ' (', nic(i).description, ')'];
                end
                [indx, ok] = listdlg('Name', 'Hardware Setup for Raspberry Pi', ...
                    'PromptString', ...
                    DAStudio.message('raspi:setup:ChooseNic'), ...
                    'ListString', nicNames, ...
                    'SelectionMode', 'single', ...
                    'ListSize', [400, 100]);
                drawnow;
                if ~ok
                    error(message('raspi:setup:MustChooseNic'));
                end
                piNic = nic(indx);
            end
        end
        
        function out = isFirmwareFileExists(localXmlFile)
            out = exist(localXmlFile, 'file') == 2;
        end
        
        function str = doubleQuotes(str)
            str = ['"', str, '"'];
        end
        
        function out = getRaspbianDownloadFolder(distroname)
            out = matlab.internal.get3pInstallLocation(distroname);
        end
        
        function errorstatus = checkValidIp(ip, argName)
            if ~ischar(ip)
                error(message('raspi:hwsetup:InvalidArgument', argName));
            end
            
            % Make sure that IP address format is valid
            ip = strtrim(ip);
            % Validating IP requires checking all 32 bits or 4 number sets
            % separated by dots.
            % First Number set has to follow these three rule
            % 1) Starts with 0 or 1 followed by two \d(numbers 0-9) E.g. 4.xxx.xxx.xxx or
            % 129.xxx.xxx
            % 2) Starts with 2 followed by 0 to 4 and \d E.g
            % 246.xxx.xxx.xxx
            % 3) Starts with 25 followed by 0 to 5 E.g. 255.xxx.xxx.xxx
            
            % Second, third and fourth number has to follow the same rules
            % as above E.g. 4.246.169.1, 255.246.169.189, 227.34.78.7
            
            pattern = ['^([01]?\d\d?|2[0-4]\d|25[0-5])\.', ...
                '([01]?\d\d?|2[0-4]\d|25[0-5])\.', ...
                '([01]?\d\d?|2[0-4]\d|25[0-5])\.', ...
                '([01]?\d\d?|2[0-4]\d|25[0-5])$'];
            tmp = regexp(ip, pattern, 'match', 'once');
            if (isempty(tmp) || ~isequal(tmp, ip))
                drawnow;
                % drawnow is required to synchronize calls from getNextScreen callback and
                % valuechanged callback from edit text. Without pause, sometimes the
                % GUI to bring errordlg (pop up window if validation fails)
                % from valuechangedcbk is delayed causing an error free scenario which
                % takes to the next screen and then error dlg comes
                % up.
                errorstatus = true; %#ok<NASGU>
                errorhandle = findall(0,'type','figure','Tag', message('raspi:hwsetup:HWSetupValidationErrorTag').getString);
                if isempty(errorhandle)
                    error(message('raspi:hwsetup:InvalidIpAddress', ip));
                else
                    close(errorhandle);
                    error(message('raspi:hwsetup:InvalidIpAddress', ip));
                end
            else
                errorstatus = false;
            end
        end% end checkValidIp
        
    end
    
    
end
