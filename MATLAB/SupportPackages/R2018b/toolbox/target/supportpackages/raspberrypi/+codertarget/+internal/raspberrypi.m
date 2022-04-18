classdef raspberrypi
    %RASPBERRYPI
    %   Helper class for docroot
    
    %   Copyright 2015 The MathWorks, Inc.
 
    properties
    end
 
    methods(Static)
        function docRoot = getDocRoot()
            % sppkgNameTag = hwconnectinstaller.SupportPackage.getPkgTag(<Name field from support_package_registry.xml>)
            % e.g. sppkgNameTag = 'xilinxzynq7000ec'
            sppkgNameTag = 'raspberrypi';
            myLocation = mfilename('fullpath');
            docRoot = matlabshared.supportpkg.internal.getSppkgDocRoot(myLocation, sppkgNameTag);
            if isempty(docRoot)
                error(message('raspberrypi:utils:HelpMissing'));
            end
        end
        
        function docRoot = getioDocRoot()
            % sppkgNameTag = hwconnectinstaller.SupportPackage.getPkgTag(<Name field from support_package_registry.xml>)
            % e.g. sppkgNameTag = 'xilinxzynq7000ec'
            sppkgNameTag = 'raspberrypiio';
            myLocation = mfilename('fullpath');
            docRoot = matlabshared.supportpkg.internal.getSppkgDocRoot(myLocation, sppkgNameTag);
            if isempty(docRoot)
                error(message('raspberrypi:utils:HelpMissing'));
            end
        end
    end
end