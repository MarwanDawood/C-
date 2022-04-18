function openPinMap(ActionData,SystemObj)
% OPENPINMAP open the Pin Map for selected Raspberry Pi board
        ActionData.UserData.h = [];
        board = SystemObj.BoardProperty;
        hBoard = realtime.internal.BoardInfo('Raspberry Pi');
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
                ActionData.UserData.h = fig;
            end
        end
end