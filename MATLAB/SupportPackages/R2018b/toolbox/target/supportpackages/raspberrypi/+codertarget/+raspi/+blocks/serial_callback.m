function serial_callback(varargin)

% SERIALWRITE_CALLBACK Mask Helper Function for Serial Write block

% Copyright 2016 The MathWorks, Inc.

blk = gcbh;

% Check on input "action"
action = varargin{1};
switch action
    
    case 'MaskInitialization'
        updatePortLabels(blk);    
        set_param(blk,'SCIModule',get_param(blk,'SCIModule_'))
        %set_param(blk,'Baudrate',['uint32(' get_param(blk,'Baudrate_') ')']);
        set_param(blk,'Baudrate',get_param(blk,'Baudrate_'));
        set_param(blk,'StopBits',get_param(blk,'StopBits_'));
          
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
        error('tfBlockBuilder:UnknownCallback',...
            'Unknown callback action "%s"', action)
end

end

%--------------------------------------------------------------------------
function updatePortLabels(blk)

    platform = upper(get_param(blk, 'blockPlatform'));
    sciname = get_param(blk,'SCIModule_');
    t = sprintf('text(0.5, 0.15, ''Port: %s'', ''horizontalAlignment'', ''center'');', sciname);
    maskDisplayStr = [ ...
                    ['color(''blue'');', char(10)] ...                                     % Drawing mask layout of the block
                    ['text(0.35, 0.9, ''' platform ''', ''horizontalAlignment'', ''left'');', char(10)] ...
                    ['color(''black'');', char(10)] ...
                    ['image(imread(''serial.png''),[0.28 0.18 0.45 0.65]);', char(10)], ...
                     t];
    if (strcmp(Simulink.Mask.get(blk).Type, 'Serial Read'))
         maskDisplayStr = [ maskDisplayStr,  char(10), 'port_label(''output'', 1, ''Data'');', char(10), 'port_label(''output'', 2, ''Status'');'];     
    end
    set_param(blk, 'MaskDisplay', maskDisplayStr);
end

%[EOF]