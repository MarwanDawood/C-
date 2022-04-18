classdef (StrictDefaults)SDLVideoDisplay < matlab.System & coder.ExternalDependency
    % SDLVideoDisplay System object for video display.
    %
    % SDLVideoDisplay is a system object that displays images and video on
    % hardware running a Linux OS through Simple Direct Media (SDL) API's.
    
    %#codegen
    % Copyright 2015 The MathWorks, Inc.
    properties (Nontunable)
        PixelFormat = 'RGB';
    end
    
    properties (Constant,Hidden)
        PixelFormatSet =  matlab.system.StringSet({'RGB','YCbCr 4:2:2'});
    end
    
    % Pre-computed constants
    properties(Access = private)
        PixelFormatEnum = int32(1)
    end
    
    methods
        % Constructor
        function obj = SDLVideoDisplay(varargin)
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods(Access = protected)
        %% Common functions
        function setupImpl(obj,pln1,~,~)
            % Perform one-time calculations, such as computing constants
            if ~isempty(coder.target)
                if isequal(obj.PixelFormat,'RGB')
                    obj.PixelFormatEnum = int32(1);
                else
                    obj.PixelFormatEnum = int32(2);
                end
                % MW_SDL_videoDisplayInit(pixelFormat,pixelOrder,rowMajor,width,height)
                coder.cinclude('MW_SDL_video_display.h');
                coder.ceval('MW_SDL_videoDisplayInit',...
                    obj.PixelFormatEnum,int32(1),int32(1),size(pln1,1),size(pln1,2));
            end
        end
        
        function stepImpl(~,pln1,pln2,pln3)
            if ~isempty(coder.target)
                % void MW_SDL_videoDisplayOutput(const uint8_T *pln0,
                %     const uint8_T *pln1, const uint8_T *pln2);
                coder.ceval('MW_SDL_videoDisplayOutput',...
                    coder.ref(pln1),coder.ref(pln2),coder.ref(pln3));
            end
        end
        
        
        function releaseImpl(~)
            if ~isempty(coder.target)
                %void MW_SDL_videoDisplayTerminate(int width, int height);
                coder.ceval('MW_SDL_videoDisplayTerminate',int32(0),int32(0));
            end
        end
        
        function validateColorPlanes(obj,pln1,pln2,pln3)
            if obj.PixelFormatEnum == 1
                validateattributes(pln1,{'uint8'},{'2d'},'','R');
                validateattributes(pln2,{'uint8'},{'2d','nrows',size(pln1,1),'ncols',size(pln1,2)},'','G');
                validateattributes(pln3,{'uint8'},{'2d','nrows',size(pln1,1),'ncols',size(pln1,2)},'','B');
            else
                validateattributes(pln1,{'uint8'},{'2d'},'','Y');
                validateattributes(pln2,{'uint8'},{'2d','nrows',size(pln1,1)/2,'ncols',size(pln1,2)},'','Cb');
                validateattributes(pln3,{'uint8'},{'2d','nrows',size(pln1,1)/2,'ncols',size(pln1,2)},'','Cr');
            end
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            % Return true if input size is not allowed to change while
            % system is running
            flag = true;
        end
        
        function N = getNumInputsImpl(~)
            N = 3;
        end
        
        function N = getNumOutputsImpl(~)
            N = 0;
        end
    end
    
    methods(Static, Access = protected)
        %% Simulink customization functions
        function header = getHeaderImpl
            % Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename('class'));
        end
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods (Hidden, Static)
        function name = getDescriptiveName()
            name = 'SDL Video Display';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo,context)
            if context.isCodeGenTarget('rtw')
                % Build artifacts
                rootDir = realtime.internal.getLinuxRoot;
                addIncludePaths(buildInfo,fullfile(rootDir,'include'));
                addIncludeFiles(buildInfo,'MW_SDL_video_display.h',fullfile(rootDir,'include'));
                systemTargetFile = get_param(buildInfo.ModelName,'SystemTargetFile');
                if isequal(systemTargetFile,'ert.tlc')
                    % Add the following when not in rapid-accel simulation
                    addSourceFiles(buildInfo,'MW_SDL_video_display.c',fullfile(rootDir,'src'));
                    addLinkFlags(buildInfo,{'-lSDL'},'SkipForSil');
                end
            end
        end
    end
end
