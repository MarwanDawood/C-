function forwardRealtimeDataToCoderTarget(hCS,realtimeTargetData)
%FORWARDREALTIMEDATATOCODERTARGET Copy Realtime Raspberry Pi Target
% parameter values to Codertarget parameters

% Copyright 2015 The MathWorks, Inc.

% Raspberry Pi Parameters
%     Enable_overrun_detection
%     port
%     verbose

%% Overrun detection parameter
if isfield(realtimeTargetData,'Enable_overrun_detection')
    detectOverrun = realtimeTargetData.Enable_overrun_detection;
    codertarget.data.setParameterValue(hCS,'DetectTaskOverruns',logical(detectOverrun));
end

%% External Mode Parameters
%data.ConnectionInfo.TCPIP
%   IPAddress: 'codertarget.raspi.getDeviceAddress'
%        Port: '17725'
%     Verbose: 0
if isfield(realtimeTargetData,'port')
    port = str2double(realtimeTargetData.port);
    if ~isnan(port) && (port >= 1024 || port < 65535)
        data = codertarget.data.getData(hCS);
        if isfield(data,'ConnectionInfo') && isfield(data.ConnectionInfo,'TCPIP')
            tcpParams = data.ConnectionInfo.TCPIP;
            if isfield(tcpParams,'Port')
                tcpParams.Port = realtimeTargetData.port;
                codertarget.data.setParameterValue(hCS,'ConnectionInfo.TCPIP',tcpParams);
            end
        end
    end
end
end