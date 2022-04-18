classdef MWRaspbian < handle
    % MWRaspbian - Class that covers information regarding MathWorks
    % Raspbian image.
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    
    properties(Access = protected)
        Raspbian_Name
        Raspbian_zipSize
        Raspbian_ImgName
        Raspbian_Version
        Raspbian_DownloadUrl
        Raspbian_github
        Raspbian_CheckSum
    end
    
    methods
        function obj = MWRaspbian(varargin)
            % Constructor
            obj.Raspbian_Name = 'mathworks_raspbian_R18.2.2.zip';
            obj.Raspbian_zipSize = 1215720623;
            obj.Raspbian_ImgName = 'mathworks_raspbian_R18.2.2.img';
            obj.Raspbian_Version = '18.2.2';
            obj.Raspbian_DownloadUrl = 'https://github.com/mathworks/Raspbian_OS_Setup/releases/download/R18.2.2_GR/mathworks_raspbian_R18.2.2.zip';
            obj.Raspbian_github = '<a href="https://github.com/mathworks/Raspbian_OS_Setup/releases/tag/R18.2.2_GR"> page</a>.';
            obj.Raspbian_CheckSum = '5e4e73f7f532a5103506deef208e7ede';
        end
        
        function name = getRaspbianName(obj,varargin)
            name = obj.Raspbian_Name;
        end
        
        function name = getRaspbianImgName(obj,varargin)
            name = obj.Raspbian_ImgName;
        end
        
        function name = getRaspbianVersion(obj,varargin)
            name = obj.Raspbian_Version;
        end
        
        function name = getRaspbianDownloadUrl(obj,varargin)
            name = obj.Raspbian_DownloadUrl;
        end
        
        function name = getRaspbianChecksum(obj,varargin)
            name = obj.Raspbian_CheckSum;
        end
        
        function fileSize = getRaspbianZipSize(obj,varargin)
            fileSize = obj.Raspbian_zipSize;
        end
        
        function out = getRaspbianGithub(obj, varargin)
            out = obj.Raspbian_github;
        end
    end
end

% LocalWords:  Raspbian raspbian github deef ede
