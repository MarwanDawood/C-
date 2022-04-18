function success = setupPigpio(ssh, ~)
%SETUPPIGPIO Download and install pigpio

%  Copyright 2015-2019 The MathWorks, Inc.

installDir = '/opt/PIGPIO';
try 
    % Check if Pigpio is installed. Query 'pigiod -v' returns the version 
    % number of the pigpio demon if the lib is installed. If not the query will result in an error
    execute(ssh,'pigpiod -v');
    success = true;
    return
catch
    try
        %Check if the folder already exists. If yes delete it.
        execute(ssh,['sudo stat ' installDir]);
        execute(ssh,['sudo rm -fr ' installDir]);
    catch
        %do nothing
    end
    try
        % Create Directory
        execute(ssh,['sudo mkdir -p ' installDir]);
        execute(ssh,['sudo chown pi ' installDir]);
        
        % Download, build and install
        execute(ssh,'sudo wget abyz.me.uk/rpi/pigpio/pigpio.zip');
        execute(ssh,'sudo unzip pigpio.zip -d /opt');
        execute(ssh,['cd ' installDir '; sudo make']);
        execute(ssh,['cd ' installDir '; sudo make install']);
        execute(ssh,'sudo rm -f pigpio.zip');
        
        % Change ownership back to root
        execute(ssh,['sudo chown root ' installDir]);
        success = true;
    catch
        success = false;
    end
end
end
%[EOF]

% LocalWords:  pigpio pigiod pigpiod sudo chown wget abyz uk rpi
