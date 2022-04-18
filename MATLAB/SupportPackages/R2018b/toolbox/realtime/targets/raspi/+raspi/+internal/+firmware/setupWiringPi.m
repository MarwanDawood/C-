function success = setupWiringPi(ssh, ~)
%setupWiringPi validate and install WiringPi library on Raspberry pi
%  Copyright 2015-2017 The MathWorks, Inc.


% Clean
installDir = '/opt/wiringPi';

% Check if wiringpi is already installed

cmd = 'gpio -v';
try
    execute(ssh, cmd);
    success = true;
catch
    %If the return is non-empty then wiring pi is installed.
    %If the return is empty, install wiringpi
    try
        execute(ssh,['sudo stat ' installDir]);
        execute(ssh,['sudo rm -fr ' installDir]);
    catch
        %do nothing
    end
    try
        execute(ssh,['sudo mkdir -p ' installDir]);
        execute(ssh,['sudo chown pi ' installDir]);
        
        % Update
        ssh.execute(['git clone git://git.drogon.net/wiringPi ' installDir]);
        ssh.execute(['cd ' installDir '; git pull origin']);
        ssh.execute(['cd ' installDir '; ./build']);
        % Change ownership back to root
        execute(ssh,['sudo chown root ' installDir]);
        success = true;
    catch
        success = false;
    end
end

%[EOF]