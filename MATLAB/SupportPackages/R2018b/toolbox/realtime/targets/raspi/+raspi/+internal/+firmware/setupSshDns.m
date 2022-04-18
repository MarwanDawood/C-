function setupSshDns(ssh, ~)
%setupSshDns

%  Copyright 2013-2017 The MathWorks, Inc.

% Get key
cmd = 'grep ''UseDNS no'' /etc/ssh/sshd_config';
try
    ssh.execute(cmd);
catch
    cmd = 'cp /etc/ssh/sshd_config /home/pi/sshd_config.new';
    ssh.execute(cmd);
    
    cmd = 'echo -e "\\n\\n# Turn off reverse DNS lookup\\nUseDNS no\\n" >> /home/pi/sshd_config.new';
    ssh.execute(cmd);
    
    cmd = 'sudo mv /home/pi/sshd_config.new /etc/ssh/sshd_config';
    ssh.execute(cmd);
    
end

end
%[EOF]