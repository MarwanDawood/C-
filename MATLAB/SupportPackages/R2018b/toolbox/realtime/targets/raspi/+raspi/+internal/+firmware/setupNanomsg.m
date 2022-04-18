function success = setupNanomsg(ssh, ~)
%SETUPPIGPIO Download and install pigpio

%  Copyright 2015-2017 The MathWorks, Inc.

buildDir = '/tmp/nanomsg-1.0.0/build';
try
    % Check if Pigpio is installed. Query 'pigiod -v' returns the version
    % number of the pigpio demon if the lib is installed. If not the query will result in an error
    execute(ssh,' sudo stat /usr/local/lib/libnanomsg.so.5.0.0 ');
    success = true;
    return
catch
    try
        % Download, build and install
        execute(ssh,'wget https://github.com/nanomsg/nanomsg/archive/1.0.0.zip');
        execute(ssh,'sudo unzip 1.0.0.zip -d /tmp');
        execute(ssh,['sudo mkdir -p ' buildDir]);
        execute(ssh,['sudo chown pi ' buildDir]);
        execute(ssh,['cd ' buildDir ';  cmake ..  ' ] );
        execute(ssh,['cd ' buildDir ' ; cmake --build . '] );
        %execute(ssh,['cd ' buildDir '; ctest -G Debug . '] );
        execute(ssh,['cd ' buildDir '; sudo cmake --build . --target install '] );
        execute(ssh,['cd ' buildDir ' ; sudo ldconfig '] );
        execute(ssh,'sudo rm -f 1.0.0.zip');
        execute(ssh,'sudo rm -r -f /tmp/nanomsg-1.0.0 ');
        success = true;
    catch
        success = false;
    end
end
end
%[EOF]