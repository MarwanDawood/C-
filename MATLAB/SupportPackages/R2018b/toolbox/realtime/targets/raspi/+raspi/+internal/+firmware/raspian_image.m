function raspian_image(firmwareFile, mwver)

disp('Create firmware information file..');

h = raspi.setup.RaspberryPiFirmwareUpdate;

% Get the size of the image file
fwinfo = struct(...
    'fwFile', '', ...
    'fwSize', 0, ...
    'fwFileMd5sum', '', ...
    'archiveFile', '', ...
    'archiveSize', 0, ...
    'archiveFileMd5sum', '');

disp('2.1 Get firmware file size');
tmp = dir(firmwareFile);
if isempty(tmp)
    error('raspi:internal:NoFirmwareImage', 'Cannot locate firmware image.');
end

fwinfo.fwSize = tmp.bytes;
disp('2.11 Compute firmware md5sum');
fwinfo.fwFileMd5sum = h.md5sum(firmwareFile);

[~, name, ext]     = fileparts(firmwareFile);
fwinfo.fwFile      = [name, ext];
fwinfo.archiveFile = [fwinfo.fwFile, '.7z'];

% Get compressed image file size
disp('2.2 Get compressed firmware size');
archiveFile = [firmwareFile, '.7z'];
tmp = dir(archiveFile);
if ~isempty(tmp)
    fwinfo.archiveFile = [fwinfo.fwFile, '.7z'];
    fwinfo.archiveSize = tmp.bytes;
    disp('2.21 Compute compressed firmware md5sum');
    fwinfo.archiveFileMd5sum = h.md5sum(archiveFile);
else
    fwinfo.archiveFile = '';
    fwinfo.archiveSize = 0;
    fwinfo.archiveFileMd5sum = '';
end
% Create XML file
disp('3.1 Create XML file');

xmlLoc = createXmlFile(...
    'firmware_info.xml', ...
    fwinfo, ...
    mwver);
disp(['Create xml file: ', xmlLoc]);
end


function xmlfile = createXmlFile(xmlFileName, fwInfo, mwver)
fid = fopen(xmlFileName, 'w');
if (fid < 0)
    error(message('raspi:utils:InternalError', 'xmlFileName'));
end
c = onCleanup(@()fclose(fid));

% Create XML file containing package information
fprintf(fid, '<?xml version="1.0"?>\n');
fprintf(fid, '<!--Copyright %s The MathWorks, Inc. -->\n', date);
fprintf(fid, '<!--Firmware Update Repository -->\n');
fprintf(fid, '<FirmwareUpdateRepository>\n');
fprintf(fid, '    <Firmware name="%s" archive="%s" archivesize="%d" archivemd5sum="%s" firmwaresize="%d" firmwaremd5sum="%s" mwver="%s" username="%s" password="%s"></Firmware>\n', ...
    fwInfo.fwFile, ...
    fwInfo.archiveFile, fwInfo.archiveSize, fwInfo.archiveFileMd5sum, ...
    fwInfo.fwSize, fwInfo.fwFileMd5sum, mwver, 'pi', 'raspberry');
fprintf(fid, '</FirmwareUpdateRepository>\n');

% Return the created package information file
xmlfile = fullfile(pwd, xmlFileName);
end
