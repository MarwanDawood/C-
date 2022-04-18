classdef MQTTSubscribe < matlab.System ...
        & matlab.system.mixin.internal.SampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.internal.CustomIcon
    % Subscribe to a topic from the MQTT broker.
    
    % Copyright 2018 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % Topic
        Topic = 'topic/level/#';
        % QoS
        QoS = '0';
        % Message length (N)
        MessageLength = 1;
        % Sample time
        SampleTime = 1;
    end
    
    properties (Nontunable, Logical, Hidden)
        Debug = false;
    end
    
    properties (Hidden,Nontunable)
        % Block platform
        blockPlatform = 'RASPBERRYPI';
    end
    
    properties (Constant, Hidden)
        QoSSet = matlab.system.StringSet({'0', '1', '2'});
        Wildcard1 = '#';
        Wildcard2 = '+';
        MAXTOPICLEN = 128;
    end
    
    properties (Hidden)
        subscribeID = uint16(0);
    end
    
    methods
        % Constructor
        function obj = MQTTSubscribe(varargin) 
            %This would allow the code generation to proceed with the
            %p-files in the installed location of the support package.
            coder.allowpcode('plain');
            
            setProperties(obj,nargin,varargin{:});
        end
        
        
        function set.Topic(obj, val)
            coder.extrinsic('error');
            coder.extrinsic('message');
            coder.extrinsic('checkTopicStr');
            
            validateattributes(val, ...
                {'char'}, {'nonempty'}, '', 'Topic');
            
            topicLen = numel(val);
            if (topicLen > obj.MAXTOPICLEN)
                error(message('linux:utils:InvalidTopicLength'));
            end
            
            val = strtrim(val);
            
            % Wildcard validation
            checkTopicStr(val);
            
            obj.Topic = val;
        end
        
        function set.MessageLength(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'integer','nonzero','positive','scalar', 'real', 'nonnan','<=',64}, '', 'Message length (N)');
            obj.MessageLength = val;
        end
        
        function set.SampleTime(obj,sampleTime)
            coder.extrinsic('error');
            coder.extrinsic('message');
            
            validateattributes(sampleTime,{'numeric'},...
                {'nonnan', 'finite'},...
                '','''Sample time''');
            
            % Sample time must be a real scalar value or 2 element array.
            if ~isreal(sampleTime(1)) || numel(sampleTime) > 2
                error(message('linux:utils:InvalidSampleTimeNeedScalar'));
            end
            if numel(sampleTime) == 2 && sampleTime(1) > 0.0 && sampleTime(2) >= sampleTime(1)
                error(message('linux:utils:InvalidSampleTimeNeedSmallerOffset'));
            end
            if numel(sampleTime) == 2 && sampleTime(1) == -1.0 && sampleTime(2) ~= 0.0
                error(message('linux:utils:InvalidSampleTimeNeedZeroOffset'));
            end
            if numel(sampleTime) == 2 && sampleTime(1) == 0.0 && sampleTime(2) ~= 1.0
                error(message('linux:utils:InvalidSampleTimeNeedOffsetOne'));
            end
            if numel(sampleTime) ==1 && sampleTime(1) < 1 && sampleTime(1) ~= -1.0
                error(message('linux:utils:InvalidSampleTimeNeedPositive'));
            end
            obj.SampleTime = sampleTime;
        end
          
    end
    
    methods (Access=protected)
        %% Common functions
        function setupImpl(obj, varargin)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            if ~isempty(coder.target)
                coder.cinclude('MW_MQTT.h');
                topicStr = cstr(obj.Topic);
                % Generate regular exp to match topics
                topicRegExp = strrep(obj.Topic,'+','(.*[^/])');
                topicRegExp = strrep(topicRegExp,'#','.*');
                topicRegExpStr = cstr(topicRegExp);
                subID = uint16(0);
                coder.ceval('MW_MQTT_subscribe_setup',coder.rref(topicStr),coder.rref(topicRegExpStr),coder.wref(subID));
                obj.subscribeID = subID;
            end
        end
        
        function [isNew, Msg, Topic] = stepImpl(obj)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            isNew = uint8(0);
            Topic = zeros(1,obj.MAXTOPICLEN,'uint8');
            Msg = zeros(1,obj.MessageLength);
            if coder.target('Rtw')
                id = uint16(obj.subscribeID);
                msgLen = uint16(obj.MessageLength);
                coder.ceval('MW_MQTT_subscribe_step', id, msgLen,coder.wref(isNew), coder.wref(Msg),coder.wref(Topic));
            end
        end
        
        function releaseImpl(~)
            if coder.target('Rtw')
                % TO DO: add terminate function
            end
        end
        
        
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        function num = getNumOutputsImpl(obj)
            if (~(isempty(find(contains(obj.Topic,obj.Wildcard1),1))) || ~(isempty(find(contains(obj.Topic,obj.Wildcard2),1))))
                num = 3;
            else
                num = 2;
            end
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(obj,~)
            varargout{1} = true;
            varargout{2} = true;
            if (~(isempty(find(contains(obj.Topic,obj.Wildcard1),1))) || ~(isempty(find(contains(obj.Topic,obj.Wildcard2),1))))
                varargout{3} = true;
            end
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(obj)
            varargout{1} = false;
            varargout{2} = false;
            if (~(isempty(find(contains(obj.Topic,obj.Wildcard1),1))) || ~(isempty(find(contains(obj.Topic,obj.Wildcard2),1))))
                varargout{3} = false;
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            varargout{1} = [1,1];
            varargout{2} = [1,obj.MessageLength];
            if (~(isempty(find(contains(obj.Topic,obj.Wildcard1),1))) || ~(isempty(find(contains(obj.Topic,obj.Wildcard2),1))))
                varargout{3} = [1,obj.MAXTOPICLEN];
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            % Return data type for each output port
            varargout{1} = 'uint8';
            varargout{2} = 'double';
            if (~(isempty(find(contains(obj.Topic,obj.Wildcard1),1))) || ~(isempty(find(contains(obj.Topic,obj.Wildcard2),1))))
                varargout{3} = 'uint8';
            end
        end
        
        function st = getSampleTimeImpl(obj)
            st = obj.SampleTime;
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            %Icon display
            iconstr = obj.Topic;
            if ~isempty(regexp(iconstr,'\'' *\''','match'))
                iconstr = '';
            end
            port1LabelIsNew = ['port_label(''output'',1,''IsNew',''');'];
            if (~(isempty(find(contains(obj.Topic,obj.Wildcard1),1))) || ~(isempty(find(contains(obj.Topic,obj.Wildcard2),1))))
                port1LabelMsg = ['port_label(''output'',2,''Msg',''');'];
                port1LabelTopic = ['port_label(''output'',3,''Topic',''');'];
            else
                port1LabelTopic = [];
                port1LabelMsg = ['port_label(''output'',2,''Msg',''');'];
            end
            
            maskDisplayCmds = { ...
                ['color(''white'');', newline],...    % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline],... % Drawing mask layout of the block
                ['plot([0,0,0,0],[0,0,0,0]);', newline],...
                ['color(''black'');', newline] ...
                [port1LabelIsNew, newline],...
                [port1LabelTopic, newline],...
                [port1LabelMsg, newline],...
                ['text(50, 12,''' iconstr ''', ''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');',newline]...
                };
            
            labelSample = obj.blockPlatform;
            maskDisplayCmdsTarget = { ...
                ['color(''blue'');', newline],...
                ['text(75, 90, ''' labelSample ''', ''horizontalAlignment'', ''right'');', newline],...
                ['color(''black'');', newline],...
                };
            maskDisplayCmds = [maskDisplayCmds maskDisplayCmdsTarget];
        end
        
        
    end
        
    methods (Static, Access=protected)
        
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
        function header = getHeaderImpl()
            MaskText = getString(message('linux:blockmask:MQTTSubscribeMask'));
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','MQTT Subscribe', ...
                'Text', MaskText);
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = getString(message('linux:blockmask:MQTTSubscribeBlockName'));
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
                buildInfo.addIncludeFiles('MW_MQTT.h');
                systemTargetFile = get_param(buildInfo.ModelName,'SystemTargetFile');
                if isequal(systemTargetFile,'ert.tlc')
                    % Add the following when not in rapid-accel simulation
                    buildInfo.addSourceFiles('MW_MQTT.c',fullfile(rootDir,'src'));
                    addLinkFlags(buildInfo,'-lpaho-mqtt3a');
                end
            end
        end
    end
end

% Internal functions
function str = cstr(str)
str = [str(:).', char(0)];
end


function status = checkTopicStr(val)
coder.extrinsic('error');
coder.extrinsic('message');
coder.extrinsic('regexp');
status = true;

if (contains(val,'#'))
    % Check the usage of # wildcard
    numOfWildCard = numel(strfind(val,'#'));
    
    if (numOfWildCard ~= 1)
        error(message('linux:utils:InvalidTopicStr'));
    else
        % Check if # is placed at the end of topic
        if ~(strcmp(val,'#') || ~isempty(regexp(val,'/#$','ONCE')))
            error(message('linux:utils:InvalidTopicStr2'));
        end
    end
end

if (contains(val,'+'))
    % Check the usage of + wildcard
    numOfWildCard = numel(strfind(val,'+'));
    
    match1 = numel(regexp(val,'\/\+\/','match'));
    match2 = numel(regexp(val,'\+\/\+','match'));
    
    if any((numOfWildCard ~= (match1 + match2)))
        error(message('linux:utils:InvalidTopicStr1'));
    end
end
end