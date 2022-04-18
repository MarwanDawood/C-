classdef TCPSend < sharedlinux.TCPSend
                        
    % Send data via tcp
    % Generic LINUX block
    
    %#codegen
    %#ok<*EMCA>    
    properties (Hidden, Nontunable,Constant)
        Label = 'RASPBERRYPI';
        %Set the parameter 'ReservedPorts' for conflict check.
        ReservedPorts = [raspi.internal.getServerPort];        
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
    end
    
    methods (Access=protected)       
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            maskDisplayCmdsShared = getMaskDisplayImpl@sharedlinux.TCPSend(obj);
            maskDisplayCmdsTarget = { ...
                ['color(''blue'');', newline],...
                ['text(96, 87, ''' obj.Label ''', ''horizontalAlignment'', ''right'');', newline],...
                };
            maskDisplayCmds = [ maskDisplayCmdsShared, maskDisplayCmdsTarget];
        end
    end

end
