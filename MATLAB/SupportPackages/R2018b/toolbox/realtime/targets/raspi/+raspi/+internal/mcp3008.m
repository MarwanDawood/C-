classdef mcp3008 < raspi.internal.mcp300x
    %MCP3008 Create an object for MCP3008 ADC.
    %   
    % sp = mcp3008(raspiObj, channel, speed, vref) creates a SPI device object.
    
    % Copyright 2013 The MathWorks, Inc.
    
    methods
        function obj = mcp3008(varargin)
            obj@raspi.internal.mcp300x(varargin{:});
            obj.NumAdcChannels = 8;
        end
    end
end

