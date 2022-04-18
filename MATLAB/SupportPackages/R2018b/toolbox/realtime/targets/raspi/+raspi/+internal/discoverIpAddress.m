function raspiList = discoverIpAddress(deviceAddress,port)
%DISCOVERIPADDRESS Discover IP address of a Raspberry Pi.
% 
%  raspiList = discoverIpAddress() returns the IP addresses and hostname of
%  Raspberry Pi boards that are in the same subnet as the host computer.

%   Copyright 2014-2015 The MathWorks, Inc.
if nargin < 1
   deviceAddress = '';
end
if nargin < 2
    port = raspi.internal.getUdpIpPort('discover');
end

% Create a UDP object
udpObj = codertarget.asyncioplugins.udp.ByteServer(0);
udpObj.NonBlocking = true;
open(udpObj);
c = onCleanup(@()close(udpObj));

% Construct a broadcast message data
if isempty(deviceAddress)
    data.Endpoint = ['255.255.255.255:' num2str(port)];
else
    data.Endpoint = [deviceAddress ':' num2str(port)];
end
data.Data = uint8('who is raspi?');

% Send broadcast message
udpObj.write(data);
pause(1);

% Enumerate return messages
raspiList = struct('Hostname','','IpAddress','');
raspiList(end) = [];
data = udpObj.read(1);
while ~isempty(data)
    % Parse IP address from the response
    raspiHost = char(data.Data);
    tmp = regexp(data.Endpoint,':','split');
    if numel(tmp) == 2
        ip = tmp{1};
        
    end
    raspiList(end+1) = struct(...
            'Hostname', raspiHost, ...
            'IpAddress', ip); %#ok<AGROW>
    data = udpObj.read(1);
end
end

