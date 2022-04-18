function setupLinuxPackages(ssh, ~)
%setupLinuxPackages

% Update
disp('1. Update package repository...');
msg = ssh.execute('sudo apt-get -y update');
disp(msg);

% Upgrade
disp('2. Upgrade to latest...');
msg = ssh.execute('sudo apt-get -y upgrade');
disp(msg);

% Install required packages
disp('3. Install required packages...');
packages = 'libsdl1.2-dev alsa-utils espeak i2c-tools libi2c-dev ssmtp ntpdate git-core v4l-utils cmake sense-hat';
msg = ssh.execute(['sudo apt-get -y install ' packages]);
disp(msg);

% Clean-up
disp('4. Remove un-needed packages...');
msg = ssh.execute('sudo apt-get -y autoremove');
disp(msg);

%  Install rpi-serial-console package
disp('5. Install serial console package...');
cmd = 'sudo wget https://raw.github.com/lurch/rpi-serial-console/master/rpi-serial-console -O /usr/bin/rpi-serial-console';
msg = ssh.execute(cmd);
disp(msg);

msg = ssh.execute('sudo chmod +x /usr/bin/rpi-serial-console');
disp(msg);

end
%[EOF]