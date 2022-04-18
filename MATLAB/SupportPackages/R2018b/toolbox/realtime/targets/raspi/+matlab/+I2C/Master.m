classdef Master < matlab.I2C.Base
    % I2C.Master Class representing an I2C master.
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    properties
        I2CSpeed = 100e3     % 100 Kbps
        AvailableI2CBusNum = 1
        AvailableI2CSpeeds = 100e3;
    end
    
    % ABSTRACT METHODS
    %
    % These must be implemented by every subclass
    methods (Abstract, Access = protected)
        busNums = getAvailableI2CBusNumbers(obj);
    end
    
    methods
        function obj = Master()
            obj.AvailableI2CBusNum = getAvailableI2CBusNumbers(obj);
        end
    end
end
