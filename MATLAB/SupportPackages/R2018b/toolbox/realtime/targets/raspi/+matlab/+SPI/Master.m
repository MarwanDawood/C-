classdef Master < matlab.SPI.Base
    % SPI.Master Class representing an SPI master.
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    properties
        SPISpeed = 500e3
        AvailableChipSelect = 0
        AvailableSPIMode = [0, 1, 2, 3]
    end
    
    % ABSTRACT METHODS
    %
    % These must be implemented by every subclass
    methods (Abstract, Access = protected)
        cs = getAvailableSPIChipSelect(obj);
    end
    
    methods
        function obj = Master()
            obj.AvailableChipSelect = getAvailableSPIChipSelect(obj);
        end
    end
end
