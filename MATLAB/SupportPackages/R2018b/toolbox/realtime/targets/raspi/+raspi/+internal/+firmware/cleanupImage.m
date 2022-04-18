function cleanupImage(ssh,~)
%CLEANUPIMAGE Cleanup image

%  Copyright 2015 The MathWorks, Inc.

execute(ssh,'sudo rm -f /var/log/*.1 /var/log/*.gz');
execute(ssh,'sudo rm -f /boot/iflist.txt');
execute(ssh,'sudo truncate /home/pi/.bash_history --size 0');
execute(ssh,'sudo truncate /var/log/*.log --size 0');
execute(ssh,'sudo truncate /var/log/*log --size 0');
execute(ssh,'sudo truncate /var/log/messages --size 0');
execute(ssh,'sudo truncate /var/log/wtmp --size 0');
execute(ssh,'sudo apt-get clean');
end
%[EOF]