function raspiList = findRaspi(hostname,port)
%FINDRASPI Discover IP address of a Raspberry Pi.
%
%  raspiList = findraspi(hostname) returns the IP address of a
%  Raspberry Pi with a given hostname. 
% 
%  raspiList = findraspi() returns the IP addresses of all
%  Raspberry Pi hardware found on the LAN.

%   Copyright 2014-2015 The MathWorks, Inc.
if nargin < 1
   hostname = '';
end
if nargin < 2
    port = raspi.internal.getUdpIpPort('find');
end

% Create a UDP object
udpObj = codertarget.asyncioplugins.udp.ByteServer(port);
udpObj.NonBlocking = true;
open(udpObj);
c = onCleanup(@()close(udpObj));

% Enumerate return messages
raspiList = struct('Hostname', '', 'IpAddress', '');
raspiList(end) = [];
tstart = tic;
while (toc(tstart) < 3) 
    % Parse IP address from the response
    data = udpObj.read(1);
    if ~isempty(data)
        raspiHost = char(data.Data);
        % Skip hostname check for Pi Zero W
        if strcmp(hostname,message('raspi:hwsetup:RaspberryPiZeroW').getString)
            tmp = regexp(data.Endpoint,':','split');
            if numel(tmp) == 2
                ip = tmp{1};
                if strcmp(ip,'192.168.9.2')
                    % Pi Zero detected
                    raspiList(end+1) = struct(...
                        'Hostname', raspiHost, ...
                        'IpAddress', ip); %#ok<AGROW>
                    break;
                else
                    % Check other UDP packets
                    continue;
                end
            end
        end
        
        if ~isempty(hostname) && ~isequal(hostname, raspiHost)
            continue;
        end
        tmp = regexp(data.Endpoint,':','split');
        if numel(tmp) == 2
            ip = tmp{1};
            raspiList(end+1) = struct(...
                'Hostname', raspiHost, ...
                'IpAddress', ip); %#ok<AGROW>
        end
    end
end
end


