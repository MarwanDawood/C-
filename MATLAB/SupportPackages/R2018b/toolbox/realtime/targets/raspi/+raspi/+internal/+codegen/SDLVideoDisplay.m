classdef SDLVideoDisplay < matlab.System & coder.ExternalDependency
    % SDLVideoDisplay Display images on the hardware board desktop using
    % Simple Direct Media (SDL) library.
    %
    % d = matlab.raspi.SDLVideoDisplay returns a System object, d, to
    % display images.
    %
    % d = matlab.raspi.SDLVideoDisplay('PropertyName', PropertyValue, ...)
    % returns a video display System object, d, with each specified
    % property set to the specified value.
    %
    % Syntax:
    %
    % d = matlab.raspi.SDLVideoDisplay;
    % displayImage(d,img)
    %
    % The displayImage method of the System object, d, takes an NxM or
    % NxMx3 array of 'uint8' values representing an image and displays it
    % on the hardware board's desktop. When the images is a 2-D matrix
    % (NxM) the image is displayed as grayscale.
    
    % Copyright 2017-2019 The MathWorks, Inc.
    %#codegen
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
    
    properties
        windowTitle
    end
    
    methods
        % Constructor
        function obj = SDLVideoDisplay(obj,varargin) %#ok<INUSL>
            % Support name-value pair arguments when constructing object
            setProperties(obj,nargin,varargin{:});
        end
        
        function displayImage(obj,img)
            if size(img,3) == 1
                step(obj,img',img',img');
            else
                step(obj,img(:,:,1)',img(:,:,2)',img(:,:,3)');
            end
            
        end
        
        function set.windowTitle(obj,val) %#ok<INUSL>
            validateattributes(val,{'char','string'},...
                {'row','nonempty'},'','Title');            
           obj.setWindowTitle(val);
        end
        
        function setWindowTitle(obj,val) %#ok<INUSL>
              coder.ceval( 'SDL_WM_SetCaption',[val char(0)],char(0));
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
                coder.cinclude('MW_video_display.h');
                coder.ceval('MW_SDL_videoDisplayInit',...
                    obj.PixelFormatEnum,int32(1),int32(1),size(pln1,1),size(pln1,2));
            end
        end
        
        function stepImpl(~,pln1,pln2,pln3)
            if ~isempty(coder.target)
%                 coder.ceval( 'SDL_WM_SetCaption',[windowTitle '\0'],'\0');
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
                rootDir = raspi.internal.getRaspiRoot;
                serverDir = fullfile(rootDir,'server');
                
                addIncludePaths(buildInfo,serverDir);
                addIncludeFiles(buildInfo,'MW_video_display.h',serverDir);
                addSourceFiles(buildInfo,'MW_video_display.c',serverDir);
                addLinkFlags(buildInfo,{'-lSDL'},'SkipForSil');
            end
        end
    end
end

% LocalWords:  SDL raspi Nx grayscale YCb pln nrows ncols Sil
