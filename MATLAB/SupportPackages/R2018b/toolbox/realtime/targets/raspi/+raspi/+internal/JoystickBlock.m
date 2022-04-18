classdef JoystickBlock < matlab.System & matlab.system.mixin.Propagates ...
         & coder.ExternalDependency
    
    % Copyright 2016 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties(Hidden, Access=private)
        Keypressed
        fd
        PositionEnum
    end
    
    properties(Nontunable)
        %SampleTime
        SampleTime = 0.1;
    end
    
    methods
        % Constructor
        function obj = JoystickBlock(varargin)
            %This would allow the code generation to proceed with the
            %p-files in the installed location of the support package.
            coder.allowpcode('plain');
            
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    
    %% Output properties
    methods (Access=protected)
        
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            if coder.target('Rtw')
                coder.cinclude('MW_joystickBlock.h');
                obj.fd = uint8(0);
                obj.fd = coder.ceval('JOYSTICK_BLOCK_INIT');
            end
        end
        
        function positionID=stepImpl(obj)
            % Implement algorithm. Calculate y as a function of
            % input u and discrete states.
             positionID = uint8(0);
            if coder.target('Rtw')               
                positionID = coder.ceval('JOYSTICK_BLOCK_READ',obj.fd);
            end
        end
        
        function releaseImpl(obj)
            % Release resources, such as file handles
            if coder.target('Rtw')
                coder.ceval('JOYSTICK_BLOCK_TERMINATE',obj.fd);
            end
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(~)
            varargout = {true};
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout = {false,false};
        end
        
        function varargout = getOutputSizeImpl(~)
            varargout = {[1,1]};
        end
        
        function varargout = getOutputDataTypeImpl(~)
            varargout = {'uint8'};
        end
        
    end
    
     methods
         function set.SampleTime(obj,newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');
            if isLocked(obj)
                error(message('svd:svd:SampleTimeNonTunable'))
            end
            newTime = matlabshared.svd.internal.validateSampleTime(newTime);
            obj.SampleTime = newTime;
        end
        
        function st = getSampleTimeImpl(obj)
            st = obj.SampleTime;
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    %% Each class should be able to add to buildInfo
    methods (Static)
        function name = getDescriptiveName()
            name = 'Joystick';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')               
                rootDir = fullfile(raspi.internal.getRaspiRoot,'server');
                addIncludePaths(buildInfo,rootDir);
                addIncludeFiles(buildInfo,'common.h');
                addIncludeFiles(buildInfo,'devices.h');
                addIncludeFiles(buildInfo,'MW_joystickBlock.h');
                addSourceFiles(buildInfo,'devices.c',rootDir);
                addSourceFiles(buildInfo,'MW_joystickBlock.c',rootDir);
            end
        end
    end
end

