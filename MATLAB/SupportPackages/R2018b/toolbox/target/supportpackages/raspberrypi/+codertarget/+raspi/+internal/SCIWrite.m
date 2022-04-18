classdef SCIWrite < matlabshared.svd.SCIWrite ...
        & coder.ExternalDependency
    %SCIWrite Set the logical value of a digital output pin.
    %
    
    %#codegen
    
    properties (Nontunable)
        %SCIModule SCI module
        SCIModule = '/dev/ttyAMA0';
    end
    
    methods
        function set.SCIModule(obj,value)
            if ~coder.target('Rtw') && ~coder.target('Sfun')
                if ~isempty(obj.Hw)
                    if ~isValidSCIModule(obj.Hw,value)
                        error(message('svd:svd:ModuleNotFound','SCI',value));
                    end
                end
            end
            obj.SCIModule = strtrim(value);
        end
    end
    
    methods
        function obj = SCIWrite(varargin)
        coder.allowpcode('plain');
        obj.Hw = codertarget.raspi.internal.Hardware;
        obj.Logo = 'RASPBERRYPI';
        obj.HardwareFlowControl = 'None';
        obj.ByteOrder = 'LittleEndian';
        setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods(Access = protected)
        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            flag = isInactivePropertyImpl@matlabshared.svd.SCIWrite(obj, prop);
            switch prop
                case {'HardwareFlowControl', 'ByteOrder','OutputStatus'}
                    flag = true;
            end
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
        name = 'SCI Write';
        end
        
        function b = isSupportedContext(context)
        b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
        if context.isCodeGenTarget('rtw')
            % SCI interface
            spkgrootDir = codertarget.raspi.internal.getSpPkgRootDir;
            raspiserverDir = fullfile(raspi.internal.getRaspiRoot, 'server');
            addIncludePaths(buildInfo, raspiserverDir);
            svdDir = matlabshared.svd.internal.getRootDir;
            addIncludePaths(buildInfo,fullfile(svdDir,'include'));
            addIncludeFiles(buildInfo,'MW_SCI.h');
            addSourcePaths(buildInfo, fullfile(spkgrootDir,'src'));
            addSourceFiles(buildInfo,'MW_SCI.c', fullfile(spkgrootDir,'src'), 'BlockModules');
        end
        end
    end
end
%[EOF]
