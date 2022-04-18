classdef webcam < matlab.System & coder.ExternalDependency
    % WEBCAM Capture images from a USB webcam attached to hardware board.
    %
    % w = matlab.raspi.webcam returns a System object, w, to capture
    % capture images from a USB camera connected to the hardware board.
    %
    % w = matlab.raspi.webcam(deviceNumber,resolution) returns a webcam
    % System object, w, connected to the camera with specified deviceNumber
    % in /dev/video* file system and with the specified resolution. The
    % deviceNumber defaults to 0, corresponding to the camera represented
    % by the device file /dev/video0. The default value for resolution is
    % [320,240].
    %
    % Syntax:
    %
    % w = matlab.raspi.webcam(0,[320,240]);
    % img = snapshot(w);
    %
    % The returned image, img, is an NxMx3 array of 'uint8' values
    % representing the red, green and blue components of the image capture
    % from the USB webcam.
    
    % Copyright 2017-2019 The MathWorks, Inc.
    %#codegen
    properties (GetAccess = public, SetAccess = private)
        Name = 'Camera'                      % Web camera name
    end
    
    properties (Nontunable, SetAccess = private)
        Resolution = [320,240]
    end
    
    properties (Access = private)
        Initialized = false
        DeviceNumber = uint8(0);
    end
    
    properties(Nontunable)
        ResoultionStr = '320x240'
    end
    
    properties(Hidden)
        searchMode = 0;
        DeviceName = '';
        ResolutionEnum;
    end
    
    properties(Constant, Hidden)
        ResoultionStrSet = matlab.system.StringSet({'160x120','320x240',...
            '640x480','800x600','1024x768','1280x720',...
            '1920x1080'});
    end
    
    
    
    methods
        % Constructor
        function obj = webcam(~,deviceID,resolution)
            % Hardware object check
            if nargin > 1
                if ischar(deviceID) || isstring(deviceID)
                    obj.DeviceName = convertStringsToChars(deviceID);
                    obj.searchMode = 1;
                else
                    obj.DeviceNumber = uint8(deviceID-1);
                    obj.searchMode = 0;
                end
            end
            if nargin > 2
                if ischar(resolution) || isstring(resolution)
                    resolution = convertStringsToChars(resolution);
                    obj.ResoultionStr = resolution;
                    obj.Resolution = obj.ResolutionEnum;
                else
                    obj.Resolution = resolution;
                end
            else
                obj.Resolution = [320, 240];
            end
        end
        
        % Take a snapshot
        function image = snapshot(obj)
            image = step(obj);
        end
        
        function set.DeviceNumber(obj,value)
            validateattributes(value,{'numeric'},...
                {'scalar','nonnegative','integer','<',256},'','DeviceNumber');
            obj.DeviceNumber = value;
        end
        
        function set.Resolution(obj,value)
            validateattributes(value,{'numeric'},...
                {'size',[1,2],'nonnegative','integer'},'','Resolution');
            obj.Resolution = value;
        end
        
        function resEnum = get.ResolutionEnum(obj)
            switch(obj.ResoultionStr)
                case '160x120'
                    resEnum = [160, 120];
                case '320x240'
                    resEnum = [320, 240];
                case '640x480'
                    resEnum = [640, 480];
                case '800x600'
                    resEnum = [800, 600];
                case '1024x768'
                    resEnum = [1024, 768];
                case '1280x720'
                    resEnum = [1280, 720];
                case '1920x1080'
                    resEnum = [1920, 1080];
                otherwise
                    resEnum = [320, 240];
            end
        end
    end
    methods(Access = protected)
        function setupImpl(obj)
            if isempty(coder.target)
            else
                coder.cinclude('stdio.h');
                coder.cinclude('v4l2_cam.h');
                coder.updateBuildInfo('addDefines','_MW_MATLABTGT_');
                status = int32(0);
                devNum = uint8(0);
                %Populate the list of cameras
                coder.ceval('getCameraList');
                %If the deviceID is device name, get the index
                if (obj.searchMode ~= 0)
                    devNum = coder.ceval('getCameraAddrIndex', coder.ref(obj.DeviceName));
                    obj.DeviceNumber = devNum;
                end
                resolutionStatus = uint8(0);
                resolutionStatus = coder.ceval('validateResolution',uint8(obj.DeviceNumber),uint16(obj.Resolution(1)),uint16(obj.Resolution(2)));
                if (uint8(resolutionStatus)~=0)
                    status = coder.ceval('EXT_webcamInit',...
                        uint8(1), ... %MATLAB Targeting flag
                        uint8(obj.DeviceNumber),... %Device ID
                        int32(0),... %roiTop
                        int32(0),... %roiLeft
                        int32(0),... %roiWidth
                        int32(0),... %roiHeight
                        uint32(obj.Resolution(1)),...
                        uint32(obj.Resolution(2)),...
                        uint32(2),... %pixelFormat
                        uint32(2),... %pixelOrder
                        uint32(1),...
                        1/30);        % Frame rate
                    %obj.PinNumber = i_str2int(obj.Pin);
                    if status == 0
                        obj.Initialized = true;
                    else
                        coder.ceval('printf',['Error opening camera.' char(0)]);
                    end
                end
            end
        end
        
        function image = stepImpl(obj)
            if isempty(coder.target)
                w = obj.Resolution(1);
                h = obj.Resolution(2);
                image = zeros(w,h,3);
            else
                h = obj.Resolution(1);
                w = obj.Resolution(2);
                image = coder.nullcopy(zeros(w,h,3,'uint8'));%[240 320]
                ts = uint64(0);
                if obj.Initialized
                    pln0 = coder.nullcopy(zeros(h,w,'uint8'));
                    pln1 = coder.nullcopy(zeros(h,w,'uint8'));
                    pln2 = coder.nullcopy(zeros(h,w,'uint8'));                    
                    coder.ceval('EXT_webcamCapture',uint8(1),uint8(obj.DeviceNumber),...
                        coder.wref(pln0),...
                        coder.wref(pln1),...
                        coder.wref(pln2));
                    image(:,:,1) = pln0';%[240 320]
                    image(:,:,2) = pln1';%[240 320]
                    image(:,:,3) = pln2';%[240 320]
                end
            end
        end
        
        function releaseImpl(obj)
            % Release camera
            if isempty(coder.target)
            else
                if obj.Initialized
                    coder.ceval('EXT_webcamTerminate',uint8(1),uint8(obj.DeviceNumber));
                end
            end
        end
        
        function N = getNumInputsImpl(~)
            % Specify number of System inputs
            N = 0;
        end
        
        function N = getNumOutputsImpl(~)
            % Specify number of System outputs
            N = 1;
        end
    end
    
    %% Output properties
    methods (Access = protected)
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(~,~)
            varargout{1} = true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout{1} = false;
        end
        
        function varargout = getOutputSizeImpl(obj)
            varargout{1} = [obj.Resolution(1),obj.Resolution(2),3];
        end
        
        function varargout = getOutputDataTypeImpl(~)
            varargout{1} = 'uint8';
        end
    end
    
    %% Build artifacts
    methods (Hidden, Static)
        function name = getDescriptiveName()
            name = 'Raspberry Pi Webcam';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Digital I/O interface
                serverDir = fullfile(raspi.internal.getRaspiRoot,'server');
                addIncludeFiles(buildInfo,'v4l2_cam.h',serverDir);
                addIncludeFiles(buildInfo,'common.h',serverDir);
                addSourceFiles(buildInfo,'v4l2_cam.c',serverDir);
                addIncludeFiles(buildInfo,'availableWebcam.h',serverDir);
                addSourceFiles(buildInfo,'availableWebcam.c',serverDir);
            end
        end
    end
end



% Put a C termination character '\0' at the end of MATLAB string
function y = cstring(x)
y = [x char(0)];
end

% LocalWords:  raspi dev Nx MATLABTGT Addr roi
