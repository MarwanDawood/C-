classdef timer < matlab.System ...
        & coder.ExternalDependency
   
    % Copyright 2018 The MathWorks, Inc.
    
    %#codegen
    properties(Hidden)
        % Add properties       
        TimerID 
    end
    
    methods
        function obj = timer(varargin)
            setProperties(obj,nargin,varargin{:});            
            obj.TimerID = uint8(0);
            obj.TimerID = coder.ceval('initMWTimer');
        end
        
        
        
        function delay(~,timeInSec)
            % Create timer obj and wait for timer event to trigger
            DelayTimerID = int32(0);
            DelayTimerID  = coder.ceval('mw_CreateArmedTimer',timeInSec);
            coder.ceval('mw_WaitForTimerEvent',DelayTimerID);
        end
        
        function t = elapsedTime(obj) 
            t = double(0);
             coder.ceval('getMWTimerValue',obj.TimerID, coder.wref(t));
        end
        
        function reset(obj)
            coder.ceval('resetMWTimer',obj.TimerID);
        end        
    end
    
    methods (Hidden, Static)        
        function name = getDescriptiveName(~)
            name = 'Raspi timer';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                serverDir = fullfile(raspi.internal.getRaspiRoot,'server');
                addIncludePaths(buildInfo,serverDir);
                addIncludeFiles(buildInfo,'MW_raspi_timer.h',serverDir);
                addSourceFiles(buildInfo,'MW_raspi_timer.c',serverDir);
            end
        end
    end
end

% LocalWords:  raspi mw linuxinitialize fullpath
