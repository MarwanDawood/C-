function closePinMap( ActionData,~)
    %CLOSEPINMAP close the Pin Map for selected Raspberry Pi board
    pinMap_h = [];
    if isfield(ActionData.UserData, 'h')
        pinMap_h = ActionData.UserData.h;   
    end
    if ~isempty(pinMap_h) && isvalid(pinMap_h)
         close(pinMap_h);
          ActionData.UserData.h = [];
    end     
end

