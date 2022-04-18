classdef TargetApplicationFramework < rtw.pil.RtIOStreamApplicationFramework
    %TARGETAPPLICATIONFRAMEWORK creates application framework
    %
    %   The TARGETAPPLICATIONFRAMEWORK allows you to specify additional files needed
    %   to build an application for the target environment. These files may include
    %   code for hardware initialization as well as device driver code for a
    %   communications channel.
    %
    %   See also RTW.PIL.RTIOSTREAMAPPLICATIONFRAMEWORK, RTWDEMO_CUSTOM_PIL
    
    %   Copyright 2016 The MathWorks, Inc.
    
    methods
        % constructor
        function this = TargetApplicationFramework(componentArgs)
            narginchk(1, 1);
            % call super class constructor
            this@rtw.pil.RtIOStreamApplicationFramework(componentArgs);
            % To build the PIL application you must specify a main.c file.
            % The following PIL main.c files are provided and can be
            % added to the application framework via the "addPILMain"
            % method:
            %
            % 1) A main.c adapted for on-target PIL and suitable
            %    for most PIL implementations. Select by specifying
            %    'target' argument to "addPILMain" method.
            %
            % 2) A main.c adapted for host-based PIL such as the
            %    "mypil" host example. Select by specifying 'host'
            %    argument to "addPILMain" method.
            buildInfo = this.getBuildInfo;
            this.addPILMain('target'); % main.c file type (target)
            % rtiostream_src_path =  fullfile(matlabroot, 'rtw', 'c', 'src', 'rtiostream', 'rtiostreamtcpip');
            rtiostream_src_path = fullfile(codertarget.raspi.internal.getSpPkgRootDir,'src');
            buildInfo.addSourcePaths(rtiostream_src_path);
            buildInfo.addSourceFiles('rtiostream_raspi_tcpip.c',rtiostream_src_path);
                        
            hCS = this.getComponentArgs.getConfigInterface.getConfig;
            tgtAttributes = codertarget.attributes.getTargetHardwareAttributes(hCS);
            linkObjs = tgtAttributes.getLinkObjects();
            for i=1:length(linkObjs)
                name = codertarget.utils.replaceTokens(hCS, linkObjs{i}.Name, tgtAttributes.Tokens);
                path = codertarget.utils.replaceTokens(hCS, linkObjs{i}.Path, tgtAttributes.Tokens);
                buildInfo.addLinkObjects(name, path, 1000, true, true);
            end
        end
    end
end

% LocalWords:  RTIOSTREAMAPPLICATIONFRAMEWORK mypil rtiostream rtiostreamtcpip
