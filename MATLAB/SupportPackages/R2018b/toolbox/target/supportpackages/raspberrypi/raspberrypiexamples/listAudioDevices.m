function ret = listAudioDevices(hw,type)
%LISTAUDIODEVICES Return a list of ALSA audio devices.
%
% ret = LISTAUDIODEVICES(r,'playback') returns a list of ALSA audio
% playback devices. The output is a structure array containing the name,
% the ALSA device number, Number of channels, rate and bit-depth.
% the ALSA device number.
%
% ret = LISTAUDIODEVICES(r,'capture') returns a list of ALSA audio capture
% devices. The output is a structure array containing the name, the ALSA
% device number, number of channels, rate and bit-depth 
%
% The device numbers returned in the output structure can be used in the
% ALSA Audio Capture and ALSA Audio Playback blocks. 

% Copyright 2015-2018 The MathWorks, Inc.
type = validatestring(type,{'capture','playback'});
ret = [];
try
    out = system(hw,'cat /proc/asound/cards');
catch
    return;
end

% pi@raspberrypi ~ $ cat /proc/asound/cards
%  0 [ALSA           ]: bcm2835 - bcm2835 ALSA
%                       bcm2835 ALSA
%  1 [Device         ]: USB-Audio - USB PnP Sound Device
%                       C-Media Electronics Inc. USB PnP Sound Device at usb-bcm2708_usb-1.3, full spee
cards = regexp(out,'\s*\d+\s*\[[\w\s]+\]:','split');
if numel(cards) > 1
    cards = cards(2:end);
    %cards = cards(2:end); % card{1} might be empty
    % pi@raspberrypi ~ $ cat /proc/asound/pcm
    % 00-00: bcm2835 ALSA : bcm2835 ALSA : playback 8
    % 00-01: bcm2835 ALSA : bcm2835 IEC958/HDMI : playback 1
    % 01-00: USB Audio : USB Audio : playback 1 : capture 1
    try
        out = system(hw, 'cat /proc/asound/pcm');
    catch
        ret = [];
        return;
    end
    pcm = regexp(out,'(?<Card>\d\d)-(?<Device>\d\d):(?<Description>[^\n]+)','names');
    % Copy test file if 'playback'
    if strcmp(type,'playback')
        fileName = fullfile(codertarget.raspi.internal.getSpPkgRootDir, 'raspberrypiexamples', 'listAudioDevices_test.wav');
        hw.putFile(fileName);
    end
    
    for k = 1:numel(pcm)
        if ~isempty(regexp(pcm(k).Description,type,'match'))
            cardNo = str2double(pcm(k).Card);
            devNo = str2double(pcm(k).Device);
            ret(end+1).Name = cards{cardNo+1}; %#ok<AGROW>
            ret(end).Device = sprintf('%d,%d',cardNo,devNo);
            if strcmp(type,'playback')
                testString = ['aplay -D hw:',num2str(cardNo),',',num2str(devNo),' --dump-hw-params listAudioDevices_test.wav &> /tmp/audioHWParams'];
            else
                testString = ['arecord -D hw:',num2str(cardNo),',',num2str(devNo),' --dump-hw-params &> /tmp/audioHWParams'];
            end
            
            try
                system(hw,testString);
            catch
                % Do nothing
            end
            % Parse the aplay/arecord log to get hw information.
            hwParams = system(hw,'cat /tmp/audioHWParams');
            
            %Populate the struct with new details
            [numChannels, Format, Rate] = getHWParams(hwParams);
            ret(end).Channels = numChannels;
            ret(end).BitDepth = Format;
            ret(end).SamplingRate = Rate;
        end
    end
end
end

function [numChannels, Format, Rate] =  getHWParams(hwParams)
    Format = {};
    tmp = strsplit(hwParams,'\n');
    
    index = find(contains(tmp,'CHANNELS:'));
    c = tmp(index(1));
    cSplit = strsplit(c{1},':');
    cNums = str2num(cSplit{2});
    cStr = num2str(cNums);
    numChannels = strsplit(cStr);
    
    index = find(contains(tmp,'FORMAT:'));
    rawFormat = tmp(index(1));
    rawFormatSplit = strsplit(rawFormat{1},' ');
    for i=1:length(rawFormatSplit)
        if contains(rawFormatSplit{i},'8')
            Format = [Format {'8-bit integer'}];
        elseif contains(rawFormatSplit{i},'16')
            Format = [Format {'16-bit integer'}];
        elseif contains(rawFormatSplit{i},'32')
            Format = [Format {'32-bit integer'}];
        end
    end
    
    index = find(contains(tmp,'RATE:'));
    R = tmp(index(1));
    RSplit = strsplit(R{1},':');
    RNums = str2num(RSplit{2});
    RStr = num2str(RNums);
    Rate = strsplit(RStr);
end
%[EOF]
