classdef targetHardware < raspi.coder.Hardware & matlab.mixin.CustomDisplay & raspi.coder.deploytohardware
    % TARGETHARDWARE Create a hardware configuration object to deploy a MATLAB® function on the hardware.
    %
    % TARGETHARDWARE(hardwareName) returns the configuration object of the hardware, hardwareName.
    %
    % Example: Create a targetHardware object of the Raspberry Pi™ hardware.
    %
    % hw = targetHardware('Raspberry Pi')
    %
    % See also deploy
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties
        BuildAction = 'Build, load, and run';
    end
    
    properties(Hidden)
        codeGenFolder
    end
    
    properties(Hidden, Constant)
        ValidBuildActions = {'Build', 'Build, load, and run'}
    end
    
    methods
        function obj = targetHardware(hardwareName)
            name = convertStringsToChars(hardwareName);
            % Return an object representing hardware with given name
            hwList = coder.internal.getHardwareNames;
            if isempty(hwList)
                error('coder:hardware:NoHardware', i_getSpkgInstallMsg);
            end
            name = validatestring(name,hwList);
            obj = obj@raspi.coder.Hardware(name);
        end
        
        function set.BuildAction(obj, value)
            obj.BuildAction =  validatestring(value,obj.ValidBuildActions);
        end
        
        
        function deploy(obj, fcnName, varargin)
            % DEPLOY Deploy a MATLAB® function on the hardware.
            %
            % DEPLOY(hwObj, fcnName) deploys a standalone executable on the hardware.
            % The executable is generated from the MATLAB function, fcnName, and is
            % deployed on the hardware specified in the targetHardware object, hwObj.
            %
            % NOTE: The MATLAB function must not have any input and output arguments.
            %
            % Example:
            % hw = targetHardware('Raspberry Pi');
            % deploy(hw, 'raspberrypi_edgedetection');
            %
            % See also targetHardware
            try
                deploy@raspi.coder.deploytohardware(obj,fcnName, varargin{:});
            catch me
                throwAsCaller(me);
            end
        end
    end
    
    methods(Access = protected)
        function displayScalarObject(obj)
            %setup the header
            className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            scalarHeader = [className, ' with properties:' newline];
            %display the header
            fprintf('%s\n',scalarHeader);
            %get the property list
            props = getPropertyGroups(obj);
            %Remove the 'CPUClockRate' fields if it exists
            if isfield(props.PropertyList,'CPUClockRate')
                props.PropertyList = rmfield(props.PropertyList,'CPUClockRate');
            end
            %Fetch the list of properties from the MATLAB props
            requiredProps =  feval(obj.HardwareInfo.MATLABPILInfo.GetPropsFcn);
            orderList = cell(1,(numel(requiredProps)+1));
            orderList{1} = 'Name';
            if ~isempty(requiredProps)
                %Prepare the order list
                for i = 1:numel(requiredProps)
                    orderList{i+1} = requiredProps(i).Name;
                end
            end
            orderList{numel(orderList)+1} = 'BuildAction';
            %re-order the props according to the order list
            props.PropertyList = orderfields(props.PropertyList,orderList);
            if isfield(props.PropertyList,'Password')
                %replace the password with '*'
                props.PropertyList.Password(1:length(props.PropertyList.Password)) = '*';
            end
            %Display the ordered property list
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj,props);
        end
        
    end
end
