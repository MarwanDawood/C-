classdef Slave < matlab.SPI.Base
    % I2C.Master Class representing an I2C master.
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    properties
        ChipSelect = 0
        Mode = 0
    end
    
    methods
        function obj = Slave(varargin)            
        end
    end
    
    methods (Access = protected)
        function checkSPIMasterCompatible(obj,master)
            coder.extrinsic('error');
            if isempty(find(ismember(superclasses(master),'matlab.SPI.Master'),1))
                error('SVD:spislave:IncompatibleMaster',...
                    'Master object must inherit from SPI.Master class.');
            end
            if ~ismember(obj.ChipSelect,master.AvailableChipSelect)
                error('SVD:spislave:IncompatibleChipSelect',...
                    'Incompatible speed.');
            end
            if ~ismember(obj.Mode,master.AvailableSPIMode)
                error('SVD:spislave:IncompatibleSPIMode',...
                    'Incompatible SPI mode.');
            end
        end
    end
end