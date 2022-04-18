classdef MQTTPublish < matlab.System ...
        & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.internal.CustomIcon
    % Publish data to MQTT broker.
    
    % Copyright 2018 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % Topic
        Topic = 'topic/level';
        % QoS
        QoS = '0';
    end
    
    properties (Nontunable, Logical)
        % Retain Msg
        RetainMsg = false;
    end
    
    properties (Hidden,Nontunable)
        % Block platform
        blockPlatform = 'RASPBERRYPI';
        QoSIntVal = int32(0);
        RetainFlag = 0;
    end
    
    properties (Constant, Hidden)
        QoSSet = matlab.system.StringSet({'0', '1', '2'});
        Wildcard1 = '#';
        Wildcard2 = '+';
        MAXTOPICLEN = 128;
    end
    
    properties (Hidden)
        MW_dataType
    end
    
    methods
        % Constructor
        function obj = MQTTPublish(varargin)
            %This would allow the code generation to proceed with the
            %p-files in the installed location of the support package.
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.Topic(obj, val)
            coder.extrinsic('error');
            coder.extrinsic('message');
            
            validateattributes(val, ...
                {'char'}, {'nonempty'}, '', 'Topic');
            
            topicLen = numel(val);
            if (topicLen > obj.MAXTOPICLEN)
                error(message('linux:utils:InvalidTopicLength'));
            end
            
            val = strtrim(val);
            
            % Wildcards are not allowed in publish topic
            if (contains(val,'#') || contains(val,'+'))
                error(message('linux:utils:InvalidTopicStr'));
            end
            
            obj.Topic = val;
        end
        
    end
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj, varargin)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            obj.QoSIntVal = int32(obj.getQoSIntVal);
            if obj.RetainMsg
                obj.RetainFlag = int32(1);
            else
                obj.RetainFlag = int32(0);
            end
            
            if ~isempty(coder.target)
                coder.cinclude('MW_MQTT.h');
                coder.ceval('MW_MQTT_publish_setup');
            end
        end
        
        function valOut = getQoSIntVal(obj)
            valIn = obj.QoS;
            switch valIn
                case '0'
                    valOut = 0;
                case '1'
                    valOut = 1;
                case '2'
                    valOut = 2;
                otherwise
                    valOut = 0;
            end
        end
        
        function status = stepImpl(obj, dataIn)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
            status = int8(0);
            dataPayloadLen = uint32(numel(dataIn));
            stringPayloadLen = uint32(0);
            if ~isempty(coder.target)
                switch class(dataIn)
                    case 'double'
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_DOUBLE','HeaderFile','MW_MQTT.h');
                    case 'single'
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_FLOAT','HeaderFile','MW_MQTT.h');
                    case 'int8'
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_I8','HeaderFile','MW_MQTT.h');
                    case {'uint8','logical'}
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_UI8','HeaderFile','MW_MQTT.h');
                    case 'int16'
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_I16','HeaderFile','MW_MQTT.h');
                    case 'uint16'
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_UI16','HeaderFile','MW_MQTT.h');
                    case 'int32'
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_I32','HeaderFile','MW_MQTT.h');
                    case 'uint32'
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_UI32','HeaderFile','MW_MQTT.h');
                    case 'int64'
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_I64','HeaderFile','MW_MQTT.h');
                    case 'uint64'
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_UI64','HeaderFile','MW_MQTT.h');
                    otherwise
                        obj.MW_dataType = coder.opaque('MW_MQTT_Data_Type','MW_MQTT_UI8','HeaderFile','MW_MQTT.h');
                end
                
                payLoadStr = coder.opaque('char*','NULL');
                coder.ceval('MW_sprintf_mqtt',obj.MW_dataType, dataPayloadLen, coder.ref(dataIn), coder.wref(payLoadStr), coder.wref(stringPayloadLen));
                topicStr = cstr(obj.Topic);
                coder.ceval('MW_MQTT_publish_step',obj.RetainFlag, obj.QoSIntVal, stringPayloadLen, coder.ref(payLoadStr), coder.ref(topicStr), coder.wref(status));
            end
        end
        
        function N = getNumInputsImpl(~)
            % Specify number of System inputs
            N = 1;
        end
        
        function N = getNumOutputsImpl(~)
            % Specify number of System outputs
            N = 1;
        end
        
        function N = getOutputSizeImpl(~)
            N = [1,1];
        end
        
        function validateInputsImpl(~, Msg)
            validateattributes(Msg,{'logical','uint8','int8','uint16','int16',...
                'uint32','int32','uint64','int64','double'},{'vector'},'','Msg');
            if (numel(Msg) > 64)
                error(message('linux:utils:InvalidInputVector'));
            end
        end
        
        function out = getOutputDataTypeImpl(~)
            % Return data type for each output port
            out = 'int8';
        end
        
        
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            %Icon display
            iconstr = obj.Topic;
            
            maskDisplayCmds = { ...
                ['color(''white'');', newline],...    % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline],... % Drawing mask layout of the block
                ['plot([0,0,0,0],[0,0,0,0]);', newline],...
                ['color(''black'');', newline] ...
                ['port_label(''input'',1,''Msg'');', newline]...
                ['port_label(''output'',1,''Status'');', newline]...
                ['text(50, 12,''' iconstr ''', ''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');',newline]...
                };
            
            labelSample = obj.blockPlatform;
            maskDisplayCmdsTarget = { ...
                ['color(''blue'');', newline],...
                ['text(96, 90, ''' labelSample ''', ''horizontalAlignment'', ''right'');', newline]...
                };
            maskDisplayCmds = [maskDisplayCmds maskDisplayCmdsTarget];
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
            MaskText = getString(message('linux:blockmask:MQTTPublishMask'));
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','MQTT Publish', ...
                'Text', MaskText);
        end
        
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'MQTT Publish';
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
