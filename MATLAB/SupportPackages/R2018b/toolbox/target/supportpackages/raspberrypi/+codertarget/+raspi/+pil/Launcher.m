classdef Launcher < rtw.connectivity.Launcher
    %LAUNCHER class for  PIL application
    %
    %   LAUNCHER(COMPONENTARGS,BUILDER) instantiates a LAUNCHER object that you can
    %   use to control starting and stopping of an application on the target
    %   processor. In this case the Debug Server Scripting (dss) utility which
    %   ships with EmbeddedCoder is used to download and
    %   run the executable.
    %
    %   See also RTW.CONNECTIVITY.LAUNCHER, RTWDEMO_CUSTOM_PIL
    
    %   Copyright 2016 The MathWorks, Inc.
    
    %% Class properties
    properties
        Exe
        Hw
    end
    
    %% Class methods
    methods
        function this = Launcher(componentArgs, builder)
            narginchk(2, 2);
            % call super class constructor
            this@rtw.connectivity.Launcher(componentArgs, builder);
            this.Hw = raspberrypi;
        end
        
        function delete(this)  %#ok<INUSD>
            % This method is called when an instance of this class is cleared from memory,
            % e.g. when the associated Simulink model is closed. You can use
            % this destructor method to close down any processes, e.g. an IDE or
            % debugger that was originally started by this class. If the
            % stopApplication method already performs this housekeeping at the
            % end of each on-target simulation run then it is not necessary to
            % insert any code in this destructor method. However, if the IDE or
            % debugger may be left open between successive on-target simulation
            % runs then it is recommended to insert code here to terminate that
            % application.
            % Kill the process that launched the embedded application
        end
        
        function startApplication(this)
            % get name of the executable file to download
            exeFullPath = this.getBuilder.getApplicationExecutable;
            [~,name,ext] = fileparts(exeFullPath);
            this.Exe = [name,ext];
            disp(DAStudio.message('raspberrypi:utils:LaunchPILAppMessage', this.Exe));
            
            % Load and run the executable
            try
                % Note only the 'sudo fuser ..' command can fail here. If
                % it fails, this means there is no process grabbing port
                % 17725
                output = system(this.Hw,...
                    ['killall -q ' this.Exe ';rm -f ' this.Exe '*; sudo fuser 17725/tcp']); 
            catch
                output = '';
            end
            if ~isempty(output)
                pid = regexp(regexprep(output,'^17725/tcp:\s*',''),...
                    '(\s*[\s\d]+)+','tokens','once');
                if ~isempty(pid)
                    pid = strtrim(pid{1});
                    error(message('raspberrypi:utils:TcpPortInUse',pid,pid,pid));
                end
            end
            putFile(this.Hw,exeFullPath); 
            cmd = ['chmod u+x ', this.Exe ';`./' this.Exe ' &> ' this.Exe '.log&` ; '];
            cmd = [cmd ' n=0; while [ ! `pidof ' this.Exe '` ] && [ $n -lt 10 ]; do n=$((n+1)); sleep 1; done; echo $n'];
            n = str2double(system(this.Hw,cmd));
            if ~isnan(n) && n == 10
                disp(DAStudio.message('raspberrypi:utils:DiagnosticInformation'));
                cmd = ['ls -al ', this.Exe];
                disp(cmd);
                system(this.Hw,cmd)
                cmd = ['cat ' this.Exe '.log'];
                disp(cmd);
                system(this.Hw,cmd)
                error(message('raspberrypi:utils:PILApplicationDidNotStart'));
            end
        end
        
        function stopApplication(this)
            % Kill the process running 
            system(this.Hw,['killall ' this.Exe ';rm -f ' this.Exe '* &']);
        end
    end
end
