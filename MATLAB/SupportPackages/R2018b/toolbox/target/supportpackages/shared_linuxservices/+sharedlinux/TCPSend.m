classdef (StrictDefaults)TCPSend < matlab.System & matlab.system.mixin.Propagates & ... 
                                   matlab.system.mixin.internal.CustomIcon & ...
                                   coder.ExternalDependency
                                  
    % Send data via tcp
    %
    
    %   Copyright 2016-2018 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>  
    
    properties (Nontunable)
        % Connection mode
        Mode_ = 'Client';
        % Remote IP address
        RemoteAddr_ = '127.0.0.1';
        % Local IP port
        LocalServerPort_ = 25000;
        % Remote IP port
        RemoteServerPort_ = 25000;
        % Local IP port
        ClientPortToBind_ = 35000;
    end

    properties (Nontunable,Logical)
       % Manually specify local IP port
       ClientPortBindingSelection_ = false;
        %Wait until previous packet transmitted
        BlockingMode_ = false;
    end
    
    properties (Nontunable)
        % Timeout in seconds
        BlockTimeout_ = 0.1;
    end

    properties (Nontunable, Logical,Hidden)
        % Print diagnostic messages
        PrintDiagnosticMessages_ = false;
    end

    properties (Hidden)
        connStream_ = uint16(0);
        isServer_ = uint16(0);
        isLittleEnd_ = uint8(0);
        errorNo_ = int16(0);
    end

    properties (Constant, Hidden)
        Mode_Set = matlab.system.StringSet({'Server', 'Client'});
    end
    
    methods
        % Constructor
        function obj = TCPSend(varargin)
            %This would allow the code generation to proceed with the
            %p-files in the installed location of the support package.
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.LocalServerPort_(obj, val)
            classes = {'numeric'};
            attributes = {'nonempty','nonnan','finite','real','nonnegative','nonzero','scalar','integer','<=',65535};
            paramName = 'Local port';
            validateattributes(val,classes,attributes,'',paramName);
            obj.LocalServerPort_ = val;
        end 
        
        function set.RemoteServerPort_(obj, val)
            classes = {'numeric'};
            attributes = {'nonempty','nonnan','finite','real','nonnegative','nonzero','scalar','integer','<=',65535};
            paramName = 'Remort port ';
            validateattributes(val,classes,attributes,'',paramName);
            obj.RemoteServerPort_ = val;
        end
        
        function set.ClientPortToBind_(obj, val)
            classes = {'numeric'};
            attributes = {'nonempty','nonnan','finite','real','nonnegative','nonzero','scalar','integer','<=',65535};
            paramName = 'Local IP port source ';
            validateattributes(val,classes,attributes,'',paramName);
            obj.ClientPortToBind_ = val;
        end
        
        function set.RemoteAddr_(obj, val)
            attributes = {'nonempty'};
            paramName = 'Remote address';
            validateattributes(val,{'char'},attributes,'',paramName);
            if isempty(coder.target)
                ip_expr = '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$';
                hostName_expr = '^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$';
                ip_match = regexp(val,ip_expr,'match');
                hostName_match = regexp(val,hostName_expr,'match');
                if ( isempty(ip_match) && isempty(hostName_match))
                    error(message('shared_linuxservices:utils:InvalidIPAddress'));
                end
            
                if strcmp(val,'0.0.0.0')
                    error(message('shared_linuxservices:utils:InvalidIPAddress'));
                end
            end
            obj.RemoteAddr_ = val;         
        end
        
        function set.BlockTimeout_(obj, val)
            attributes = {'nonempty','nonnan','real','nonnegative','nonzero','scalar'};
            paramName = 'Timeout in seconds';
            validateattributes(val,{'numeric'},attributes,'',paramName);
            obj.BlockTimeout_ = val;
        end
             
    end
    
    methods (Access = protected)
        %% Common functions
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            connStream = uint16(0);
            errorNo = int16(0);
            if coder.target('Rtw')
                %Get the port number
                if strcmp(obj.Mode_,'Server')
                    obj.isServer_ = 1;
                    portNum = obj.LocalServerPort_;
					obj.RemoteAddr_ = 'Server';
                else
                    obj.isServer_ = 0;
                    portNum = obj.RemoteServerPort_;
                end
                
                
                if obj.ClientPortBindingSelection_
                    clientPortToBind = uint16(obj.ClientPortToBind_);
                else
                    clientPortToBind = uint16(0);
                end
                
                if obj.BlockingMode_ == true
                    %pass -1 for infinite blocking 
                    timeout = obj.BlockTimeout_;
                else
                    %Non blocking
                    timeout = 0;
                end
                %Open TCP Stream
                ipaddr = cstr(obj.RemoteAddr_);
                coder.ceval('TCPStreamSetup',uint16(portNum),uint16(clientPortToBind),coder.wref(connStream),uint16(obj.isServer_),double(timeout),coder.wref(errorNo), coder.ref(ipaddr));
                %coder.ceval('TCPStreamSetup',cstr(obj.RemoteAddr_),coder.wref(connStream),cstr(obj.Mode_),double(obj.BlockTimeout_));
                obj.connStream_ = connStream;   
                obj.errorNo_ = errorNo;
                %Endianness check
                isLittleEndian = uint8(0);
                coder.ceval('littleEndianCheck',coder.wref(isLittleEndian));  
                obj.isLittleEnd_ = isLittleEndian;
                
                if obj.PrintDiagnosticMessages_
                    coder.updateBuildInfo('addDefines','PRINT_DEBUG_MESSAGES');
                end
            end                         

        end
        
        function stepImpl(obj, dataIn)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
             [inSizeBytes,nBytes] = calcInputSize(obj,dataIn);
             %Swap bytes if nBytes > 1 and the target is little endian
             if nBytes > 1
                if obj.isLittleEnd_ == 1
                    dataIn = swapbytes(dataIn);
                end                 
             end
             errorNo = int16(0);
             if coder.target('Rtw')
                 coder.ceval('TCPStreamStepSend', coder.rref(dataIn), uint32(inSizeBytes), uint16(obj.connStream_), uint16(obj.isServer_),coder.wref(errorNo));
                 obj.errorNo_ = errorNo;
             end
        end
        
        function resetImpl(obj)
            %TO DO:
            %
        end



        function [inSizeBytes,nBytes] = calcInputSize(obj,dataIn)
            %get the size of input
            dataInLen = numel(dataIn);
            switch class(dataIn)
                case {'int8','uint8','boolean'}
                    nBytes = 1;
                case {'int16','uint16'}
                    nBytes = 2;                    
                case {'int32','uint32'}
                    nBytes = 4;
                case {'int64','uint64'}
                    nBytes = 8;
                case 'single'
                    nBytes = 4;
                case 'double'
                    nBytes = 8;
                otherwise   
                    nBytes = 1;
            end            
            inSizeBytes = dataInLen * nBytes;
        end
        

        function N = getNumInputsImpl(obj)
            % Specify number of System inputs
            N = 1;
        end
        
        function N = getNumOutputsImpl(obj)
            % Specify number of System outputs
            N = 0;
        end

        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            flag = false;
            if strcmp(prop,'RemoteAddr_')
                flag = strcmp(obj.Mode_,'Server');
            end
            
            if strcmp(prop,'LocalServerPort_')
                flag = strcmp(obj.Mode_,'Client');
            end
            
            if strcmp(prop,'RemoteServerPort_')
                flag = strcmp(obj.Mode_,'Server');
            end
            
            if strcmp(prop,'ClientPortBindingSelection_')
                flag = ~strcmp(obj.Mode_,'Client');
            end
            
            if strcmp(prop,'ClientPortToBind_')
                flag = ~((strcmp(obj.Mode_,'Client') && obj.ClientPortBindingSelection_));
            end
            
            if strcmp(prop,'BlockTimeout_')
                flag = ~obj.BlockingMode_;
            end
            
        end
        
        
        function inputname = getInputNamesImpl(~)
            inputname = '';
        end
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            if strcmp(obj.Mode_, 'Client')
                str = ['TCP/IP Client\nAddress:' obj.RemoteAddr_ '\nPort:' sprintf('%d', obj.RemoteServerPort_)];
            else
                str = ['TCP/IP Server\nPort:' sprintf('%d', obj.LocalServerPort_)];
            end
            
            maskDisplayCmds = [ ...
                ['color(''white'');', newline]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline]...            % Drawing mask layout of the block
                ['plot([0,0,0,0],[0,0,0,0]);', newline]...               
                ['color(''black'');', newline] ...
                ['text(50, 50,''' str ''', ''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');'],...
                ];
        end
        
    end
    
    methods(Static, Access = protected)
        %% Simulink customization functions
        function header = getHeaderImpl(~)
            % Define header for the System block dialog box.
            textDisp = getString(message('shared_linuxservices:blockmask:TCPIPSendMaskDescription'));
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', getString(message('shared_linuxservices:blockmask:TCPIPSendMaskTitle')), 'Text', ...
                textDisp,'ShowSourceLink',false);
        end

        function groups = getPropertyGroupsImpl(~)
            % Define section for properties in System block dialog box.
            requiredProps = matlab.system.display.Section(...
                'PropertyList', {'Mode_', 'LocalServerPort_', ...
                'RemoteAddr_', 'RemoteServerPort_'});
            advancedProps = matlab.system.display.Section(...
                'PropertyList', {'ClientPortBindingSelection_', 'ClientPortToBind_', ...
                'BlockingMode_','BlockTimeout_'});
            mainTab = matlab.system.display.SectionGroup(...
                'Title', 'Main', ...
                'Sections',  requiredProps);
           advancedTab = matlab.system.display.SectionGroup(...
                'Title', 'Advanced', ...
                'Sections',  advancedProps);
            groups = [mainTab, advancedTab];
        end
        
        function flag = showSimulateUsingImpl
            % Return false if simulation mode hidden in System block dialog
            flag = false;
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'TCP Send';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                spkgRootDir = codertarget.linux.internal.getSpPkgRootDir;
                
                addIncludePaths(buildInfo, fullfile(spkgRootDir, 'include'));
                addIncludeFiles(buildInfo, 'MW_TCPSendReceive.h');
                
                addSourcePaths(buildInfo, fullfile(spkgRootDir, 'src', 'TCPSendReceive'));
                addSourceFiles(buildInfo, 'MW_TCPSendReceive.c', fullfile(spkgRootDir, 'src', 'TCPSendReceive'), 'BlockModules');
            end
        end
    end
end

%% Internal functions
function str = cstr(str)
str = [str(:).', char(0)];
end

