classdef mcp3004 < raspi.internal.mcp300x
    %MCP3004 Create an object for MCP3004 ADC.
    %   
    % sp = mcp3004(raspiObj, channel, speed, vref) creates a SPI device object.
    
    % Copyright 2013 The MathWorks, Inc.
    
    methods
        function obj = mcp3004(varargin)
            obj@raspi.internal.mcp300x(varargin{:});
            obj.NumAdcChannels = 4;
        end
    end
end

