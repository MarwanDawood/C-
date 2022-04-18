classdef hardwareDisplay < handle
    %HARDWAREDISPLAY Display an input image on the computer screen.
    %DISPLAYIMAGE supports MxNx3 or a MxN image
    
    % Copyright 2018 The MathWorks, Inc.
    properties(SetAccess = private)
        hFig
        dims
        hIm
        windowTitle
    end
    
    methods
        
        function obj = hardwareDisplay(obj,varargin)    %#ok<INUSD>
            %empty constructor
        end
        
        function displayImage(obj,varargin)
            try
                p = inputParser;
                addRequired(p,'img');
                addParameter(p,'Title','Raspberry Pi Display');
                parse(p,varargin{:});
            catch
                error(message('raspi:utils:InvalidNVPropertyName',...
                    'displayImage','''Title'''));
            end
            img = p.Results.img;
            obj.windowTitle = p.Results.Title;
            imgDims = size(img(:,:,1)');
            obj.updateFigure(imgDims);
            obj.updateImage(img);
        end
    end
    
    methods(Access = protected)
        function updateFigure(obj, dims)
            %Update an existing window or create a new one if it is not a
            %valid handle
            if (~isempty(obj.hFig) && isgraphics(obj.hFig))
                obj.hFig.Name = obj.windowTitle;
                obj.hFig.NumberTitle = 'off';
                obj.hFig.MenuBar = 'none';
                obj.hFig.ToolBar = 'none';
                currPosition = obj.hFig.Position;
                newPosition = [currPosition(1) (currPosition(2) + obj.dims(2)-dims(2)) ...
                    dims(1) dims(2)];
                obj.hFig.Position = newPosition;
                obj.dims = dims;
            else
                % On MAC OS-X, not specifying a position for figure window causes
                % figure window to open outside screen. We set the top left corner to
                % [100, 120] and width and height to the dimensions of the R/Y port.
                scrsz = get(groot,'ScreenSize');
                obj.hFig = figure('Name',obj.windowTitle, ...
                    'NumberTitle','off',...
                    'MenuBar','none',...
                    'ToolBar','none',...
                    'Position',[100 scrsz(4)-(dims(2)+120) dims(1) dims(1)]);
                obj.dims = dims;
                % Position = [lef bottom width height]
            end
            %Do not error out if the figure window is closed. Re opening of
            %the window is handled in updateImage
            try
                ax = axes('Parent',obj.hFig,'Visible','off');
                obj.hIm = imshow(zeros([dims(2),dims(1)],'uint8'),'parent',ax,'border','tight');
            catch
            end
            
        end
        
        function updateImage(obj, img)
            %Create a new figure if the handle is non existent
            if ~(~isempty(obj.hFig) && isgraphics(obj.hFig))
                imgDims = size(img(:,:,1)');
                obj.updateFigure(imgDims);
            end
            %Handle Grey scale images
            if (size(img,3) == 3)
                reshapedImg = cat(3, img(:,:,1).',img(:,:,2)',img(:,:,3)');
            else
                reshapedImg = cat(3, img.',img',img');
            end
            %Convert row major to column major
            reshapedImg = flip(reshapedImg);
            reshapedImg = rot90(reshapedImg,3);
            %Display the image
            obj.hIm.CData = reshapedImg;
            drawnow;
            %Bring the figure window to the foreground
            figure(obj.hFig);
        end
    end
    
end