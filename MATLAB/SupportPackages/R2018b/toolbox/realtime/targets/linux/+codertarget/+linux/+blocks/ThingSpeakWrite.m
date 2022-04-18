classdef (StrictDefaults)ThingSpeakWrite < matlab.System ...
        & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.CustomIcon
    % Send data to online service ThingSpeak.
    %
    
    %   Copyright 2016 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % Update URL
        UpdateURL = '184.106.153.149';
        % Write API key
        WriteAPIKey = 'ABCDEFGHIJK';
        % Number of variables
        NumberOfVariables = 1;
        % Coordinate source
        CoordinatesSource = 'Block dialog';
        % Status message source
        StatusSource = 'Block dialog';
        Coordinates = [42.29971, -71.350719, 69.29]; % Coordinates (latitude, longitude, altitude)
        % Status message
        StatusMessage = 'OK';
        % Update interval
        UpdateInterval = 15;
    end
    
    properties (Nontunable, Logical)
        % Print diagnostic messages
        PrintDiagnosticMessages = false;
        % Send status message
        StatusEnabled = false;
        % Send location information
        CoordinatesEnabled = false;
    end
    
    properties (Nontunable, Logical, Hidden)
        Debug = false;
    end
    
    properties (Hidden, Access=private)
        LastUpdateTime
    end
    
    properties (Constant, Hidden)
        AvailableNumberOfChannels = 1:8;
        CoordinatesSourceSet = matlab.system.StringSet({'Block dialog', 'Input port'});
        StatusSourceSet = matlab.system.StringSet({'Block dialog', 'Input port'});
    end % Hidden properties
    
    
    methods
        % Constructor
        function obj = ThingSpeakWrite(varargin)
            %This would allow the code generation to proceed with the
            %p-files in the installed location of the support package.
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.NumberOfVariables(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar', ...
                '>=', obj.AvailableNumberOfChannels(1), ...
                '<=', obj.AvailableNumberOfChannels(end)}, '', ...
                'NumberOfChannels');
            obj.NumberOfVariables = val;
        end
        
        function set.UpdateURL(obj, val)
            validateattributes(val, ...
                {'char'}, {'nonempty'}, '', 'UpdateURL');
            obj.UpdateURL = strtrim(val);
        end
        
        function set.WriteAPIKey(obj, val)
            validateattributes(val, ...
                {'char'}, {'nonempty'}, '', 'WriteAPIKey');
            obj.WriteAPIKey = strtrim(val);
        end
        
        function set.Coordinates(obj, val)
            validateattributes(val, {'single', 'double'}, ...
                {'numel', 3, 'real', 'nonnan', 'finite'}, '', 'Coordinates');
            obj.Coordinates = val;
        end
        
        function set.UpdateInterval(obj, val)
            validateattributes(val, {'single', 'double'}, ...
                {'scalar', 'real', 'nonnegative', 'nonnan', 'finite'}, '', 'UpdateInterval');
            obj.UpdateInterval = val;
        end
        
        function set.StatusMessage(obj, val)
            if ~ischar(val)
                validateattributes(val, {'uint8', 'char'}, ...
                    {''}, '', 'StatusMessage');
            end
            obj.StatusMessage = strtrim(val);
        end
    end
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj, varargin)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            if ~isempty(coder.target)
                coder.cinclude('MW_thingspeak.h');
                coder.ceval('MW_initThingSpeak', cstr(obj.UpdateURL), ...
                    cstr(obj.WriteAPIKey), obj.UpdateInterval, ...
                    obj.PrintDiagnosticMessages);
            end
        end
        
        function stepImpl(obj, varargin)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            if ~isempty(coder.target)
                ptr = coder.opaque('TSData_t *');
                currentTime = coder.nullcopy(uint32(0));
                currentTime = coder.ceval('MW_getCurrentTimeInMillis');
                if (obj.LastUpdateTime == uint32(0)) || ...
                        ((currentTime - obj.LastUpdateTime) >= 1000*obj.UpdateInterval)
                    obj.LastUpdateTime = currentTime;
                    ptr = coder.ceval('MW_startThingSpeak', cstr(obj.UpdateURL), ...
                        cstr(obj.WriteAPIKey), obj.PrintDiagnosticMessages);
                    for k = 1:obj.NumberOfVariables
                        u = double(varargin{k});
                        coder.ceval('MW_addField', ptr, u, uint8(k));
                    end
                    if obj.CoordinatesEnabled
                        if isequal(obj.CoordinatesSource, 'Block dialog')
                            coder.ceval('MW_addLocation', ptr, obj.Coordinates);
                        else
                            c = double(varargin{k+1});
                            coder.ceval('MW_addLocation', ptr, coder.rref(c));
                        end
                    end
                    if obj.StatusEnabled
                        if isequal(obj.StatusSource, 'Block dialog')
                            coder.ceval('MW_addStatus', ptr, obj.StatusMessage);
                        else
                            statusMsg = cstr(char(varargin{nargin - 1}));
                            coder.ceval('MW_addStatus', ptr, statusMsg);
                        end
                    end
                    coder.ceval('MW_postThingSpeak', ptr, cstr(obj.UpdateURL), ...
                        cstr(obj.WriteAPIKey), obj.PrintDiagnosticMessages);
                end
            end
        end
        
        function resetImpl(obj)
            obj.LastUpdateTime = uint32(0);
        end
        
        function N = getNumInputsImpl(obj)
            % Specify number of System inputs
            N = obj.NumberOfVariables + (obj.CoordinatesEnabled && ...
                strcmp(obj.CoordinatesSource,'Input port')) + ...
                (obj.StatusEnabled && strcmp(obj.StatusSource,'Input port'));
        end
        
        function N = getNumOutputsImpl(~)
            % Specify number of System outputs
            N = 0;
        end
        
        function validateInputsImpl(obj, varargin)
            for k = 1:obj.NumberOfVariables
                validateattributes(varargin{k},{'numeric'}, ...
                    {'scalar','nonnan','finite'},'','input');
            end
            if obj.CoordinatesEnabled && isequal(obj.CoordinatesSource,'Input port')
                k = k + 1;
                validateattributes(varargin{k},{'single','double'}, ...
                    {'numel',3,'nonnan','finite'},'','Coordinates');
            end
            if obj.StatusEnabled && isequal(obj.StatusSource,'Input port')
                validateattributes(varargin{nargin - 1},{'int8','uint8','char'}, ...
                    {''},'','status');
            end
        end
        
        function icon = getIconImpl(~)
            % Define a string as the icon for the System block in Simulink.
            icon = mfilename('ThingSpeak Write');
        end
    end
    
    methods(Static, Access = protected)
        %% Simulink customization functions
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
        function header = getHeaderImpl(~)
            % Define header for the System block dialog box.
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', 'ThingSpeak', 'Text', ...
                'Send data to online service ThingSpeak.');
        end
        
        function groups = getPropertyGroupsImpl(~)
            % Define section for properties in System block dialog box.
            requiredProps = matlab.system.display.Section(...
                'Title', 'Main',...
                'PropertyList', {'UpdateURL', 'WriteAPIKey', ...
                'NumberOfVariables', 'UpdateInterval', 'PrintDiagnosticMessages'});
            optionalProps = matlab.system.display.Section(...
                'Title', 'Optional',...
                'PropertyList', {'CoordinatesEnabled', 'CoordinatesSource', ...
                'Coordinates', 'StatusEnabled', 'StatusSource', 'StatusMessage'});
            mainTab = matlab.system.display.SectionGroup(...
                'Title', 'Main', ...
                'Sections',  requiredProps);
            optionalTab = matlab.system.display.SectionGroup(...
                'Title', 'Optional', ...
                'Sections',  optionalProps);
            groups = [mainTab, optionalTab];
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'ThingSpeak Write';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            % Update the build-time buildInfo
            if context.isCodeGenTarget('rtw')
                % Header paths
                rootDir = realtime.internal.getLinuxRoot();
                buildInfo.addIncludePaths(fullfile(rootDir,'include'));
                buildInfo.addIncludeFiles('MW_thingspeak.h');
                systemTargetFile = get_param(buildInfo.ModelName,'SystemTargetFile');
                if isequal(systemTargetFile,'ert.tlc')
                    % Add the following when not in rapid-accel simulation
                    buildInfo.addSourceFiles('MW_thingspeak.c',fullfile(rootDir,'src'));
                    addLinkFlags(buildInfo,'-lcurl');
                end
            end
        end
    end
end

%% Internal functions
function str = cstr(str)
str = [str(:).', char(0)];
end
