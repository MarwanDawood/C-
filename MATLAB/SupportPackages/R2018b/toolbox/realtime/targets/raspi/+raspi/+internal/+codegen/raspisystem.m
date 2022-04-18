classdef raspisystem < matlab.System ...
        & matlab.system.mixin.Propagates ...
        & coder.ExternalDependency
    %raspisystem System object to execute system commands in raspberry pi
    
    % Copyright 2018 The MathWorks, Inc.
    %#codegen
    
    properties
        maxSystemOut = uint32(16384);
    end
        
    methods
        function obj = raspisystem(varargin)
            coder.allowpcode('plain');
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.maxSystemOut(obj,value)
            validateattributes(value,{'numeric'},...
                {'scalar'},'','maxSystemOut');
            obj.maxSystemOut = uint32(value);
        end
        
        function out = runSystemCmd(obj,varargin)
            out = char(zeros(1,obj.maxSystemOut));
            if nargin == 3
                cmdToExec = [varargin{2},' ',varargin{1}];
            else
                cmdToExec = [varargin{1}];
            end
            
            % Redirect stderr to stdout
            cmdToExec = [cmdToExec, ' ', '2>&1'];
            
            coder.cinclude('MW_raspisystem.h');
            coder.ceval('MW_execSystemCmd',i_cstr(cmdToExec), obj.maxSystemOut, coder.ref(out));
        end
        
    end
    
    methods (Hidden, Static)
        function name = getDescriptiveName()
            name = 'raspisystem';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                srcDir = fullfile(raspi.internal.getRaspiRoot,'src','raspisystem');
                includeDir = fullfile(raspi.internal.getRaspiRoot,'include');
                addIncludePaths(buildInfo,includeDir);
                addIncludeFiles(buildInfo,'MW_raspisystem.h',includeDir);
                addSourceFiles(buildInfo,'MW_raspisystem.c',srcDir);
            end
        end
    end
end

%% Internal functions
function str = i_cstr(str)
str = [str char(0)];
end
