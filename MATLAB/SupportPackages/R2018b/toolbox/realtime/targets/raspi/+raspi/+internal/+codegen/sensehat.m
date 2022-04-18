classdef sensehat < handle ...
%SENSEHAT codegen class

% Copyrights 2018 The MathWorks, Inc.

%#codegen 


methods(Hidden)
    function obj = sensehat(~,varargin)
        %No action during code generation
    end
    
    function [varargout] = readTemperature(~,varargin)
        [varargout{1:nargout}] = functionNotSupported('readTemperature');
    end
    
    function [varargout] = readHumidity(~)
        [varargout{1:nargout}] = functionNotSupported('readHumidity');
    end
    
    function  [varargout] = readPressure(~)
        [varargout{1:nargout}] = functionNotSupported('readPressure');
    end
    
    function [varargout] = readAngularVelocity(~,varargin)
        [varargout{1:nargout}] = functionNotSupported('readAngularVelocity');
    end
    
    function [varargout] = readAcceleration(~,varargin)
        [varargout{1:nargout}] = functionNotSupported('readAcceleration');
    end
    
    function [varargout] = readMagneticField(~,varargin)
        [varargout{1:nargout}] = functionNotSupported('readMagneticField');
    end
    
    function [varargout] = readJoystick(~,varargin)
        [varargout{1:nargout}] = functionNotSupported('readJoystick');
    end
    
    function writePixel(~,~,~)
        functionNotSupported('writePixel');
    end
    
    function displayImage(~,~,varargin)
        functionNotSupported('displayImage');
    end
    
    function displayMessage(~,~,varargin)
        functionNotSupported('displayMessage');
    end
    
    function clearLEDMatrix(~)
        functionNotSupported('clearLEDMatrix');
    end
    
end
end

function [varargout] = functionNotSupported(fname)
coder.internal.prefer_const(fname);
coder.inline('always');
coder.internal.assert(false, ...
    'raspi:matlabtarget:CodeGenNotSupported',fname);
[varargout{1:nargout}] = deal([]);
end