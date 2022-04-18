function registerAudioFile(blk)
%REGISTERAUDIOFILE This function register the audio file name to the
%resources so that the file can be included in the zip
%   Detailed explanation goes here

    % Copyright 2017 The MathWorks, Inc.
    %TO DO
    %isInvalidRegisterUseCase
    mdlName = codertarget.utils.getModelForBlock(blk);
    if ~codertarget.target.isCoderTarget(mdlName) || ...
            codertarget.resourcemanager.isblockregistered(blk)
        return
    else
        codertarget.resourcemanager.registerblock(blk);
        
        % Register file name used by the block
        if codertarget.resourcemanager.isregistered(blk, 'raspiAudioFileRead', 'fName')
            fNameList = codertarget.resourcemanager.get(blk, 'raspiAudioFileRead', 'fName');
        else
            fNameList = {};
        end
        
        fName = get_param(blk, 'FileName');
        if strcmp(fName, 'guitartune.wav')
            fName = fullfile(codertarget.raspi.internal.getSpPkgRootDir, 'blocks', 'guitartune.wav');
        end
        [isFound, ~] = ismember(fName,fNameList);
        
        if ~isFound
            fNameList{end+1} = fName;
            codertarget.resourcemanager.set(blk, 'raspiAudioFileRead', 'fName', fNameList);
            codertarget.resourcemanager.increment(blk, 'raspiAudioFileRead', 'numAudioReadBlocks');
        end
    end

end

