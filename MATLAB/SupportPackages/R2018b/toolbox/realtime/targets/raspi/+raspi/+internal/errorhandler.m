classdef errorhandler < handle
    %ERRORHANDLER Handle error received fromthe server.
    %
    %
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties (Access = public)
        EX
    end
    
    methods
        function obj = errorhandler(errno)
            % Constructor
            try
                obj.EX = MException(message(['raspi:server:ERRNO', num2str(errno)]));
            catch
                obj.EX = MException(message('raspi:server:ERRNO'));
            end
        end
        
        function throw(obj)
            throw(obj.EX);
        end
        
        function EX = MException(obj)
            EX = obj.EX;
        end
    end
end % classdef

%[EOF]