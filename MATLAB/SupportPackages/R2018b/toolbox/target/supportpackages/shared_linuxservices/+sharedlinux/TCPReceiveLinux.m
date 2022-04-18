classdef (StrictDefaults)TCPReceiveLinux < sharedlinux.TCPReceive
                        
    % Receive data via tcp
    % Generic LINUX block
    
    %#codegen
    %#ok<*EMCA>    
    
    properties (Hidden, Nontunable)
        Label = 'LINUX'
    end
    
    methods
        % Constructor
        function obj = TCPReceiveLinux(varargin)
            %This would allow the code generation to proceed with the
            %p-files in the installed location of the support package.
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access=protected)       
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            maskDisplayCmdsShared = getMaskDisplayImpl@sharedlinux.TCPReceive(obj);
            maskDisplayCmdsTarget = { ...
                ['color(''blue'');', newline],...     % Drawing mask layout of the block
                ['text(90, 87, ''' obj.Label ''', ''horizontalAlignment'', ''right'');', newline],...
                };
            maskDisplayCmds = [ maskDisplayCmdsShared, maskDisplayCmdsTarget];
        end
    end

end
