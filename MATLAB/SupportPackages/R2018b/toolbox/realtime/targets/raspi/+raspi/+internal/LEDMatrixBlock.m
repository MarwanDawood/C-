classdef LEDMatrixBlock < matlab.System & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties(Nontunable)
        %Mode
        Mode_ = 'Write Pixel';
        %Orientation Source
        OrientationSource_ = 'Block dialog';
    end
    
    properties(Nontunable)
        %Orientation
        LEDOrientation_ = '0';
        %Input Image Source
        ImageSource_ = 'One multidimensional signal';
    end
    
    
    properties(Constant, Hidden)
        Mode_Set = matlab.system.StringSet({'Write Pixel','Display Image'});
        LEDOrientation_Set = matlab.system.StringSet({'0','90','180','270'});
        OrientationSource_Set = matlab.system.StringSet({'Block dialog', 'Input port'});
        ImageSource_Set = matlab.system.StringSet({'One multidimensional signal','Separate color signals'});
    end
    
    properties(Hidden, Access=private)
        fd
        pxlLoc
        pxlVal
    end
    
    methods
        % Constructor
        function obj = LEDMatrixBlock(varargin)
            %This would allow the code generation to proceed with the
            %p-files in the installed location of the support package.
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
        
        function writePixel(obj,pixelLocation,pixelvalue)
            if coder.target('Rtw')
                obj.pxlLoc = 2*((8 * (pixelLocation(1) - 1)) + (pixelLocation(2) - 1));
                pxlvalue = uint16(pixelvalue);
                r5 = bitshift(bitshift(pxlvalue(1),-3),11);
                g6 = bitshift(bitshift(pxlvalue(2),-2),5);
                b5 = bitshift(pxlvalue(3),-3);
                obj.pxlVal = r5 + g6 + b5;
                coder.ceval('FRAMEBUFFER_WRITEPIXEL',obj.fd,uint16(obj.pxlLoc),uint16(obj.pxlVal));
            end
        end
        
        
    end
    
    
    %% Output properties
    methods (Access=protected)
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            if coder.target('Rtw')
                coder.cinclude('MW_fbBlock.h');
                obj.fd = uint8(0);
                obj.fd = coder.ceval('FRAMEBUFFER_INIT');
            end
        end
        
        
        
        function stepImpl(obj,varargin)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            
            if coder.target('Rtw')
                switch(obj.Mode_)
                    case 'Write Pixel'
                        numPxl = size(varargin{1});
                        if (numPxl(1)==1)||(numPxl(2)==1)
                            obj.writePixel(varargin{1},varargin{2});
                        else
                            for i=1: numPxl(1)
                                if (numel(varargin{2})==3)
                                    obj.writePixel(varargin{1}(i,:),varargin{2});
                                else
                                    obj.writePixel(varargin{1}(i,:),varargin{2}(i,:));
                                end
                            end
                            
                        end
                    case 'Display Image'
                        %Prepare the image according to the LEDOrientation_
                        img = uint16(zeros(8,8,3));
                        switch(obj.ImageSource_)
                            case 'One multidimensional signal'
                                img = uint16(varargin{1});
                            otherwise
                                img(:,:,1) = uint16(varargin{1});
                                img(:,:,2) = uint16(varargin{2});
                                img(:,:,3) = uint16(varargin{3});
                        end
                        switch (obj.OrientationSource_)
                            case 'Block dialog'
                                orient =str2double(obj.LEDOrientation_);
                            case 'Input port'
                                if isequal(obj.ImageSource_,'One multidimensional signal')
                                    orient = varargin{2};
                                else
                                    orient = varargin{4};
                                end
                        end
                        
                        if orient ~= 0
                            switch(orient)
                                case 90
                                    img = rot90(img,3);
                                case 180
                                    img = rot90(img,2);
                                case 270
                                    img = rot90(img,1);
                            end
                        end
                        %Convert the image into RGB565 [1 64] array
                        r5 = bitshift(bitshift(img(:,:,1),-3),11);
                        g6 = bitshift(bitshift(img(:,:,2),-2),5);
                        b5 = bitshift(img(:,:,3),-3);
                        rgb565 = reshape(r5 + g6 + b5, [1,64]);
                        coder.ceval('FRAMEBUFFER_DISPLAYIMAGE',obj.fd,uint8(1),rgb565);
                end
            end
        end
        
        
        function releaseImpl(obj)
            % Release resources, such as file handles
            if coder.target('Rtw')
                rgb565 = uint16(zeros(1,64));
                coder.ceval('FRAMEBUFFER_DISPLAYIMAGE',obj.fd,uint8(1),rgb565);
                coder.ceval('FRAMEBUFFER_TERMINATE',obj.fd);
            end
        end
        
        function validateInputsImpl(obj,varargin)
            % Validate inputs to the step method at initialization
            switch(obj.Mode_)
                case 'Write Pixel'
                    if numel(varargin{1}) ~=2
                        validateattributes(varargin{1},{'numeric'},{'integer','ncols',2},'','Pixel Location');
                        if numel(varargin{1}) > 128
                            DAStudio.error('raspberrypi:utils:locationDimension');
                        end
                    end
                    if numel(varargin{2}) ~=3
                        validateattributes(varargin{2},{'numeric'},{'integer','ncols',3},'','Pixel Value');
                    end
                    numLoc = size(varargin{1});
                    numVal = size(varargin{2});
                    if numel(varargin{2}) ~=3
                        if numLoc(1) ~= numVal(1)
                            DAStudio.error('raspberrypi:utils:InavlidPXLColor');
                        end
                    end
                    
                case 'Display Image'
                    switch(obj.ImageSource_)
                        case 'One multidimensional signal'
                            validateattributes(varargin{1},{'numeric'},{'integer','size',[8 8 3]},'','image');
                            if strcmp(obj.OrientationSource_,'Input port')
                                validateattributes(varargin{2},{'numeric'},{'scalar'},'','Orientation');
                            end
                        case 'Separate color signals'
                            validateattributes(varargin{1},{'numeric'},{'integer','size',[8 8]},'','R');
                            validateattributes(varargin{2},{'numeric'},{'integer','size',[8 8]},'','G');
                            validateattributes(varargin{3},{'numeric'},{'integer','size',[8 8]},'','B');
                            if strcmp(obj.OrientationSource_,'Input port')
                                validateattributes(varargin{4},{'numeric'},{'scalar'},'','Orientation');
                            end
                    end
            end
        end
        
        
        function num = getNumInputsImpl(obj)
            % Define total number of inputs for system with optional inputs
            switch(obj.Mode_)
                case 'Write Pixel'
                    num = 2;
                case 'Display Image'
                    if isequal(obj.ImageSource_,'One multidimensional signal')
                        num = 1;
                    else
                        num =3;
                    end
                    if strcmp(obj.OrientationSource_,'Input port')
                        num = num+1;
                    end
            end
        end
        
        
        
        function num = getNumOutputsImpl(~)
            % Define total number of outputs for system with optional
            % outputs
            num = 0;
        end
        
        function varargout = getInputNamesImpl(obj)
            switch(obj.Mode_)
                case 'Write Pixel'
                    varargout{1} = 'Loc';
                    varargout{2} = 'Val';
                case 'Display Image'
                    if isequal(obj.ImageSource_,'One multidimensional signal')
                        varargout{1} = 'Image';
                        if strcmp(obj.OrientationSource_,'Input port')
                            varargout{2} = 'Orientation';
                        end
                    else
                        varargout{1} = 'R';
                        varargout{2} = 'G';
                        varargout{3} = 'B';
                        if strcmp(obj.OrientationSource_,'Input port')
                            varargout{4} = 'Orientation';
                        end
                    end
            end
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputFixedSizeImpl(~,~)
            varargout{1} = true;
        end
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isInputComplexImpl(~)
            varargout{1} = false;
        end
        
        
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    
    methods(Static, Access = protected)
        % Note that this is ignored for the mask-on-mask
        function header = getHeaderImpl
            %getHeaderImpl Create mask header
            %   This only has an effect on the base mask.
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', 'LED Matrix', ...
                'Text', 'Display on the LED Matrix', ...
                'ShowSourceLink', false);
        end
    end
    
    %% Each class should be able to add to buildInfo
    methods (Static)
        function name = getDescriptiveName()
            name = 'LED Matrix';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Digital I/O interface
                rootDir = fullfile(raspi.internal.getRaspiRoot,'server');
                addIncludePaths(buildInfo,rootDir);
                addIncludeFiles(buildInfo,'common.h');
                addIncludeFiles(buildInfo,'devices.h');
                addIncludeFiles(buildInfo,'MW_fbBlock.h');
                addSourceFiles(buildInfo,'devices.c',rootDir);
                addSourceFiles(buildInfo,'MW_fbBlock.c',rootDir);
            end
        end
    end
end

