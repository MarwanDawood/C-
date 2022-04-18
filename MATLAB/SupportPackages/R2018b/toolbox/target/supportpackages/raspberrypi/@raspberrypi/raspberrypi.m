classdef raspberrypi < matlabshared.internal.LinuxSystemInterface & ...
        matlab.mixin.CustomDisplay 
    %RASPBERRYPI Access Raspberry Pi hardware.
    %
    % obj = RASPBERRYPI(DEVICEADDRESS, USERNAME, PASSWORD) creates a
    % RASPBERRYPI object connected to the Raspberry Pi hardware at
    % DEVICEADDRESS with login credentials USERNAME and PASSWORD. The
    % DEVICEADDRESS can be an IP address such as '192.168.0.10' or a
    % hostname such as 'raspberrypi-MJONES.foo.com'.
    %
    % obj = RASPBERRYPI() creates a RASPBERRYPI object connected
    % to a Raspberry Pi hardware using saved values for DEVICEADDRESS,
    % USERNAME and PASSWORD.
    %
    %
    %METHODS:
    %
    % output = SYSTEM(obj,command) executes the Linux command on the
    % Raspberry Pi hardware and returns the resulting output.
    %
    % LOADMODEL(obj,modelName) loads a previously compiled Simulink
    % model to the Raspberry Pi hardware.
    %
    % RUNMODEL(obj,modelName) runs a previously compiled Simulink
    % model on the Raspberry Pi hardware.
    %
    % STOPMODEL(obj,modelName) stops the execution of a Simulink model on
    % the Raspberry Pi hardware.
    %
    % [status, pid] = ISMODELRUNNING(obj,modelName) returns run status and
    % the process ID of a specified Simulink model. If the model is running
    % on the Raspberry Pi hardware the return value for status is true.
    % Otherwise, the return value for status is false.
    %
    % GETFILE(obj,remoteSource,localDestination) copies the remoteSource
    % on the Raspberry Pi hardware to the localDestination on the local
    % host computer. The input parameter, localDestination, is optional. If
    % not specified, the remoteSource is copied to the current directory.
    %
    % PUTFILE(obj,localSource,remoteDestination) copies the localSource
    % on the local host computer to the remoteDestination on the Raspberry
    % Pi hardware. The input parameter, remoteDestination, is optional.
    % If not specified, the remoteDestination is copied to the user's home
    % directory on the Raspberry Pi hardware.
    %
    % DELETEFILE(obj,remoteFile) deletes remoteFile on the Raspberry Pi
    % hardware.
    %
    % OPENSHELL(obj) launches a SSH terminal session. Once the terminal
    % session is started, you can execute commands on the Raspberry Pi
    % hardware interactively.
    %
    % ADDTORUNONBOOT(obj,modelName) adds a Simulink model to Run-on-boot so
    % that the model automatically starts to run each time you restart the
    % Raspberry Pi. Model elf should be available in the home directory or
    % else you need to provide absolute path to elf.
    %
    % modelName = GETRUNONBOOT(obj) returns the name of the Simulink model
    % added to Run-on-boot.
    %
    % REMOVERUNONBOOT(obj) removes the Simulink model from Run-on-boot.
    %
    % STARTROSCORE(obj,catkinWs) launches roscore application on the
    % Raspberry Pi hardware using specified Catkin workspace with the
    % default port number 11311. 
    %
    % STARTROSCORE(obj,catkinWs,port) launches roscore application with
    % the specified Catkin workspace and port number.
    %
    % STOPROSCORE(obj) terminates roscore application running on the
    % Raspberry Pi hardware.
    %
    % RUNROSNODE(obj,modelName,catkinWs) runs the ROS
    % node generated from the given model on the Raspberry Pi hardware
    % using the specified Catkin workspace. The running node uses the
    % ROS master specified for simulation in Tools > Robot Operating System
    % > Configure Network Addresses GUI.
    %
    % RUNROSNODE(obj,modelName,catkinWs,rosMasterUri,rosIP) runs the ROS
    % node generated from the given model with specified ROS master and ROS
    % node IP.
    %
    % Examples:
    %
    %  r = raspberrypi;
    %  system(r,'ls -al ~')
    %
    %  lists the contents of the home directory for the current user on the
    %  Raspberry Pi hardware.
    %
    %  runModel(r,'raspberrypi_gettingstarted')
    %
    %  runs the model 'raspberrypi_gettingstarted' on the Raspberry Pi
    %  hardware. The model must be previously run on the Raspberry Pi
    %  hardware for this method to work properly.
    %
    %  getFile(r,'/home/debian/img0.dat')
    %
    %  copies the file 'img0.dat' in the '/home/debian' directory of the
    %  Raspberry Pi hardware to the current directory on the host
    %  computer.
    %
    %  putFile(r,'img0.dat','/home/debian')
    %
    %  copies the file 'img0.dat' in the current directory on the host
    %  computer to the '/home/debian' directory on the Raspberry Pi
    %  hardware.
    %
    %  openShell(r)
    %
    %  launches a PuTTY SSH terminal session. After logging into the Linux
    %  shell, you can execute interactive shell commands.
    %
    %  addToRunOnBoot(r,'raspberrypi_gettingstarted')
    %
    %  adds the model 'raspberrypi_gettingstarted' to Run-on-boot. The
    %  model must be previously deployed on the Raspberry Pi hardware for
    %  this method to work properly.
    %
    %  getRunOnBoot(r)
    %
    %  shows the Simulink model name added to Run-on-boot.
    %
    %  removeRunOnBoot(r)
    %
    %  removes the Simulink model from Run-on-boot.
    
    % Copyright 2015-2018 The MathWorks, Inc.
    
    properties (Dependent, GetAccess = public)
        DeviceAddress
    end
    
    properties (SetAccess = private, GetAccess = public)
        Port = 22
    end
    
    properties (Hidden)
        Ssh
        BuildDir
    end
    
    properties (Hidden, Constant)
        % Constant used for storing board parameters
        BoardPref = 'Raspberry Pi';
    end
    
    
    methods (Hidden)
        function obj = raspberrypi(hostname, username, password, port)
            % Create a connection to Raspberry Pi hardware.
            narginchk(0, 4);
            if nargin > 3
                % In case SSH port is not 22
                obj.Port = port;
            end
            
            % Register the error message catalog location
            [~] = registerrealtimecataloglocation(...
                codertarget.raspi.internal.getSpPkgBaseRootDir);
            
            %% Retrieve connection parameters
            hb = realtime.internal.BoardParameters(obj.BoardPref);
            if nargin < 1
                hostname = hb.getParam('hostname');
                if isempty(hostname)
                    error(message('raspberrypi:utils:InvalidDeviceAddress'));
                end
            end
            if nargin < 2
                username = hb.getParam('username');
                if isempty(username)
                    error(message('raspberrypi:utils:InvalidUsername'));
                end
            end
            if nargin < 3
                password = hb.getParam('password');
            end
            
            % Create an SSH client
            if ~isequal(hostname,'localhost') && ...
                    ~isequal(hostname,'127.0.0.1')
                obj.Ssh = matlabshared.internal.ssh2client(hostname, ...
                    username, password, obj.Port);
            end
            obj.BuildDir = codertarget.raspi.getRemoteBuildDir;
            
            % Store board parameters for a future session
            setParam(hb,'hostname',hostname);
            setParam(hb,'username',username);
            setParam(hb,'password',password);
        end
    end
    
    methods
        % GET / SET methods
        function value = get.DeviceAddress(obj)
            value = obj.Ssh.Hostname;
        end
        
        function set.Port(obj,value)
            validateattributes(value,{'numeric'},...
                {'scalar','>=',1,'<=',2^16-1},'','Port');
            obj.Port = double(value);
        end
    end
    
    methods (Access = public, Hidden)
        function msg = connect(~,~) %#ok<STOUT>
            warning(message('raspberrypi:utils:ConnectDeprecated'));
        end
        
        function run(obj,modelName,~,args,~)
            warning(message('raspberrypi:utils:DeprecatedMethod', ...
                'run','runModel'));
            runModel(obj,modelName,args);
        end
        
        function stop(obj,modelName)
            % stop(obj, modelname) stops execution of specified model.
            warning(message('raspberrypi:utils:DeprecatedMethod', ...
                    'stop','stopModel'));
            stopModel(obj,modelName);
        end
        
        function [status, msg] = execute(obj,cmd,echooutput)
            % runcmd(obj, cmd)
            warning(message('raspberrypi:utils:DeprecatedMethod', ...
                    'execute','system'));
            narginchk(2, 3);
            if nargin < 3
                echooutput = false;
            end
            if ~isscalar(echooutput) || ~isa(echooutput, 'logical')
                error(message('realtime:utils:InvalidEchoOutput'));
            end
            try
                msg = system(obj,cmd);
                status = 0;
                if echooutput
                    disp(msg);
                end
            catch ME
                status = 1;
                msg = ME.message;
            end
        end
    end % Public methods for backward compatibility
    
    methods (Access = public)
        function logFile = startroscore(obj,catkinWs,port)
            % startroscore(obj,catkinWs) Starts roscore application using
            % given Catkin workspace with the default port number 11311 on
            % the connected Raspberry Pi board.
            %
            % startroscore(obj,catkinWs,port) Uses the specified port
            % number. Port number must be between 1000 and 65535.
            if nargin < 3
                port = 11311;
            else
                validateattributes(port,{'numeric'},...
                    {'scalar','integer','>=',1000,'<',2^16-1},'startroscore','port');
            end

            % Check if roscore is running
            if i_isExecutableRunning(obj,'roscore')
                error('raspberrypi:utils:RoscoreAlreadyRunning',...
                    'roscore application is already running.');
            else
                % Check if catkinWs is valid
                setupBash = [catkinWs '/devel/setup.bash'];
                try
                    system(obj,['stat ' setupBash]);
                catch
                    error('raspberrypi:utils:InvalidCatkinWorkspace',...
                        ['Invalid Catkin workspace. ' ...
                        'Cannot find %s under the specified Catkin workspace.'],...
                        setupBash);
                end
                
                % Now run roscore application
                [~,b] = fileparts(tempname);
                logFile = ['/tmp/roscore_' b '.log'];
                cmd = ['export ROS_MASTER_URI=http://' ...
                    obj.DeviceAddress ':' num2str(port) ...
                    '; source ' setupBash '; roscore &> ' logFile ' &'];
                system(obj,cmd);
                pause(2);
                if ~i_isExecutableRunning(obj,'roscore')
                    logOut = system(obj,['tail ' logFile]);
                    error('raspberrypi:utils:RoscoreDidNotStart',...
                        'roscore application did not start. Details: %s',logOut);
                end
            end
        end
        
        function stoproscore(obj)
            %stoproscore(obj)
            try
                system(obj,'sudo killall roscore');
            catch
                error('raspberrypi:utils:RosCoreNotRunning',...
                    'Nothing to stop. roscore process is not running.');
            end
        end
        
        function runROSNode(obj,modelName,catkinWs,rosMasterUri,rosIP)
            narginchk(3, 5);
            if nargin < 4
                rosMasterUri = codertarget.raspi.ros.getMasterUri(obj);
            end
            if nargin < 5
                rosIP = obj.DeviceAddress;
            end
            modelName = lower(modelName); % All ROS nodes are lower case
            nodeName = [modelName,'_node'];
            nodePath = [catkinWs,'/devel/lib/',modelName];

            % Run ROS node. Should we set ROS_MASTER_URI here?
            cmd = ['export DISPLAY=:0.0; export XAUTHORITY=~/.Xauthority; ' ...
                'export ROS_MASTER_URI=' rosMasterUri '; export ROS_IP=' rosIP '; '...
                'sudo -E bash -c ' nodePath '/' nodeName ' &> ' nodeName '.log &'];
            system(obj,cmd);
            
            % Check if ROS node has launched correctly
            cmd = ['n=0; while [ ! `pidof ' nodeName '` ] '...
                '&& [ $n -lt  10 ]; do n=$((n+1)); sleep 1; done; echo $n'];
            n = str2double(system(obj,cmd));
            if ~isnan(n) && n == 10
                logFile = [nodeName '.log'];
                try
                    out = system(obj,['cat ' logFile]);
                catch
                    out = '';
                end
                error(message('raspberrypi:utils:ROSNodeDidNotStart',logFile,out));
            end
        end
        
        function stopROSNode(obj,modelName)
            nodeName = [modelName,'_node'];
            stopExecutable(obj,nodeName);
        end
    
        function [ret, pid] = isModelRunning(obj, modelName)
            % [ret, pid] = ISMODELRUNNING(obj, modelName) Reports run
            % status of a Simulink model.
            try
                pid = str2num(obj.system(['pgrep -f ', modelName])); %#ok<ST2NM>
                ret = true;
            catch
                ret = false;
                pid = [];
            end
        end
        
        function runModel(obj,modelName,args)
            % RUNMODEL(obj, modelName) runs a Simulink model
            % on Raspberry Pi hardware.
            if nargin < 3 || isempty(args)
                args = '';
            else
                validateattributes(args,{'char'},{'row'},'runModel',...
                    'args');
            end
            validateattributes(modelName,{'char'},{'nonempty','row'}, ...
                'runModel','modelName');
            
            % Find executable name in Simulink workspace folder on remote
            % file system
            exeName = [modelName '.elf'];
            try
                % Find modelName.elf file
                out = system(obj,['find ' obj.BuildDir ' -name ' exeName]);
            catch
                error(message('raspberrypi:utils:ModelNotAvailable',modelName));
            end
            if isempty(out)
                error(message('raspberrypi:utils:ModelNotAvailable',modelName));
            end
            
            % Find full path of the application
            tmp = regexp(out,'\n','split'); 
            exeFileFullPath = tmp{1}; % There is always a \n at the end of the list printed out by find
            cmd = ['export DISPLAY=:0.0; export XAUTHORITY=~/.Xauthority; ' ...
                'sudo ', exeFileFullPath ' ' args , ' &> ', modelName, '.log &'];
            system(obj,cmd);
        end
        
        function loadModel(obj, modelName)
            %LOADMODEL(obj, modelName) loads a Simulink model to Raspberry
            %Pi hardware.
            validateattributes(modelName, {'char'}, {'nonempty', 'row'}, ...
                '', 'modelName');
            exe = [modelName '.elf'];
            exeFullPath = which(exe);
            if isempty(exeFullPath)
                exeFullPath = exe;
            end
            if exist(exeFullPath, 'file') ~= 2 
                error(message('raspberrypi:utils:CannotLocateModelExecutable',modelName));
            end
            system(obj,['rm -f ', exe]); % Unlink executable before copying over 
            putFile(obj,exeFullPath);           
            system(obj,['chmod u+x ', exe]);
        end
        
        function stopModel(obj, modelName)
            % STOPMODEL(obj, modelname) stops execution of a Simulink model.
            validateattributes(modelName, {'char'}, {'nonempty', 'row'}, ...
                '', 'modelName');     
            exe = [modelName '.elf'];
            system(obj,['killall ', exe], 'sudo');
        end
        
        function runExecutable(obj,exe,args)
            % RUNAPPLICATION(obj,exe,args) runs an executable
            % on Raspberry Pi hardware.
            if nargin < 3 || isempty(args)
                args = '';
            else
                validateattributes(args,{'char'},{'row'},...
                    'runExecutable','args');
            end
            validateattributes(exe,{'char'},{'nonempty','row'},...
                '','exeFullPath');
                 
            % Check if executable is available on hardware
            try
                system(obj, ['ls ' exe]);
            catch ME
                error(message('raspberrypi:utils:ExeNotAvailable',exe));
            end
            
            % Run executable. stdout/stderr goes to logfile
            [p,n] = fileparts(exe);
            if isempty(p)
                exe = ['./' exe];
                logFile = n;
            else
                logFile = obj.fullLnxFile(p,n);
            end
            cmd = ['export DISPLAY=:0.0; export XAUTHORITY=~/.Xauthority; ' ...
                'sudo ' exe ' ' args ' &> ' logFile '.log &'];
            system(obj, cmd, 'sudo');
        end
        
        function loadExecutable(obj, exeFullPath)
            %LOADEXECUTABLE(obj, exe) loads an executable to Raspberry Pi
            % hardware.
            validateattributes(exeFullPath,{'char'},...
                {'nonempty','row'},'loadExecutable','exe');
            if exist(exeFullPath, 'file') ~= 2 
                error(message('raspberrypi:utils:ExecutableDoesNotExist',exeFullPath));
            end
            exe = i_getExe(exeFullPath);
            system(obj,['rm -f ', exe]); % Unlink executable before copying over 
            putFile(obj, exeFullPath);           
            system(obj,['chmod u+x ', exe]);
        end
        
        function stopExecutable(obj, exe)
            % STOPEXECUTABLE(obj, exe) stops an executable running on
            % Raspberry Pi hardware.
            validateattributes(exe,{'char'},...
                {'nonempty','row'},'stopExecutable','exe');   
            exe = i_getExe(exe); % Don't need full path
            system(obj, ['killall ', exe], 'sudo');
        end
        
        function killProcess(obj,pid)
            % KILLPROCESS(obj,pid) kills the process with given pid.
            % PID can be a string representing process numbers or an array
            % of numeric values.
            if isnumeric(pid)
                validateattributes(pid,{'numeric'},...
                    {'integer','positive','row'},...
                    'killProcess','pid');
                cmd = ['kill -9 ', sprintf('%d ',pid)];
            elseif ischar(pid)
                cmd = ['kill -9 ', sprintf('%s ',pid)];
            else
                error(message('raspberrypi:utils:InvalidProcessId'));
            end
            try
                system(obj,cmd,'sudo');
            catch
            end
        end
        
        function killApplication(obj,appName)
            % KILLAPPLICATION(obj, appName) stops execution of an application.
            validateattributes(appName,{'char'},{'nonempty','row'}, ...
                '', 'appName');
            system(obj,['killall ' appName],'sudo');
        end
        
        function openShell(obj)
            %OPENSHELL opens an interactive command shell to Raspberry Pi
            % hardware.
            openShell(obj.Ssh);
        end
        
        function modelName = getRunOnBoot(obj)
            %GETRUNONBOOT function will show the model name that will start
            %automatically after reboot.
            try
                startupScript = strtrim(system(obj,'cat /usr/local/bin/MW_runSimulinkModel'));
            catch
                modelName = {};
                return;
            end
            C = strsplit(startupScript,newline);
            index = find(contains(C,'elf'));
            if isempty(index)
                modelName = {};
            else
                [~, name, ~] = fileparts(startupScript);
                modelName = name;
            end
        end
        
        function addToRunOnBoot(obj,modelName)
            %ADDTORUNONBOOT function will add the model name to startup
            %script. Model elf should be available in the home directory or
            %else the user should give the absolute path to elf.
            
            %Remove extension if any
            [pathStr,name,ext] = fileparts(modelName);
            if isempty(ext)
                ext = '.elf';
            end
            if isempty(pathStr)
                pathStr = '~';
            end
            fileNameToCheck = [pathStr,'/',name,ext];
            %Check model name exist in Raspberry Pi
            fileCheck = ['test -e ',fileNameToCheck,' ; echo $?'];
            try 
               fileStatus = strtrim(system(obj,fileCheck));
            catch
                % Error in execution system command
                error(message('raspberrypi:utils:InvalidModelName'));
            end
            
            if strcmp(fileStatus,'0')
                %Model elf exist in Raspberry Pi SD card
                %Get the full path for the file using readlink
                getFileFullPathCmd = ['readlink -f ', fileNameToCheck];
                fileFullPath = strtrim(system(obj,getFileFullPathCmd));
            else
                %Cannot find model elf in SD card
                error(message('raspberrypi:utils:InvalidModelName'));
            end
            
            %Add model name to startup script
            codertarget.raspi.addToStartup(obj,fileFullPath);
        end
        
        function removeRunOnBoot(obj)
            %REMOVERUNONBOOT function will remove the model name from
            %starutp.
            modelName = obj.getRunOnBoot;
            if ~isempty(modelName)
                codertarget.raspi.removeFromStartup(obj);
            end
        end
    end
    
    methods (Access = public, Hidden)
        function saveInfo = saveobj(obj)
            saveInfo.DeviceAddress = obj.DeviceAddress; 
        end
        
        function disableScreen(obj)
            system(obj,'tvservice -o');
        end
        
        function enableScreen(obj)
            system(obj,'tvservice -p && fbset -depth 8 && fbset -depth 16');
        end
    end
    
    methods (Static, Access = protected)
        function file = fullLnxFile(varargin)
            % Convert paths to Linux convention.
            file = strrep(varargin{1}, '\', '/');
            for i = 2:nargin
                file = [file, '/', varargin{i}]; %#ok<AGROW>
            end
            file = strrep(file, '//', '/');
            file = regexprep(file, '/$', '');  %remove trailing slash
        end
        
        function showImage(imgFile, title)
            if ~isempty(imgFile) && (exist(imgFile, 'file') == 2)
                figure;
                
                % Slightly enlarge the image
                pos = get(gcf, 'Position');
                pos(1:2) = [300 300];
                set(gcf, 'Position', pos .* [1 1 1.50 1.50]);
                
                % Draw the picture
                image(imread(imgFile));
                set(gca, 'LooseInset', get(gca, 'TightInset'));
                set(gcf, 'Name', title, 'NumberTitle', 'off');
                axis('off');
                axis('equal');
            end
        end
    end %methods (Static, Access = protected)
    
    methods (Static, Hidden)
        function obj = loadobj(saveInfo)
            try
                obj = raspberrypi(saveInfo.DeviceAddress);
            catch EX
                warning(EX.identifier, '%s', EX.message);
                obj = codertarget.raspberrypi.empty();
            end
        end
    end %methods (Static, Hidden)
end %classdef

%% Internal functions
function exe = i_getExe(exeFullPath)
[~,name,ext] = fileparts(exeFullPath);
exe = [name,ext];
end

function [ret, pid] = i_isExecutableRunning(hw,exe)
try
    pid = str2num(system(hw,['pgrep -f ' exe])); %#ok<ST2NM>
    ret = true;
catch
    ret = false;
    pid = [];
end
end

