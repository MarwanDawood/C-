classdef ConnectivityConfig < rtw.connectivity.Config
    %CONNECTIVITYCONFIG PIL connectivity configuration class
    %
    %
    %   Copyright 2016 The MathWorks, Inc.
    
    methods
        function this = ConnectivityConfig(args)
            
            appFwk = codertarget.raspi.pil.TargetApplicationFramework(args);
            builder = rtw.connectivity.MakefileBuilder(args,appFwk,'.elf');
            launcher = codertarget.raspi.pil.Launcher(args,builder);
            sharedLibExt = system_dependent('GetSharedLibExt');
            lib = ['libmwrtiostreamtcpip' sharedLibExt];
            communicator = rtw.connectivity.RtIOStreamHostCommunicator(...
                args, ...
                launcher, ...
                lib);
            communicator.setInitCommsTimeout(30);
            communicator.setTimeoutRecvSecs(30);
            
            % Set connection parameters
            cfg = args.getConfigInterface.getConfig;
            try 
                port = cfg.Hardware.IOInterface.Port;
            catch
                port = 17725;
            end
            hostname = codertarget.raspi.getDeviceAddress;
            argList = {...
                '-hostname', hostname, ...
                '-client', '1', ...
                '-blocking', '1', ...
                '-port', num2str(port),...
                };
            communicator.setOpenRtIOStreamArgList(argList);
            this@rtw.connectivity.Config(args,builder,launcher,communicator);
            
            % Register timer functions
            timer = codertarget.raspi.pil.profilingTimer(cfg);
            this.setTimer(timer);        
        end
    end
end
