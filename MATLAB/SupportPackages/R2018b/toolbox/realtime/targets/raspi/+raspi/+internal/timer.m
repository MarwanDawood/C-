classdef timer < handle
    % TIMER. Creates a timer obj
    
    % Copyright 2018 The MathWorks, Inc.
    properties (Hidden)
        raspiObj       
    end
    
    properties(Access = private)
        startTime
    end
    
    methods
        % Constructor
        function obj = timer(raspiObj)
            obj.raspiObj = raspiObj;
            obj.startTime = builtin('tic');
        end
        
        function out = elapsedTime(obj)
            out = builtin('toc',obj.startTime);
        end
        
        function reset(obj)
            obj.startTime=builtin('tic');
        end
        
        function delay(~, timeInSec)
           builtin('pause',timeInSec);
        end
    end
    
end