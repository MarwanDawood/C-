classdef raspberrypiio
    %RASPBERRYPIIO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function docRoot = getDocRoot()
            sppkgNameTag = 'raspberrypiio';
            myLocation = mfilename('fullpath');
            docRoot = matlabshared.supportpkg.internal.getSppkgDocRoot(myLocation, sppkgNameTag);
            if isempty(docRoot)
                error(message('raspi:setup:HelpMissing'));
            end
        end
    end
    
    
end

