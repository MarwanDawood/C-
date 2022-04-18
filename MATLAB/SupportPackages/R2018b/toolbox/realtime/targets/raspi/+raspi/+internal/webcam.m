classdef webcam < handle
    % WEBCAM - The class to represent the web camera
    % You can use WEBCAM to interact with web camera on Beaglebone Black
    % board.
    %
    % mywebcam = webcam(bbb)
    % mywebcam = webcam(bbb, cameraName)
    % mywebcam = webcam(bbb, cameraName, '320x240')
    % mywebcam = webcam(bbb, cameraIndex)
    %
    % Set up connection to web camera. Use bbb.AvailableWebcams to find the
    % camera name or index. If no camera name or index provided, the first
    % camera will be used.
    %
    % WEBCAM Properties:
    %    Name                 - The web camera name
    %    Resolution           - The resolution setting, e.g. '320x240'
    %    AvailabResolution - The available resolutions
    %
    % WEBCAM Methods:
    %    snapshot             - capture a snapshot of camera
    
    % Copyright 2015-2018 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = private)
        Name                    % Web camera name
        Resolution = '320x240'  % Default resolution setting
        AvailableResolutions    % Available resolution settings
    end
    
    properties (Access = private)
        Hw
        DeviceName
        DeviceNum
        CameraMap = containers.Map();
        Width
        Height
    end
    
    properties (Constant, Access = private)
        % Web camera requests
        REQUEST_WEBCAM_INIT        = 9900;
        REQUEST_WEBCAM_SNAPSHOT    = 9901;
        REQUEST_WEBCAM_TERMINATE   = 9902;
    end
    
    methods 
        % Constructor
        function obj = webcam(Hw,arg2,resolution)
            
            % Hardware object check
            narginchk(1, 3);
            validateattributes(Hw, {'raspi.internal.raspiOnline','raspi.internal.raspiDesktop'}, {'nonempty'}, '', 'Hw')
            obj.Hw = Hw;
            
            % Camera check
            if isempty(obj.Hw.AvailableWebcams)
                error(message('raspi:utils:NoWebcam'));
            end
            if nargin > 1
                if isnumeric(arg2) % Index case
                    cameraIndex = arg2;
                    validateattributes(cameraIndex,{'numeric'}, ...
                        {'scalar','integer','>=',1,'<=',numel(obj.Hw.AvailableWebcams)},...
                        '', 'camera index');
                    obj.Name = obj.Hw.WebcamInfo(cameraIndex).Name;
                    obj.DeviceName = obj.Hw.WebcamInfo(cameraIndex).Dev;
                else
                    cameraName = arg2;
                    validateattributes(cameraName,{'char'}, {'nonempty', 'row'},'', 'camera name');
                    [~, idx] = ismember(cameraName, obj.Hw.AvailableWebcams);
                    if idx == 0
                        error(message('raspi:utils:InvalidWebcamName', cameraName));
                    end
                    obj.Name = cameraName;
                    obj.DeviceName = obj.Hw.WebcamInfo(idx).Dev;
                end
            else
                obj.Name = obj.Hw.WebcamInfo(1).Name;
                obj.DeviceName = obj.Hw.WebcamInfo(1).Dev;
            end
            obj.DeviceNum = i_getCameraNum(obj.DeviceName);
            
            if isKey(obj.CameraMap, obj.Name)
                error(message('raspi:utils:WebcamInUse',obj.Name));
            end
            
            % Get available resolutions
            if strfind(obj.Name,'bcm2835-v4l2')
                % Handle Raspberry Pi camera module as a special case
                obj.AvailableResolutions = {'160x120','320x240',...
                    '640x480','800x600','1024x768','1280x720',...
                    '1920x1080'};
            else
                obj.AvailableResolutions = obj.getAvailableResolutions;
            end
            
            % Resolution check
            if(nargin > 2)
                validateattributes(resolution, {'char'}, {'nonempty', 'row'}, '', 'resolution');
                [~, idx] = ismember(resolution, obj.AvailableResolutions);
                if idx == 0
                    error(message('raspi:utils:InvalidWebcamResolution', resolution));
                end
                obj.Resolution = resolution;
            end
            
            [obj.Width, obj.Height] = i_getWidthHeight(obj.Resolution);
            
            % Webcam initialization
            obj.Hw.sendRequest(obj.REQUEST_WEBCAM_INIT, ...
                uint32(obj.DeviceNum), uint32(obj.Width), uint32(obj.Height));
            obj.Hw.recvResponse();
            
            obj.CameraMap(obj.Name) = 1;
        end
        
        % Take a snapshot
        function [image, ts] = snapshot(obj)
            % snapshot - capture a snapshot of web camera
            %   snapshot(obj)
            %
            %   Outputs:
            %       image - image data
            %       ts    - timestamp
            %
            %   Example:
            %       snapshot(mywebcam)
            
            obj.Hw.sendRequest(obj.REQUEST_WEBCAM_SNAPSHOT,...
                uint32(obj.DeviceNum), uint32(obj.Width), uint32(obj.Height));
            data = typecast(obj.Hw.recvResponse(),'uint8');
            
            if length(data) ~= (obj.Width*obj.Height*3)
                error(message('raspi:utils:ErrorWebcamSnapshot'));
            end
            imgSize = obj.Width * obj.Height;
            image(:,:,1) = reshape(data(1:imgSize),obj.Width,obj.Height)';
            image(:,:,2) = reshape(data(imgSize+1:imgSize*2),obj.Width,obj.Height)';
            image(:,:,3) = reshape(data(imgSize*2+1:imgSize*3),obj.Width,obj.Height)';
            ts = datetime;
        end
        
    end
    
    methods (Access = private)
        
        function S = saveobj(~)
            S = [];
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:SaveNotSupported', 'webcam'));
        end
        
        % Destructor
        function delete(obj)
            try
                if isKey(obj.CameraMap, obj.Name)
                    remove(obj.CameraMap, obj.Name);
                    obj.Hw.sendRequest(obj.REQUEST_WEBCAM_TERMINATE, uint32(obj.DeviceNum));
                    obj.Hw.recvResponse();
                end
            catch
                % Do not throw errors/warnings on destruction
            end
        end
    
        % Query the available resolutions supported
        function resolution = getAvailableResolutions(obj)
            resolution = {};
            if obj.Hw.isV4l2Installed
                try
                    output = execute(obj.Hw.Ssh,['v4l2-ctl -d ' obj.DeviceName ' --list-framesizes=YUYV']);            
                    tmp = regexp(output, '\n', 'split');
                    for i=1:numel(tmp)
                        tokens = regexp(tmp{i}, '.+ (?<res>\w+x\w+)', 'names');
                        if ~isempty(tokens)
                            resolution{end + 1} = tokens.res; %#ok<AGROW>
                        end
                    end
                catch
                    resolution = {};
                end
            else
                resolution = {'320x240'};
            end
        end
    end
    
    methods (Hidden, Static)
        function out = loadobj(~)
            out = raspi.internal.webcam.empty();
            sWarningBacktrace = warning('off','backtrace');
            oc = onCleanup(@()warning(sWarningBacktrace));
            warning(message('raspi:utils:LoadNotSupported', ...
                'webcam', 'webcam'));
        end
    end
end

%% helper functions
function [width, height] = i_getWidthHeight(resolution)
p = '(?<width>\w+)x(?<height>\w+)';
tokens = regexp(lower(resolution), p, 'names');
width = str2double(tokens.width);
height = str2double(tokens.height);
end

function num = i_getCameraNum(name)
num = str2double(name(end));
end
