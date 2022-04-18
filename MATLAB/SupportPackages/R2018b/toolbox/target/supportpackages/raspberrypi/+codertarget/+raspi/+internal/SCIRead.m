classdef SCIRead < matlabshared.svd.SCIRead ...
        & coder.ExternalDependency
    %SCIRead Set the logical value of a digital output pin.
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
        function obj = SCIRead(varargin)
        coder.allowpcode('plain');
        obj.Hw = codertarget.raspi.internal.Hardware;
        obj.Logo = 'RASPBERRYPI';
        obj.HardwareFlowControl = 'None';
        obj.ByteOrder = 'LittleEndian';
        obj.OutputStatus = true;
        setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods(Access = protected)
        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog
            flag = isInactivePropertyImpl@matlabshared.svd.SCIRead(obj, prop);
            switch prop
                case {'HardwareFlowControl', 'ByteOrder', 'OutputStatus'}
                    flag = true;
            end
        end
        
        function setupImpl(obj)
        coder.extrinsic('num2str');
%         % Define outport size
%         size_out = getOutputSizeImpl(obj);
%         size_t = size_out(1)*2;
%         coder.updateBuildInfo('addDefines',['MW_SERIAL_BUF_SIZE=' coder.const(num2str(size_t))]);
        % Initialise SCI Module
        setupImpl@matlabshared.svd.SCIRead(obj);
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
        name = 'SCI Read';
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
