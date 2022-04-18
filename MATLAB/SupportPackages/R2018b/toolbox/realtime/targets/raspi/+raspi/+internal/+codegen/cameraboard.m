classdef cameraboard < matlab.System ...
        & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency
    %cameraboard System object to capture image/video from Raspberry Pi
    %camera
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %#codegen
    properties (Dependent)
        Resolution = '320x240';
    end
    
    properties
        FrameRate = 30;
        Quality = 10;
        Rotation = 0;
        HorizontalFlip = false;
        VerticalFlip = false;
        Brightness = 50;
        Contrast = 0;
        Saturation = 0;
        Sharpness = 0;
        VideoStabilization = 'off';
        ExposureMode = 'auto        ';
        ExposureCompensation = 0;
        AWBMode = 'auto        ';
        MeteringMode = 'average';
        ImageEffect = 'none         ';
        ROI = [0.0 0.0 1.0 1.0];
    end
    
    properties (GetAccess = public, SetAccess = private)
        Recording = false;
    end
    
    properties (Dependent, Access = private)
        CameraArgs
        CameraAvailable
    end
    
    properties (Hidden,Nontunable)
        WidthHeight = [320,240];
    end
    
    
    properties (Hidden, Constant)
        AvailableVideoStabilizations = {'off', 'on'};
        AvailableResolutions = {...
            '160x120', '320x240', ...
            '640x480', '800x600', '1024x768', ...
            '1280x720', '1920x1080'};
        AvailableFrameRates = 2:1:90;
        AvailableRotations = [0, 90, 180, 270];
        ArgDelimiter = ' ';
        CameraOptions = struct(...
            'Sharpness', '-sh', ...       % Set image sharpness (-100 to 100)
            'Contrast', '-co', ...        % Set image contrast (-100 to 100)
            'Brightness', '-br', ...      % Set image brightness (0 to 100)
            'Saturation', '-sa', ...      % Set image saturation (-100 to 100)
            'ISO', '-ISO', ...            % Set capture ISO
            'StabilizationOn', '-vs', ... % Turn on video stabilization
            'ExposureCompensation', '-ev', ...  % Set EV compensation
            'ExposureMode', '-ex', ...    % Set exposure mode (see Notes)
            'AWBMode', '-awb', ...        % Set AWB mode (see Notes)
            'ImageEffect', '-ifx', ...    % Set image effect (see Notes)
            'ColorEffect', '-cfx', ...    % Set color effect (U:V)
            'MeteringMode', '-mm', ...    % Set metering mode (see Notes)
            'Rotation', '-rot', ...       % Set image rotation (0-359)
            'HorizontalFlip', '-hf', ...  % Set horizontal flip
            'VerticalFlip', '-vf', ...    % Set vertical flip
            'ROI', '-roi', ...            % Set region of interest (x,y,w,d as normalized coordinates [0.0-1.0])
            'ShutterSpeed', '-ss');       % Set shutter speed in microseconds
        AvailableQuality    = 1:1:100;
        AvailableSharpness  = -100:1:100;
        AvailableBrightness = 0:1:100;
        AvailableContrast   = -100:1:100;
        AvailableSaturation = -100:1:100;
        AvailableExposureCompensations = -10:1:10;
        AvailableExposureModes = {'auto', 'night', 'nightpreview', ...
            'backlight', 'spotlight', 'sports', 'snow', 'beach', ...
            'verylong', 'fixedfps', 'antishake', 'fireworks'};
        AvailableAWBModes = {'off', 'auto', 'sun', 'cloud', 'shade', ...
            'tungsten', 'fluorescent', 'incandescent', 'flash', 'horizon'};
        AvailableImageEffects = {'none', 'negative', 'solarise', 'sketch', ...
            'denoise', 'emboss', 'oilpaint', 'hatch', 'gpen', 'pastel', ...
            'watercolour', 'film', 'blur', 'saturation', 'colourswap', ...
            'washedout', 'posterise', 'colourpoint', 'colourbalance', ...
            'cartoon'};
        AvailableMeteringModes = {'average', 'spot', 'backlit', 'matrix'};
    end
    
    properties (Hidden, Access = private)
        Initialized = false;
        Opened = false;
    end
    
    methods(Access = protected)
        function img = setupImpl(obj)
            img = obj.snapshot();
        end
    end
    
    methods
        function obj = cameraboard(varargin)
            coder.allowpcode('plain');
            
            setProperties(obj,nargin,varargin{:});
            obj.Initialized = true;            
        end

        function ret = get.Recording(~)
            if isempty(coder.target)
                % return false
                ret = false;
            else
                check = int8(0);
                coder.cinclude('picam.h');
                check = coder.ceval('isRaspividRunning');
                if check == 1
                    % raspivid is running in background
                    ret = true;
                else
                    ret = false;
                end
            end
        end
        
        function args = get.CameraArgs(obj)
            args = '';
            % Validation check for Rotation value
            if ~ismember(obj.Rotation,obj.AvailableRotations)
                fprintf('Rotation must be one of the following values: 0, 90, 180 or 270.\n');
                coder.ceval('exit',0);
            end
            args = addOption(obj,args,obj.CameraOptions.Rotation, obj.Rotation);
            if obj.HorizontalFlip
                args = addOption(obj, args, obj.CameraOptions.HorizontalFlip);
            end
            if obj.VerticalFlip
                args = addOption(obj, args, obj.CameraOptions.VerticalFlip);
            end
            args = addOption(obj, args, obj.CameraOptions.Brightness, obj.Brightness);
            args = addOption(obj, args, obj.CameraOptions.Contrast, obj.Contrast);
            args = addOption(obj, args, obj.CameraOptions.Saturation, obj.Saturation);
            args = addOption(obj, args, obj.CameraOptions.Sharpness, obj.Sharpness);
            if isequal(obj.VideoStabilization, 'on')
                args = addOption(obj, args, obj.CameraOptions.StabilizationOn);
            end
            args = addOption(obj, args, obj.CameraOptions.ExposureMode, obj.ExposureMode);
            args = addOption(obj, args, obj.CameraOptions.ExposureCompensation, obj.ExposureCompensation);
            args = addOption(obj, args, obj.CameraOptions.AWBMode, obj.AWBMode);
            args = addOption(obj, args, obj.CameraOptions.MeteringMode, obj.MeteringMode);
            args = addOption(obj, args, obj.CameraOptions.ImageEffect, obj.ImageEffect);
            args = addROIOption(obj, args, obj.CameraOptions.ROI, obj.ROI);
        end
        
        function set.Resolution(obj,value)
            validateattributes(value,{'char','string'},...
                {'row','nonempty'},'','led');
            value = validatestring(value,obj.AvailableResolutions,'Resolution');
            switch value
                case '160x120'
                    obj.WidthHeight = [160,120];
                case '320x240'
                    obj.WidthHeight = [320,240];
                case '640x480'
                    obj.WidthHeight = [640,480];
                case '800x600'
                    obj.WidthHeight = [800,600];
                case '1024x768'
                    obj.WidthHeight = [1024,768];
                case '1280x720'
                    obj.WidthHeight = [1280,720];
                case '1920x1080'
                    obj.WidthHeight = [1920,1080];
                otherwise
                    obj.WidthHeight = [320,240];
            end
        end
        
        function set.FrameRate(obj,value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan', 'integer' '>=',2,'<=',90 }, '', 'FrameRate');
            obj.FrameRate = value;
        end
        
        function set.Quality(obj,value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan','integer' '>=',1,'<=',100 }, '', 'Quality');
            obj.Quality = value;
            obj.setCameraParams();
        end
        
        function set.Rotation(obj,value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan'}, '', 'Rotation');
            mustBeMember(value,obj.AvailableRotations);
            obj.Rotation = value;
            obj.setCameraParams();
        end
        
        function set.HorizontalFlip(obj, value)
            validateattributes(value, {'numeric', 'logical'}, ...
                {'scalar'}, '', 'HorizontalFlip');
            obj.HorizontalFlip = logical(value);
            obj.setCameraParams();
        end
        
        function set.VerticalFlip(obj, value)
            validateattributes(value, {'numeric', 'logical'}, ...
                {'scalar'}, '', 'VerticalFlip');
            obj.VerticalFlip = logical(value);
            obj.setCameraParams();
        end
        
        function set.Brightness(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan','integer','>=',0,'<=',100}, '', 'Brightness');
            obj.Brightness = value;
            obj.setCameraParams();
        end
        
        function set.Contrast(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan','integer','>=',-100,'<=',100}, '', 'Contrast');
            obj.Contrast = value;
            obj.setCameraParams();
        end
        
        function set.Saturation(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan','integer','>=',-100,'<=',100}, '', 'Saturation');
            obj.Saturation = value;
            obj.setCameraParams();
        end
        
        function set.Sharpness(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan','integer','>=',-100,'<=',100}, '', 'Sharpness');
            obj.Sharpness = value;
            obj.setCameraParams();
        end
        
        function set.VideoStabilization(obj, value)
            value = validatestring(value, obj.AvailableVideoStabilizations,'VideoStabilization');
            switch value
                case 'on'
                    valueStr = 'on ';
                case 'off'
                    valueStr = 'off';
                otherwise
                    valueStr = 'on ';
            end
            obj.VideoStabilization = valueStr;
            obj.setCameraParams();
        end
        
        function set.ExposureMode(obj, value)
            value = validatestring(value, obj.AvailableExposureModes,'ExposureMode');
            switch value
                case 'auto'
                     valueStr = 'auto        ';
                case 'night'
                     valueStr = 'night       ';
                case 'nightpreview'
                     valueStr = 'nightpreview';
                case 'backlight'
                     valueStr = 'backlight   ';
                case 'spotlight'
                     valueStr = 'spotlight   ';
                case 'sports'
                     valueStr = 'sports      ';
                case 'snow'
                     valueStr = 'snow        ';
                case 'beach'
                     valueStr = 'beach       ';
                case 'verylong'
                     valueStr = 'verylong    ';
                case 'fixedfps'
                     valueStr = 'fixedfps    ';
                case 'antishake'
                     valueStr = 'antishake   ';
                case 'fireworks'
                     valueStr = 'fireworks   ';
                otherwise
                     valueStr = 'auto        ';
            end
            obj.ExposureMode = valueStr;
            obj.setCameraParams();
        end
        
        function set.ExposureCompensation(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan','integer','>=',-10,'<=',10}, '', 'ExposureCompensation');
            obj.ExposureCompensation = value;
            obj.setCameraParams();
        end
        
        function set.ROI(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'size', [1, 4], 'nonnan', 'nonnegative','>=',0,'<=',1}, '', 'ROI');
            obj.ROI = value;
            obj.setCameraParams();
        end
        
        function set.AWBMode(obj, value)
            value = validatestring(value, obj.AvailableAWBModes,'AWBMode');
            switch value
                case 'off'
                    valueStr = 'off         ';
                case 'auto'
                    valueStr = 'auto        ';
                case 'sun'
                    valueStr = 'sun         ';
                case 'cloud'
                    valueStr = 'cloud       ';
                case 'shade'
                    valueStr = 'shade       ';
                case 'tungsten'
                    valueStr = 'tungsten    ';
                case 'fluorescent'
                    valueStr = 'fluorescent ';
                case 'incandescent'
                    valueStr = 'incandescent';
                case 'flash'
                    valueStr = 'flash       ';
                case 'horizon'
                    valueStr = 'horizon     ';
                otherwise
                    valueStr = 'off         ';
            end
            obj.AWBMode = valueStr;                                 
            obj.setCameraParams();
        end
        
        function set.MeteringMode(obj, value)
            value = validatestring(value, obj.AvailableMeteringModes,'MeteringMode');
            switch value
                case 'average'
                    valueStr = 'average';
                case 'spot'
                    valueStr = 'spot   ';
                case 'backlit'
                    valueStr = 'backlit';
                case 'matrix'
                    valueStr = 'matrix ';
                otherwise
                    valueStr = 'average';  
            end
            obj.MeteringMode = valueStr;
            obj.setCameraParams();
        end
        
        function set.ImageEffect(obj, value)
            value = validatestring(value, obj.AvailableImageEffects,'ImageEffect');
            switch value
                case 'none'
                    valuseStr = 'none         ';
                case 'negative'
                    valuseStr = 'negative     ';
                case 'solarise'
                    valuseStr = 'solarise     ';
                case 'sketch'
                    valuseStr = 'sketch       ';
                case 'denoise'
                    valuseStr = 'denoise      ';
                case 'emboss'
                    valuseStr = 'emboss       ';
                case 'oilpaint'
                    valuseStr = 'oilpaint     ';
                case 'hatch'
                    valuseStr = 'hatch        ';
                case 'gpen'
                    valuseStr = 'gpen         ';
                case 'pastel'
                    valuseStr = 'pastel       ';
                case 'watercolour'
                    valuseStr = 'watercolour  ';
                case 'film'
                    valuseStr = 'film         ';
                case 'blur'
                    valuseStr = 'blur         ';
                case 'saturation'
                    valuseStr = 'saturation   ';
                case 'colourswap'
                    valuseStr = 'colourswap   ';
                case 'washedout'
                    valuseStr = 'washedout    ';
                case 'posterise'
                    valuseStr = 'posterise    ';
                case 'colourpoint'
                    valuseStr = 'colourpoint  ';
                case 'colourbalance'
                    valuseStr = 'colourbalance';
                case 'cartoon'
                    valuseStr = 'cartoon      ';
                otherwise
                    valuseStr = 'none         ';
            end
            obj.ImageEffect = valuseStr;
            obj.setCameraParams();
        end
        
        function img = snapshot(obj)
            img_init = zeros(obj.WidthHeight(2), obj.WidthHeight(1), 3, 'uint8');
            dataSize = uint32(0);
            ret = int32(0);
            
            if ~obj.Opened
                if obj.Recording
                    fprintf('Camera board is currently recording video. You cannot perform this operation at this time. Either wait until video recording is complete or stop the current recording session using stop method.');
                    coder.ceval('exit',0);
                else
                    obj.open();
                end
            end
            coder.cinclude('picam.h');
            ret = coder.ceval('EXT_CAMERABOARD_snapshot',coder.ref(img_init),coder.wref(dataSize));
            
            Rimg = img_init(1:3:end);
            Gimg = img_init(2:3:end);
            Bimg = img_init(3:3:end);
            
            Rimg2D = reshape(Rimg,obj.WidthHeight(1),obj.WidthHeight(2));
            Gimg2D = reshape(Gimg,obj.WidthHeight(1),obj.WidthHeight(2));
            Bimg2D = reshape(Bimg,obj.WidthHeight(1),obj.WidthHeight(2));
            
            
            img = cat(3,Rimg2D',Gimg2D',Bimg2D');
            if ret < 0
                fprintf('Error in taking snapshot \n');
            end
            
        end
        
        function record(obj, fileName, duration)
            narginchk(3,3);
            validateattributes(fileName, {'char'}, ...
                {'row'}, '', 'fileName');
            validateattributes(duration, {'numeric'}, ...
                {'scalar', 'positive'}, '', 'duration');
            
            if obj.Opened
                obj.close();
            else
                if obj.Recording
                    fprintf('Camera board is currently recording video. You cannot perform this operation at this time. Either wait until video recording is complete or stop the current recording session using stop method. \n');
                    coder.ceval('exit',0);
                end
            end
            
            % Set duration parameter
            if isinf(duration)
                % Setting duration to zero will make raspivid record video
                % indefinitely until a SIGINT is received
                duration = 0;
            end
            
            % Form command line to launch a recording session with raspivid
            cmd = ['raspivid -t ', i_num2str(floor(duration*1000)), ' -o ', fileName];
            cmd = [cmd, ' -w ', i_num2str(obj.WidthHeight(1)), ' -h ', i_num2str(obj.WidthHeight(2))];
            cmd = [cmd, ' -n ', obj.CameraArgs, '&> /dev/null &']; % No preview
            fprintf('Video recording initiated.\n');
            coder.ceval('system',cmd);
        end
        
        function stop(obj)
            if ~isempty(coder.target)
                if obj.Recording
                    % Use killall -9 to ensure all raspivid processes are
                    % killed including the one started by popen in MATLAB
                    % Online case
                    cmd = 'sudo killall -9 raspivid';
                    coder.ceval('system',cmd);
                end
            end
        end
        
        function delete(obj)
            obj.close();
        end
        
    end
    
    methods (Access = private)
        
        function open(obj)
            framerate = int32(obj.FrameRate*2); % Latest firmware is somehow requiring 2x frame rate
            quality = int32(obj.Quality);
            ret = int32(-1);
            
            coder.cinclude('picam.h');
            ret = coder.ceval('EXT_CAMERABOARD_init', obj.WidthHeight(1), obj.WidthHeight(2),...
                framerate, quality, i_cstr(obj.CameraArgs));
            
            if ret == 0
                obj.Opened = true;
            end
        end
        
        function close(~)
            % Close camera board
            if ~isempty(coder.target)
                coder.cinclude('picam.h');
                coder.ceval('EXT_CAMERABOARD_terminate');
            end
        end
        
        function option =  addOption(obj, option, optionStr, optionVal)
            if nargin < 4
                optionVal = '';             
            end
            if isnumeric(optionVal)
                option = [option, obj.ArgDelimiter, optionStr, obj.ArgDelimiter, i_num2str(optionVal)];
            else
                option = [option, obj.ArgDelimiter, optionStr, obj.ArgDelimiter, optionVal];
            end  
        end
        
        function option = addROIOption(obj, option, optionStr, ROI)
            option = addOption(obj, option, optionStr);
            for i = 1:3
                option = [option, i_num2str(ROI(i)), ',']; %#ok<AGROW>
            end
            option = [option, i_num2str(ROI(4)), ' '];
        end
        
        function setCameraParams(obj)
            % We set all camera parameters as a batch at the time of object
            % initialization. Setting individual camera parameters after
            % this point should trigger a CONTROL request
            if obj.Initialized && obj.Opened
                coder.ceval('EXT_CAMERABOARD_control', i_cstr(obj.CameraArgs));
            end
        end
        
    end
    
    
    methods (Hidden, Static)
        function name = getDescriptiveName()
            name = 'cameraboard';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Digital I/O interface
                rootDir = fileparts(strtok(mfilename('fullpath'), '+'));
                srcDir = fullfile(rootDir,'server');
                bcmDir = fullfile('opt','userland','host_applications','linux','libs','bcm_host','include');
                userlandDir = fullfile('opt','userland');
                raspiCamDir = fullfile('opt','userland','host_applications','linux','apps','raspicam');
                vcosDir = fullfile('opt','userland','interface','vcos');
                vcosThreadDir = fullfile('opt','userland','interface','vcos','pthreads');
                vmcsDir = fullfile('opt','userland','interface','vmcs_host','linux');
                addIncludePaths(buildInfo,srcDir);
                addIncludePaths(buildInfo,bcmDir);
                addIncludePaths(buildInfo,userlandDir);
                addIncludePaths(buildInfo,raspiCamDir);
                addIncludePaths(buildInfo,vcosDir);
                addIncludePaths(buildInfo,vcosThreadDir);
                addIncludePaths(buildInfo,vmcsDir);
                addIncludeFiles(buildInfo,'picam.h',srcDir);
                addDefines(buildInfo,'DISABLE_JPEG_ENCODING');
                buildInfo.addMakeVars('LIBMMAL','${shell $gcc ${CFLAGS} -print-file-name=libmmal.so}');
                addLinkObjects(buildInfo,'$(LIBMMAL)','opt/vc/lib',1000,true,true);
                buildInfo.addMakeVars('LIBMMALCORE','${shell $gcc ${CFLAGS} -print-file-name=libmmal_core.so}');
                addLinkObjects(buildInfo,'$(LIBMMALCORE)','opt/vc/lib',1000,true,true);
                buildInfo.addMakeVars('LIBMMALUTIL','${shell $gcc ${CFLAGS} -print-file-name=libmmal_util.so}');
                addLinkObjects(buildInfo,'$(LIBMMALUTIL)','opt/vc/lib',1000,true,true);
                buildInfo.addMakeVars('LIBMMALVC','${shell $gcc ${CFLAGS} -print-file-name=libmmal_vc_client.so}');
                addLinkObjects(buildInfo,'$(LIBMMALVC)','opt/vc/lib',1000,true,true);
                buildInfo.addMakeVars('LIBVCOS','${shell $gcc ${CFLAGS} -print-file-name=libvcos.so}');
                addLinkObjects(buildInfo,'$(LIBVCOS)','opt/vc/lib',1000,true,true);
                buildInfo.addMakeVars('LIBBCMHOST','${shell $gcc ${CFLAGS} -print-file-name=libbcm_host.so}');
                addLinkObjects(buildInfo,'$(LIBBCMHOST)','opt/vc/lib',1000,true,true);
                
                % Add c files available in raspi : /opt/userland/host_applications/linux/apps/raspicam
                addSourceFiles(buildInfo,'RaspiCamControl.c',raspiCamDir);
                addSourceFiles(buildInfo,'RaspiPreview.c',raspiCamDir);
                addSourceFiles(buildInfo,'RaspiCLI.c',raspiCamDir);
                addSourceFiles(buildInfo,'RaspiHelpers.c',raspiCamDir);
                addSourceFiles(buildInfo,'RaspiCommonSettings.c',raspiCamDir);
                
                addIncludeFiles(buildInfo,'common.h',srcDir);
                addSourceFiles(buildInfo,'picam.c',srcDir);
                
            end
        end
    end
end


%% Internal functions
function str = i_cstr(str)
str = [str char(0)];
end

function str = i_num2str(num)
str = '';

if num == 0
    str = '0';
end

while num > 0
   digit = mod(num, 10);
   str = [digit + '0', str]; %digit + '0' convert an integer between 0-9 into the corresponding character
   num = floor(num / 10);
end
end

% LocalWords:  sa ev AWB awb ifx cfx vf roi nightpreview backlight verylong
% LocalWords:  fixedfps antishake solarise denoise oilpaint gpen watercolour
% LocalWords:  colourswap washedout posterise colourpoint colourbalance backlit
% LocalWords:  picam Raspivid raspivid nonnan SIGINT dev killall popen sudo
% LocalWords:  fullpath userland linux bcm raspicam vcos pthreads vmcs LIBMMAL
% LocalWords:  CFLAGS libmmal vc LIBMMALCORE LIBMMALUTIL LIBMMALVC LIBVCOS
% LocalWords:  libvcos LIBBCMHOST libbcm raspi CLI
