function servo(varargin)
%SERVO Block mask helper function for Servo block.
%

% Copyright 2015 The MathWorks, Inc.

blk = gcbh;

%% Parameter map
%1 = board
%2 = Pin_
%3 = MinPulseDuration
%4 = MaxPulseDuration
%5 = blockPlatform

% Execute "action" callback
action = varargin{1};
switch action
    case 'MaskInitialization' 
        updatePortLabels(blk);    
        set_param(blk,'Pin',get_param(blk,'Pin_'));
    case 'OnBoardChange'
        board = get_param(blk,'board');
        blockPlatform = get_param(blk,'blockPlatform');
        maskObj = get_param(blk,'MaskObject');
        currOptions = maskObj.Parameters(2).TypeOptions;
        hBoard = realtime.internal.BoardInfo(blockPlatform);
        newOptions = transpose(hBoard.getGpioList(board,'Output'));
        % Reset current value of the pin to the first element in the list
        if ~isequal(currOptions,newOptions)  
            maskObj.Parameters(2).TypeOptions = newOptions;
            set_param(blk,'Pin_',maskObj.Parameters(2).TypeOptions{1});
        end
    case 'ViewPinMap'
        board = get_param(blk,'board');
        blockPlatform = get_param(blk,'blockPlatform');
        hBoard = realtime.internal.BoardInfo(blockPlatform);
        imgFile = hBoard.getGPIOImgFile(board);
        imgTitle = [board ' GPIO Pin Map'];
        % Look for the figure window and bring forward.
        imgHandle = findobj('type','figure','Name',imgTitle,'Tag','raspiOpenPinMap');
        if (numel(imgHandle) == 1) && ishandle(imgHandle)
            %Figure windiw already opened. Bring it to front.
            figure(imgHandle);
        else
            %Cannot find any opened figure. Create new
            if ~isempty(imgFile) && exist(imgFile,'file') == 2
                fig = figure( ...
                    'Name', imgTitle, ...
                    'NumberTitle', 'off',...
                    'MenuBar','none','Tag','raspiOpenPinMap');
                hax = axes( ...
                    'Parent',fig, ...
                    'Visible','off');
                imshow(imgFile,'parent',hax,'border','tight');
            end
        end
    otherwise
        error('raspi:internal:UnknownCallback',...
            'Unknown callback action "%s"',action)
end
end

%--------------------------------------------------------------------------
function updatePortLabels(blk)
% Update port labels
eol = char(10);
platform = realtime.internal.getBlockDisplayText(gcb);
pin = get_param(blk,'Pin_');
maskDisplayStr = ['text(0.5, 0.15, ''GPIO ' pin ''', ''horizontalAlignment'', ''center'');', eol];
maskDisplayStr = [maskDisplayStr, 'image(imread(''servowrite.png''),[0.32 0.25 0.35 0.55]);', eol];
maskDisplayStr = [maskDisplayStr, 'color(''blue'');', eol, ...
    'text(0.90, 0.90, ''' platform ''', ''horizontalAlignment'', ''right'');', eol ...
    'color(''black'');', eol, ...
    ];
set_param(blk,'MaskDisplay',maskDisplayStr);
end

%[EOF] LINUXGPIOREAD.M
