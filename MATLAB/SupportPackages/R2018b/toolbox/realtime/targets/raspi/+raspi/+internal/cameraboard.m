classdef cameraboard < handle & matlab.mixin.CustomDisplay
    %CAMERABOARD Create a Camera Board object.
    %
    % cam = cameraboard() creates a camera board object.
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties (Constant)
        Name = 'Camera Board';
    end
    
    properties (GetAccess = public, SetAccess = private)
        Resolution = '640x480';
        FrameRate = 30;
        Quality = 10;
    end
    
    properties (Access = public)
        Rotation = 0;
        HorizontalFlip = false;
        VerticalFlip = false;
        Brightness = 50;
        Contrast = 0;
        Saturation = 0;
        Sharpness = 0;
        VideoStabilization = 'off';
        ExposureMode = 'auto';
        ExposureCompensation = 0;
        AWBMode = 'auto';
        MeteringMode = 'average';
        ImageEffect = 'none';
        ROI = [0.0 0.0 1.0 1.0];
    end
    
    properties (GetAccess = public, SetAccess = private)
        Recording = false;
    end
    
    properties (Dependent, Access = private)
        CameraArgs
        Width
        Height
        CameraAvailable
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
        RaspiObj
        % Maintain a map of created objects to gain exclusive access
        Map = containers.Map();
        Initialized = false;
        Opened = false;
    end
    
    properties (Constant, Access = private)
        % CameraBoard requests
        REQUEST_CAMERABOARD_INIT      = 6000;
        REQUEST_CAMERABOARD_TERMINATE = 6001;
        REQUEST_CAMERABOARD_SNAPSHOT  = 6002;
        REQUEST_CAMERABOARD_CONTROL   = 6003;
        WIDTHOF = struct('d160x120', 160, 'd320x240', 320, ...
            'd640x480', 640, 'd800x600', 800, 'd1024x768', 1024, ...
            'd1280x720', 1280, 'd1920x1080', 1920);
        HEIGHTOF = struct('d160x120', 120, 'd320x240', 240, ...
            'd640x480', 480, 'd800x600', 600, 'd1024x768', 768, ...
            'd1280x720', 720, 'd1920x1080', 1080);
    end
    
    methods
        function obj = cameraboard(RaspiObj, varargin)
            obj.RaspiObj = RaspiObj;
            if nargin > 1
                nameValuePairs = varargin;
            else
                nameValuePairs = {};
            end
            if isUsed(obj, obj.Name)
                error(message('raspi:utils:CameraBoardInUse'));
            end
            try
                parseNameValuePairs(obj, nameValuePairs);
            catch EX
                throwAsCaller(EX);
            end
            
            % Check if camera is recording
            if obj.Recording
                error(message('raspi:utils:CannotCreateObjectWhileRecording'));
            end
            
            % Open camera board for use
            try
                obj.open();
            catch ME
                % Find out if we have a camera
                if ~obj.CameraAvailable
                    error(message('raspi:utils:NoCameraBoard'));
                else
                    baseME = MException(message('raspi:utils:CannotOpenCameraBoard'));
                    EX = addCause(baseME, ME);
                    throw(EX);
                end
            end
            
            % Add object to the container map
            obj.markUsed(obj.Name);
            obj.Initialized = true;
        end
        
        function img = snapshot(obj)
            if ~obj.Opened
                if obj.Recording
                    error(message('raspi:utils:CameraBoardRecording'));
                else
                    obj.open();
                end
            end
            obj.RaspiObj.sendRequest(obj.REQUEST_CAMERABOARD_SNAPSHOT);
            img = jpegread(obj.RaspiObj.recvResponse());
        end
        
        function record(obj, fileName, duration)
            narginchk(3,3);
            validateattributes(fileName, {'char'}, ...
                {'row'}, '', 'fileName');
            validateattributes(duration, {'numeric'}, ...
                {'scalar', 'positive'}, '', 'duration');
            fileName = strtrim(fileName);
            
            % Specify full path of filename is not supported in MATLAB
            % Online for security reason. All files are placed in
            % /home/matlabrpi folder
            s = settings;
            if s.matlab.hardware.raspi.IsOnline.ActiveValue
                if strcmp(fileName(1),'/') || strcmp(fileName(1),'\')
                    error(message('raspi:online:FullPathUnsupported'));
                end
            end
            
            try
                execute(obj.RaspiObj,['touch "', fileName, '"']);
            catch ME
                baseME = MException(message('raspi:utils:InvalidFileName'));
                EX = addCause(baseME, ME);
                throw(EX);
            end
            if obj.Opened
                % Close camera board in raspiserver to launch a recording
                % session using raspivid application
                obj.close();
            else
                if obj.Recording
                    error(message('raspi:utils:CameraBoardRecording'));
                end
            end
            
            % Set duration parameter
            if isinf(duration)
                % Setting duration to zero will make raspivid record video
                % indefinitely until a SIGINT is received
                duration = 0;
            end
            
            % Form command line to launch a recording session with raspivid
            cmd = ['raspivid -t ', num2str(floor(duration*1000)), ' -o ', fileName];
            cmd = [cmd, ' -w ', num2str(obj.Width), ' -h ', num2str(obj.Height)];
            cmd = [cmd, ' -n ', obj.CameraArgs, '&> /dev/null &']; % No preview
            try
                execute(obj.RaspiObj,cmd);
            catch EX
                error(message('raspi:utils:CameraBoardRecordFailed'));
            end
        end
        
        function stop(obj)
            if obj.Recording
                try
                    % Use killall -9 to ensure all raspivid processes are
                    % killed including the one started by popen in MATLAB
                    % Online case
                    execute(obj.RaspiObj,'killall -9 raspivid');
                catch EX
                    error(message('raspi:utils:CameraBoardStopFailed'));
                end
            end
            if ~obj.Opened
                open(obj);
            end
        end
    end
    
    methods
        %% GET/SET methods
        function ret = get.Recording(obj)
            try
                execute(obj.RaspiObj,'pidof raspivid');
                ret = true;
            catch
                ret = false;
            end
        end
        
        function ret = get.CameraAvailable(obj)
            ret = false;
            try
                output = execute(obj.RaspiObj,'vcgencmd get_camera');
                if contains(output,'supported=1 detected=1')
                    ret = true;
                end
            catch EX
                warning(EX.identifier, '%s', EX.message);
            end
        end
        
        function args = get.CameraArgs(obj)
            args = '';
            args = addOption(obj, args, obj.CameraOptions.Rotation, obj.Rotation);
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
        
        function set.Resolution(obj, value)
            value = validatestring(value, obj.AvailableResolutions);
            obj.Resolution = value;
        end
        
        function ret = get.Width(obj)
            ret = obj.WIDTHOF.(['d' obj.Resolution]);
        end
        
        function ret = get.Height(obj)
            ret = obj.HEIGHTOF.(['d' obj.Resolution]);
        end
        
        function set.FrameRate(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan'}, '', 'FrameRate');
            if ~ismember(value, obj.AvailableFrameRates)
                error(message('raspi:utils:InvalidFrameRate', ...
                    obj.AvailableFrameRates(1), obj.AvailableFrameRates(end)));
            end
            obj.FrameRate = value;
        end
        
        function set.HorizontalFlip(obj, value)
            validateattributes(value, {'numeric', 'logical'}, ...
                {'scalar'}, '', 'HorizontalFlip');
            if isnumeric(value) && ~((value == 0) || (value == 1))
                error(message('raspi:utils:InvalidHorizontalFlip'));
            end
            obj.HorizontalFlip = logical(value);
            obj.setCameraParams();
        end
        
        function set.VerticalFlip(obj, value)
            validateattributes(value, {'numeric', 'logical'}, ...
                {'scalar'}, '', 'VerticalFlip');
            if isnumeric(value) && ~((value == 0) || (value == 1))
                error(message('raspi:utils:InvalidVerticalFlip'));
            end
            obj.VerticalFlip = logical(value);
            obj.setCameraParams();
        end
        
        function set.Brightness(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan'}, '', 'Brightness');
            if ~ismember(value, obj.AvailableBrightness)
                error(message('raspi:utils:InvalidBrightness', ...
                    obj.AvailableBrightness(1), obj.AvailableBrightness(end)));
            end
            obj.Brightness = value;
            obj.setCameraParams();
        end
        
        function set.Contrast(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Contrast');
            if ~ismember(value, obj.AvailableContrast)
                error(message('raspi:utils:InvalidContrast', ...
                    obj.AvailableContrast(1), obj.AvailableContrast(end)));
            end
            obj.Contrast = value;
            obj.setCameraParams();
        end
        
        function set.Saturation(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Saturation');
            if ~ismember(value, obj.AvailableContrast)
                error(message('raspi:utils:InvalidSaturation', ...
                    obj.AvailableSaturation(1), obj.AvailableSaturation(end)));
            end
            obj.Saturation = value;
            obj.setCameraParams();
        end
        
        function set.Quality(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Quality');
            if ~ismember(value, obj.AvailableQuality)
                error(message('raspi:utils:InvalidQuality', ...
                    obj.AvailableQuality(1), obj.AvailableQuality(end)));
            end
            obj.Quality = value;
            obj.setCameraParams();
        end
        
        function set.Sharpness(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Sharpness');
            if ~ismember(value, obj.AvailableSharpness)
                error(message('raspi:utils:InvalidSharpness', ...
                    obj.AvailableSharpness(1), obj.AvailableSharpness(end)));
            end
            obj.Sharpness = value;
            obj.setCameraParams();
        end
        
        function set.VideoStabilization(obj, value)
            value = validatestring(value, obj.AvailableVideoStabilizations);
            obj.VideoStabilization = value;
            obj.setCameraParams();
        end
        
        function set.ExposureMode(obj, value)
            value = validatestring(value, obj.AvailableExposureModes);
            obj.ExposureMode = value;
            obj.setCameraParams();
        end
        
        function set.ExposureCompensation(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'ExposureCompensation');
            if ~ismember(value, obj.AvailableExposureCompensations)
                error(message('raspi:utils:InvalidExposureCompensation', ...
                    obj.AvailableExposureCompensations(1), ...
                    obj.AvailableExposureCompensations(end)));
            end
            obj.ExposureCompensation = value;
            obj.setCameraParams();
        end
        
        function set.Rotation(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnegative', 'nonnan'}, '', 'Rotation');
            if ~ismember(value, obj.AvailableRotations)
                error(message('raspi:utils:InvalidRotation'));
            end
            obj.Rotation = value;
            obj.setCameraParams();
        end
        
        function set.ROI(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'size', [1, 4], 'nonnan', 'nonnegative'}, '', 'ROI');
            if any(value > 1.0)
                error(message('raspi:utils:InvalidROI'));
            end
            obj.ROI = value;
            obj.setCameraParams();
        end
        
        function set.AWBMode(obj, value)
            value = validatestring(value, obj.AvailableAWBModes);
            obj.AWBMode = value;
            obj.setCameraParams();
        end
        
        function set.MeteringMode(obj, value)
            value = validatestring(value, obj.AvailableMeteringModes);
            obj.MeteringMode = value;
            obj.setCameraParams();
        end
        
        function set.ImageEffect(obj, value)
            value = validatestring(value, obj.AvailableImageEffects);
            obj.ImageEffect = value;
            obj.setCameraParams();
        end
        
        function set.RaspiObj(obj, value)
            if ~isa(value, 'raspi.internal.raspiBase')
                error(message('raspi:utils:ExpectedRaspiObj'));
            end
            obj.RaspiObj = value;
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            % Display main options
            fprintf('                    Name: %-15s\n', obj.Name);
            fprintf('              Resolution: %-15s (<a href="%s">View available resolutions</a>)\n', ...
                i_getDisplayText(obj.Resolution), i_getHyperlinkAction('Available resolutions', obj.AvailableResolutions));
            fprintf('                 Quality: %-15d (%d to %d)\n', obj.Quality, obj.AvailableQuality(1), obj.AvailableQuality(end));
            fprintf('                Rotation: %-15d (0, 90, 180 or 270)\n', obj.Rotation);
            fprintf('          HorizontalFlip: %-15d\n', obj.HorizontalFlip);
            fprintf('            VerticalFlip: %-15d\n', obj.VerticalFlip);
            fprintf('               FrameRate: %-15d (%d to %d)\n', obj.FrameRate, obj.AvailableFrameRates(1), obj.AvailableFrameRates(end));
            fprintf('               Recording: %-15d\n', obj.Recording);
            
            % Display image quality options
            fprintf('\n   Picture settings\n');
            fprintf('              Brightness: %-15d (%d to %d)\n', obj.Brightness, obj.AvailableBrightness(1), obj.AvailableBrightness(end));
            fprintf('                Contrast: %-15d (%d to %d)\n', obj.Contrast, obj.AvailableContrast(1), obj.AvailableContrast(end));
            fprintf('              Saturation: %-15d (%d to %d)\n', obj.Saturation, obj.AvailableSaturation(1), obj.AvailableSaturation(end));
            fprintf('               Sharpness: %-15d (%d to %d)\n', obj.Sharpness, obj.AvailableSharpness(1), obj.AvailableSharpness(end));
            
            % Display exposure and white balance options
            fprintf('\n   Exposure and AWB\n');
            fprintf('            ExposureMode: %-15s (<a href="%s">View available exposure modes</a>)\n', ...
                i_getDisplayText(obj.ExposureMode), i_getHyperlinkAction('Available exposure modes', obj.AvailableExposureModes));
            fprintf('    ExposureCompensation: %-15d (%d to %d)\n', obj.ExposureCompensation, obj.AvailableExposureCompensations(1), obj.AvailableExposureCompensations(end));
            fprintf('                 AWBMode: %-15s (<a href="%s">View available AWB modes</a>)\n', ...
                i_getDisplayText(obj.AWBMode), i_getHyperlinkAction('Available AWB modes', obj.AvailableAWBModes));
            fprintf('            MeteringMode: %-15s (<a href="%s">View available metering modes</a>)\n', ...
                i_getDisplayText(obj.MeteringMode), i_getHyperlinkAction('Available metering modes', obj.AvailableMeteringModes));
            
            % Display imaging effects
            fprintf('\n   Effects\n');
            fprintf('             ImageEffect: %-15s (<a href="%s">View available image effects</a>)\n', ...
                i_getDisplayText(obj.ImageEffect), i_getHyperlinkAction('Available image effects', obj.AvailableImageEffects));
            fprintf('      VideoStabilization: %-15s\n', i_getDisplayText(obj.VideoStabilization));
            fprintf('                     ROI: [%0.2f %0.2f %0.2f %0.2f] (0.0 to 1.0 [top, left, width, height])', ...
                obj.ROI(1), obj.ROI(2), obj.ROI(3), obj.ROI(4));
            fprintf('\n');
            
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
    
    methods (Access = private)
        function open(obj)
            % Open camera board
            % Initialize CameraBoard
            % int *width = (int *) req->data;
            % int *height = (int *) (req->data + sizeof(int));
            % int *value = (int *) (req->data + 2*sizeof(int));
            % char *cameraParamsStr = (char *) (req->data + 3*sizeof(int));
            obj.RaspiObj.sendRequest(obj.REQUEST_CAMERABOARD_INIT, ...
                int32(obj.Width), ...
                int32(obj.Height), ...
                int32(obj.FrameRate * 2), ... % Latest firmware is somehow requiring 2x frame rate
                int32(obj.Quality), ...
                i_cstr(obj.CameraArgs));
            obj.RaspiObj.recvResponse();
            obj.Opened = true;
        end
        
        function close(obj)
            % Close camera board
            obj.RaspiObj.sendRequest(obj.REQUEST_CAMERABOARD_TERMINATE);
            obj.RaspiObj.recvResponse();
            obj.Opened = false;
        end
        
        function setCameraParams(obj)
            % We set all camera parameters as a batch at the time of object
            % initialization. Setting individual camera parameters after
            % this point should trigger a CONTROL request
            if obj.Initialized && obj.Opened
                obj.RaspiObj.sendRequest(obj.REQUEST_CAMERABOARD_CONTROL, ...
                    i_cstr(obj.CameraArgs));
                obj.RaspiObj.recvResponse();
            end
        end
        
        function delete(obj)
            try
                if obj.Initialized
                    obj.markUnused(obj.Name)
                    obj.close();
                end
            catch
                % do not throw errors/warnings at destruction
            end
        end
        
        function S = saveobj(~)
            S = [];
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:SaveNotSupported', 'cameraboard'));
        end
        
        function parseNameValuePairs(obj, nvPairs)
            names  = nvPairs(1:2:end);
            values = nvPairs(2:2:end);
            propNames = properties(obj);
            for i = 1:length(names)
                if isequal(names{i}, 'Recording')
                    error(message('raspi:utils:RecordingCannotBeSet'));
                end
                if ~ismember(names{i}, propNames)
                    error(message('raspi:utils:NoSuchProperty', names{i}));
                end
                if i <= numel(values)
                    obj.(names{i}) = values{i};
                else
                    error(message('raspi:utils:MissingValue', names{i}));
                end
            end
        end
        
        function option = addROIOption(obj, option, optionStr, ROI)
            option = addOption(obj, option, optionStr);
            for i = 1:3
                option = [option, num2str(ROI(i)), ',']; %#ok<AGROW>
            end
            option = [option, num2str(ROI(4)), ' '];
        end
        
        function option = addOption(obj, option, optionStr, optionVal)
            if nargin < 4
                optionVal = '';
            end
            option = [option, obj.ArgDelimiter, ...
                optionStr, obj.ArgDelimiter];
            if isnumeric(optionVal)
                option = [option, num2str(optionVal)];
            elseif ischar(optionVal)
                option = [option, optionVal];
            else
                error(message('raspi:utils:InvalidCameraOption', ...
                    optionStr, class(optionVal)));
            end
        end
        
        function ret = isUsed(obj, name)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress) && ...
                ismember(name, obj.Map(obj.RaspiObj.DeviceAddress))
                ret = true;
            else
                ret = false;
            end
        end
        
        function markUsed(obj, name)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress)
                used = obj.Map(obj.RaspiObj.DeviceAddress);
                obj.Map(obj.RaspiObj.DeviceAddress) = union(used, name);
            else
                obj.Map(obj.RaspiObj.DeviceAddress) = {name};
            end
        end
        
        function markUnused(obj, name)
            if isKey(obj.Map, obj.RaspiObj.DeviceAddress)
                used = obj.Map(obj.RaspiObj.DeviceAddress);
                obj.Map(obj.RaspiObj.DeviceAddress) = setdiff(used, name);
            end
        end
    end
    
    methods (Hidden, Static)
        function out = loadobj(~)
            out = raspi.internal.cameraboard.empty();
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:LoadNotSupported', ...
                'cameraboard', 'cameraboard'));
        end
    end % methods (Hidden, Static)
end

%% Internal functions
function str = i_getDisplayText(str)
str = ['''' str ''''];
end

function str = i_getHyperlinkAction(title, values)
str = [title, ': '];
for i = 1:length(values)
    str = [str, '''''' values{i}, '''''']; %#ok<AGROW>
    if i ~= length(values)
        str = [str, ', ']; %#ok<AGROW>
    end
end
str = ['matlab:disp(''' str ''')'];
end

function ret = i_cstr(str)
% Add C-string terminator
ret = [str, 0];
end

