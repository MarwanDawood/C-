classdef frameBuffer < handle & matlab.mixin.CustomDisplay
    % FRAMEBUFFER Create a framebuffer object.
    %
    % myfb = framebuffer(Hw) creates a Framebuffer object.
    
    % Copyright 2016 The MathWorks, Inc.
    properties (Constant)
        Name = 'Raspberry Pi Sense HAT FrameBuffer';
    end
    
    %     properties
    %         Orientation = 0;
    %     end
    
    properties(Access = private)
        Hw
        Map = containers.Map();
        Initialized = false;
        FrameBufferAddress
        Font
    end
    
    properties (Constant,Access = private)
        REQUEST_FRAMEBUFFER_INIT         = 7501;
        REQUEST_FRAMEBUFFER_WRITEPIXEL   = 7502;
        REQUEST_FRAMEBUFFER_DISPLAYIMAGE = 7503;
        REQUEST_FRAMEBUFFER_DISPLAYMESSAGE = 7504;
        AvailableOrientation = [0,90,180,270];
        AvailablePxlColors = {'red', 'green', 'blue', 'white', 'yellow', 'magenta', 'cyan','black'};
        AvailableSingleLetterColors = {'r', 'g', 'b', 'w', 'y', 'm', 'c','k'};
    end
    
    methods
        function obj = frameBuffer(Hw)
            obj.Hw = Hw;
            %Check if the SenseHAT is already in use
            if isUsed(obj, obj.Name)
                error(message('raspi:utils:SenseHATInUse','frameBuffer'));
            end
            fbinit(obj);
            markUsed(obj,obj.Name);
            obj.Initialized = true;
        end
        
        function writePixel(obj,loc,val)
            % writePixel(obj, pixelLocation, pixelValue) sets the
            % value specified by pixelValue to the pixel present in the
            % location specified by pixelLocation
            
            %validate row and column
            validatePixelLocation(loc);
            %Accept both color name and [RGB] value as input.
            validatePixelValue(val,'pixel value');
            % get the pxlLocation [col row]
            pLoc = 8 * (loc(2) - 1) + (loc(1) - 1);
            %convert color to RGB565
            rgb565=convertRGB565(obj,val);
            
            sendRequest(obj.Hw, obj.REQUEST_FRAMEBUFFER_WRITEPIXEL,...
                uint16(2 * pLoc),... % Location is specified in num-uint8's
                uint16(rgb565),...
                obj.FrameBufferAddress);
            recvResponse(obj.Hw);
        end
        
        function displayImage(obj,img,varargin)
            % displayImage(obj, image) displays the image on the
            % LED matrix.
            % image should be of 8X8X3 dimension.
            narginchk(2,3);
            %validate the input image. Make sure that the image is of size
            %[8 8 3]
            validateattributes(img,{'numeric'},{'integer'},'','image');
            if ~isequal(size(img),[8 8 3])
                error(message('raspi:utils:InvalidImageSize'));
            end
            
            %validate the orientation
            if nargin > 2
                validateattributes(varargin{1},{'numeric'},{'integer','scalar','finite'},'','Orientation');
                if ~ismember(varargin{1},obj.AvailableOrientation)
                    error(message('raspi:utils:InvalidSensorSetting',...
                        '''Orientation''',' 0, 90, 180, 270'));
                end
                orientation = varargin{1};
            else
                orientation = 0;
            end
            
            
            
            % Convert to uint16 and apply Orientation value
            if orientation ~= 0
                switch(orientation)
                    case 90
                        img = rot90(uint16(img),3);
                    case 270
                        img = rot90(uint16(img),1);
                    otherwise
                        img = rot90(uint16(img),orientation/90);
                end
            end
            
            % Compute RGB565 representation
            img = uint16(img);
            r5 = bitshift(bitshift(img(:,:,1),-3),11);
            g6 = bitshift(bitshift(img(:,:,2),-2),5);
            b5 = bitshift(img(:,:,3),-3);
            rgb565 = reshape(r5 + g6 + b5, [1,64]);
            
            % Send to hardware
            sendRequest(obj.Hw,obj.REQUEST_FRAMEBUFFER_DISPLAYIMAGE,...
                uint8(1),uint16(rgb565),obj.FrameBufferAddress);
            recvResponse(obj.Hw);
        end
        
        function displayMessage(obj,msg,varargin)
             % displayMessage(obj, message) displays a scrolling
            % message on the LED matrix.
            %
            % displayMessage(obj,'P1',v1,'P2',v2,...) displays a
            % scrolling message on the LED matrix applying the
            % specified parameter value pair.
            % Supported parameters are: 
            % * ScrollingSpeed - Speed in seconds at which the message will
            % scroll. Default: 0.1 s.  
            % * TextColor - Color of the text to be displayed. textColor
            % can be specified as a 1-by-3 rgb color or as a color string
            % such as 'white' or 'w'. Default: 'red' or [255 0 0}
            % * BackgroundColor - background color whenthe text is displayed. bgColor
            % can be specified as a 1-by-3 rgb color or as a color string
            % such as 'white' or 'w'. Default: [0 0 0].
            
            %Check that the number of inputs is between 2 and 8.
            narginchk(2,10);
            
            %Ensure that the input is 'char' or 'numeric'
            validateattributes(msg,{'char','numeric'}, {'nonempty'}, '', 'msg');
            %if msg is numeric, validate that it is a scalar and non nan
            if ~ischar(msg)
                validateattributes(msg, {'numeric'},{'scalar', 'nonnan'}, '', 'msg');
            end
            
            % check for the class of the input. If the input is non-char
            % and numeric, applay 'mat2str' and convert it to a char.
            if ~ischar(msg)
                msg = mat2str(msg);
            end
            
            %set default scrollingSpeed, pxlvalue and bgvalue
            scrollingSpeed = 0.1;
            textColor = [255,0,0];
            bgColor = [0,0,0];
            orientation = 0;
            %If additional parameters are provided, assign the values to
            %the properties depending on the name value pair.
            if nargin > 2
                if (mod(nargin,2)~=0)
                    error(message('raspi:utils:InvalidNumberOfInputs'));
                end
                numNameValuepair = (nargin-2)/ 2;
                for ii = 1:numNameValuepair
                    switch lower(varargin{1+(ii-1)*2})
                        case 'scrollingspeed'
                            validateattributes(scrollingSpeed, {'numeric'}, ...
                                {'scalar', 'nonnan'}, '', 'scrollingSpeed');
                            scrollingSpeed = varargin{1+(ii-1)*2+1};
                        case 'textcolor'
                            validatePixelValue(varargin{1+(ii-1)*2+1},'text color');
                            textColor = varargin{1+(ii-1)*2+1};
                        case 'backgroundcolor'
                            validatePixelValue(varargin{1+(ii-1)*2+1},'background color');
                            bgColor = varargin{1+(ii-1)*2+1};
                        case 'orientation'
                            validateattributes(varargin{1+(ii-1)*2+1},{'numeric'},{'integer','scalar','finite'},'','Orientation');
                            if ~ismember(varargin{1+(ii-1)*2+1},obj.AvailableOrientation)
                                error(message('raspi:utils:InvalidSensorSetting',...
                                    '''Orientation''',' 0, 90, 180, 270'));
                            end
                            orientation = varargin{1+(ii-1)*2+1};
                        otherwise
                            error(message('raspi:utils:InvalidParamOption'));
                    end
                end
            end
            
            %Convert textColor and bgColor to RGB565
            pxlValue = convertRGB565(obj,textColor);            
            bgValue = convertRGB565(obj,bgColor);
            
            %Frame the text.
            charlist = ' +-*/!"#$><0123456789.=)(ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz?,;:|@%[&_'']\~';
            imagefile = imread(fullfile(raspi.internal.getRaspiRoot,'resources','sense_hat_text.png'));
            strarray = uint16(zeros(1,40));
            for l = 1:length(msg)
                charindex = strfind(charlist,msg(l))-1;
                % If the charcter in the msg cannot be found in the
                % dictionary, replace the character with a '?'.
                if isempty(charindex)
                    charindex=strfind(charlist,'?')-1;
                    warning(message('raspi:utils:InvalidCharacter',['''' msg(l) '''']));
                end
                if (orientation == 0)||(orientation == 180)
                    charmatrix = rot90(imagefile(1+(charindex*5):5+(charindex*5),:,1));
                else
                    charmatrix = imagefile(1+(charindex*5):5+(charindex*5),:,1)';
                end
                chararray = reshape(charmatrix,[1 40])/255;
                %Trim trailing whitespace
                if (sum(chararray(33:40)) == 0)
                    chararray = chararray(1:32);
                end
                %trim leading whitespace
                if (sum(chararray(1:8))==0)
                    chararray = chararray(9:length(chararray));
                end
                strarray=uint16([strarray chararray zeros(1,8)]);
            end
            strarray = [strarray uint16(zeros(1,64))];
            if(pxlValue ==0)
                strarray =uint16(not(strarray));
                strarray = strarray * bgValue ;
            else
                strarray = strarray*pxlValue;
                strarray(strarray==0) = bgValue;
            end
            
            % Estimated maximum timeout:
            % 1. each char is maxium 6 pixels wide(including one space behind) 
            % 2. each pixel needs to scroll across the entire matrix, e.g 8 columns
            % 3. add an extra 5s to account for Online over the Internet communication
            timeout = (8+6*length(msg))*scrollingSpeed+5;
            data = typecast(uint16(length(strarray)),'uint8');
            data = [data, typecast(uint16(orientation),'uint8')];
            data = [data, typecast(uint16(scrollingSpeed*1000),'uint8')];
            data = [data, typecast(strarray,'uint8')];
            data = [data, uint8(obj.FrameBufferAddress)];
            sendCommand(obj.Hw,obj.REQUEST_FRAMEBUFFER_DISPLAYMESSAGE,data,timeout);
        end
        
        function clearLEDMatrix(obj)
            % clearLEDMatrix(obj) clear the LED matrix and turnoff
            % all the pixels of the LED matrix.
            imgArray = uint16(zeros(1,64));
            sendRequest(obj.Hw,...
                obj.REQUEST_FRAMEBUFFER_DISPLAYIMAGE,...
                uint8(0),...
                fliplr(imgArray),...
                obj.FrameBufferAddress);
            recvResponse(obj.Hw);
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            % Display main options
            fprintf('                   Name: %-15s\n', 'Raspberry Pi Sense HAT FrameBuffer');
        end
    end
    
    methods(Access = private)
        function fbinit(obj)
            sendRequest(obj.Hw, obj.REQUEST_FRAMEBUFFER_INIT);
            FramebufferName = char(recvResponse(obj.Hw));
            FramebufferName = strrep(FramebufferName,'/sys/class/graphics/','/dev/');
            FramebufferName = strrep(FramebufferName,'/name',char(0));
            obj.FrameBufferAddress = FramebufferName;
        end
        
        function delete(obj)
            try
                if obj.Initialized
                    obj.markUnused(obj.Name)
                end
            catch
                % do not throw errors/warnings at destruction
            end
        end
        
        function ret = isUsed(obj, name)
            if isKey(obj.Map, obj.Hw.DeviceAddress) && ...
                    ismember(name, obj.Map(obj.Hw.DeviceAddress))
                ret = true;
            else
                ret = false;
            end
        end
        
        function markUsed(obj, name)
            if isKey(obj.Map, obj.Hw.DeviceAddress)
                used = obj.Map(obj.Hw.DeviceAddress);
                obj.Map(obj.Hw.DeviceAddress) = union(used, name);
            else
                obj.Map(obj.Hw.DeviceAddress) = {name};
            end
        end
        
        function markUnused(obj, name)
            if isKey(obj.Map, obj.Hw.DeviceAddress)
                used = obj.Map(obj.Hw.DeviceAddress);
                obj.Map(obj.Hw.DeviceAddress) = setdiff(used, name);
            end
        end
    end
    
    methods (Hidden = true)
        function rgb565 = convertRGB565(obj,val)
            if ischar(val)
                if length(val) == 1
                    colorName=validatestring(val,obj.AvailableSingleLetterColors);
                else
                colorName=validatestring(val,obj.AvailablePxlColors);
                end
                switch lower(colorName)
                    case {'red','r'}
                        val = [255 0 0];
                    case {'green','g'}
                        val = [0 255 0];
                    case {'blue','b'}
                        val = [0 0 255];
                    case {'white','w'}
                        val = [255 255 255];
                    case {'yellow','y'}
                        val = [255 255 0];
                    case {'magenta','m'}
                        val = [255 0 255];
                    case {'cyan','c'}
                        val = [0 255 255];
                    case {'black','k'}
                        val = [0 0 0];
                end
            end
            
            % Convert [R,G,B] triplet to RGB565
            val = uint16(val);
            r5 = bitshift(bitshift(val(1),-3),11);
            g6 = bitshift(bitshift(val(2),-2),5);
            b5 = bitshift(val(3),-3);
            rgb565 = r5 + g6 + b5;
        end
    end
end

%% Internal functions
function validatePixelLocation(loc)
validateattributes(loc,{'numeric'},{'integer','nrows',1,'ncols',2},'','pixelLocation');
if any(loc > 8 | loc < 1)
    error('raspi:utils:InvalidPixelValue',...
        'X and Y components of the pixel location must be between 1 and 8.');
end
end

function validatePixelValue(val,str)
%val can be char or numeric.
validateattributes(val,{'char','numeric'}, {'nonempty'}, '', 'msg');
if ~ischar(val)
    validateattributes(val,{'numeric'},{'integer','nrows',1,'ncols',3},'',str);
    if any(val > 255 | val < 0)
        error('raspi:utils:InvalidPixelValue',...
            ['R, G and B components of the ' str ' must be between 0 and 255.']);
    end
end
end



