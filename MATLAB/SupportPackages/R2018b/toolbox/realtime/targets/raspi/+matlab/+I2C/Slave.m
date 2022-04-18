classdef Slave < matlab.I2C.Base
    % I2C.Master Class representing an I2C master.
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    properties
        Bus = 0
        Address = 0
    end
    
% A reference to Master is not needed and dropped to reduce long-term
% coupling:
%
%     properties (Access = protected)
%         I2CMaster
%     end
    
    properties (Access = protected)
        MaximumI2CSpeed = 100e3
    end
    
    methods
        function obj = Slave()            
        end
    end
    
    methods (Access = protected)
        function checkI2CMasterCompatible(obj,master)
            coder.extrinsic('error');
            if isempty(find(ismember(superclasses(master),'matlab.I2C.Master'),1))
                error('SVD:i2cslave:IncompatibleMaster',...
                    'Master object must inherit from I2C.Master class');
            end
            if master.I2CSpeed > obj.MaximumI2CSpeed
                error('I2CMater:utils:IncompatibleSpeed',...
                    'Incompatible speed.');
            end
            if ~ismember(obj.Bus,master.AvailableI2CBusNum)
                error('I2CMater:utils:IncompatibleBus',...
                    'Incompatible bus.');
            end
        end
    end
end