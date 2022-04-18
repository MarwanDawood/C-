function validateSerialBlock(blk)
    % VALIDATESERIALBLOCK
    % This function validates Serial Read and Serial Write blocks.
    %
    % If the Port name for any two blocks is same then validate if 
    % Baurate, Parity, Stop Bits are same.

    % Copyright 2016 The MathWorks, Inc.
    
   global modelBlockStruct;
   
   % Register Port name first
   opts.familyName = 'Serial';
   opts.parameterName = {'Port'};
   opts.parameterValue = {get_param(blk, 'SCIModule')};
   opts.parameterCallback = {''};
   lf_registerBlockCallbackInfo(opts);
   
   % Get the final port identifier. Example: pick 'ttyAMA0' from
   % '/dev/ttyAMA0'.
   tmpCell = regexp(get_param(blk, 'SCIModule'), '\w*','match');
   portName = tmpCell{end};
   
   if ~isempty(modelBlockStruct) && isfield(modelBlockStruct.parameters,'Port')
           % Register Baudrate, Parity, StopBits under portName as Family name
           % Validate for parameters by prepending the names with portName
           opts1.familyName = portName;
           opts1.parameterName = {[portName 'Baudrate']; ...
                [portName 'Parity'];  ...
                [portName 'StopBits']};
           opts1.parameterValue = {get_param(blk, 'Baudrate');...
                get_param(blk, 'Parity');...
                get_param(blk, 'StopBits')};
           opts1.parameterCallback = {{'allSame'};{'allSame'};{'allSame'}};


       
       errorID = 'raspberrypi:utils:SerialConflict';
       opts1.errorID = {errorID; errorID; errorID};
       opts1.errorArgs = {{'Baudrate', opts.parameterValue{1}};...
              {'Parity', opts.parameterValue{1}};...
              {'Stop bits', opts.parameterValue{1}}};
       lf_registerBlockCallbackInfo(opts1);
    
   end
 
end