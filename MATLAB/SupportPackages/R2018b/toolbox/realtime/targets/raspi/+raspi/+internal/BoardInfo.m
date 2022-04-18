classdef (Sealed = true) BoardInfo < raspi.internal.Info
%BOARDINFO The class that handles the board info

% Copyright 2013 The MathWorks, Inc.
    
    
    %% Properties
    properties (SetAccess = 'private')
        Board
    end
    
    properties(Constant)
    end
    
    %% Public Methods
    methods
        function obj = BoardInfo(boardName)
            boardName = regexprep(boardName, '\s', '');
            boardName = regexprep(boardName, '+', 'Plus');
            fileName = ['raspi.internal.boardInfo' strrep(boardName, ' ', '')];
            obj.deserialize(fileName);
        end
        
        function set(obj, property, value)
            obj.(property) = value;
        end 
        
        function ret = getGPIOImgFile(obj)
            ret = obj.Board.GPIOImgFile;
        end
        
        function ledList = getLEDList(obj)
            % Return a list of LED names to be displayed on the LED block
            % mask
            LED = obj.Board.LED;
            ledList = cell(1, length(LED));
            for i = 1:length(LED)
                ledList{i} = [LED(i).Name ' (' LED(i).Color, ')'];
            end
        end
        
        function deviceFile = getLEDDeviceFile(obj, led)
            % Return the device file name of an LED
            LED = obj.Board.LED;
            deviceFile = '';
            for i = 1:length(LED)
                if ~isempty(strfind(led, LED(i).Name))
                    deviceFile = LED(i).DeviceFile;
                    break;
                end
            end
        end
        
        function ret = getLEDImgFile(obj)
            ret = obj.Board.LEDImgFile;
        end
    end
end
