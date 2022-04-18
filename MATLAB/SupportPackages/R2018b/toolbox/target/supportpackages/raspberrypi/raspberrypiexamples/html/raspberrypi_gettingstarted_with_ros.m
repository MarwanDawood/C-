%% Getting Started with Robot Operating System (ROS) on Raspberry Pi(R)
%
% This example shows you how to generate and build a standalone ROS node
% from a Simulink model on the Raspberry Pi hardware.
%

% Copyright 2015-2017 The MathWorks, Inc.


%% Introduction
%
% In this example, you will configure a model to generate C++ code for a
% standalone ROS node that runs on the Raspberry Pi board. You will use
% Raspberry Pi Simulink blocks together with a ROS Subscribe block to blink
% the Raspberry Pi user LED. If you are new to ROS, we strongly recommend
% reviewing <matlab:doc('robotics') Robotics System Toolbox documentation>.
%
% ROS is a communication layer that allows different components of a robot
% system to exchange information in the form of _messages_. A component
% sends a message by _publishing_ it to a particular _topic_, such as
% "/odometry". Other components receive the message by _subscribing_ to
% that topic. The Robotics system toolbox provides an interface between
% MATLAB and Simulink and the Robot Operating System (ROS) that enables you
% to test and verify applications on ROS-enabled hardware such as Raspberry
% Pi. It supports C++ code generation, enabling you to generate a ROS node
% from a Simulink model and deploy it to a ROS network.
% 
% In this example, you will learn how to:
%
% * Set up the ROS environment on the Raspberry Pi board
% * Create and run a Simulink model on the Raspberry Pi board to send and
% receive ROS messages
% * Work with data in ROS messages


%% Prerequisites
%
% * This example requires Robotics Toolbox(TM).
%
% * Review the <https://www.mathworks.com/help/robotics/examples/get-started-with-ros.html Get Started with ROS>
% example
% 
% * Review the <https://www.mathworks.com/help/robotics/examples/get-started-with-ros-in-simulink.html Get Started with ROS in Simulink(R)>
% example.
%


%% Required Hardware
%
% To run this example you need the following hardware:
% 
% * Raspberry Pi board
%
% We strongly recommend a Raspberry Pi 2 board when working with ROS.

open_system('rosberrypi_getting_started');


%% Task 1 - Get Started 
%
% The Raspbian Linux image provided by the Simulink Support Package for
% Raspberry Pi hardware includes a ROS Indigo installation. In this task,
% you will start a ROS master on the host computer and send messages to
% Raspberry Pi hardware using ROS communication interface.
%
% *1.* First, start a ROS master on the host computer:
%
%  rosinit('NodeHost',<IP address of your computer>)
%
% For example, if the IP address of your host computer is 10.10.10.2, use
% the following command:
%
%  rosinit('NodeHost','10.10.10.2')
%
% *2.* Use |rosnode list| to see all nodes in the ROS network. Note that
% the only available node is the global MATLAB node created by |rosinit|.
%
%  rosnode list
%
% Next, list the available ROS topics:
%  
%  rostopic list
%
% The output should just list |/rosout| topic used for console log
% messages.
%
% *3.* Create an interactive Linux shell terminal to communicate with your
% Raspberry Pi board:
% 
%  r = raspberrypi 
%  openShell(r)
% 
% The commands above will log you in with your username and password. Note
% that in the rest of this example, we assume that you logged in with the
% default username for the Raspbian Linux, *pi*.
%
% *4.* On the interactive Linux command shell, initialize ROS environment
% and set the ROS master to the IP address of the host computer and monitor
% messages coming from the host computer using:
%
%  pi@raspberrypi:~ $ source ~/catkin_ws/devel/setup.bash 
%  pi@raspberrypi:~ $ export ROS_MASTER_URI=http://<Enter your host computer's IP address>:11311
%  pi@raspberrypi:~ $ rostopic echo /rosout
%
% The last command does not return and waits for a new message published to
% the |/rosout| topic. On the MATLAB command line, execute the following
% commands to see that your Raspberry Pi has subscribed to the |/rosout|
% topic:
%
%  rostopic info /rosout
%
% The IP address of your Raspberry Pi board should show up in the
% subscriber list.
% 
% *5.* To publish a log message to the |/rosout| topic from the host computer,
% execute the following commands on the MATLAB prompt:
%  
%  b = rospublisher('/rosout'); 
%  msg = rosmessage(b); 
%  msg.Msg = 'Hello Raspberry Pi!' 
%  send(b,msg);
% 
% When the |send(b,msg)| is executed, you should see that the contents of
% the message you sent from your host computer is printed on the Raspberry
% Pi Linux shell.
%
% *6.* Execute a *Ctrl+C* On the Raspberry Pi Linux command shell to stop
% listening messages published to |/rosout| topic.


%% Task 2 - Configure a Model to Generate a ROS Node 
% 
% In this task, you will configure a model to generate C++ code for a
% standalone ROS node that runs on your Raspberry Pi board.
%  
% *1.* Open the <matlab:rosberrypi_getting_started Raspberry Pi Getting
% Started with ROS> model.
%
% *2.* Click on _Simulation > Model Configuration Parameters_ and follow the
% steps illustrated in the diagram below to configure the model to generate
% a ROS node for Raspberry Pi:
%
% <<rosberrypi_workflow.png>>
% 
% Review the settings in the *Hardware Implementation* pane of the
% Configuration Parameters dialog, The *Hardware board settings* section
% contains settings specific to the generated ROS package, such as
% information to be included in the |package.xml| file, ROS Catkin
% workspace being used for model build, etc. In
%
% *3.* The model is configured to generate a ROS node in the ROS Catkin
% workspace, |~/catkin_ws|, and automatically deploy to the Raspberry Pi
% board. Click on *Build Model* button to start deployment process.
%
% <<rosberrypi_build_model.png>>
%
% Click on the *View Diagnostics* link at the bottom of the model toolbar
% to see the output of the build process.


%% Task 3 - Run and Verify the ROS Node
%
% In this task, you will run the newly-built ROS node and verify its
% behavior using a MATLAB command line interface for ROS.
%
% *1.* <matlab:rosberrypi_getting_started Raspberry Pi Getting Started with
% ROS> model receives messages published on the |/led| topic and sets the
% state of the Raspberry Pi user LED based on the contents of this message.
% First, verify that a new topic called |/led| has been generated:
%  
%  rostopic info /led
%
% You should see the IP address of your Raspberry Pi in the subscribers
% list.
%
% *2.* Create a ROS publisher for the |/led| topic:
%
%  b = rospublisher('/led')
%
% The publisher |b| uses |std_msgs/Bool| message type to represent the on /
% off state of the LED.
%
% *3.* Send messages to Raspberry Pi board to blink the user LED for 10
% seconds with a period of 0.5 second:
%
%  msg = rosmessage(b); 
%  for k = 1:10
%      msg.Data = 1; 
%      send(b,msg); 
%      pause(0.5); 
%      msg.Data = 0; 
%      send(b,msg);
%      pause(0.5);
%  end
%
% *4.* Once you are done verifying the ROS node, stop it by executing the
% following on the MATLAB prompt:
%
%  stopROSNode(r,'rosberrypi_getting_started')
%
% You can re-start the ROS node at any time by executing the following
% command on the MATLAB prompt:
%
%  runROSNode(r,'rosberrypi_getting_started','~/catkin_ws')
%
% The second argument specifies the Catkin workspace used to build the ROS
% node.


%% Advanced Topics and Troubleshooting
%
% *Raspberry Pi ROS Indigo Installation* The Raspbian Linux image provided
% by the Simulink Support Package for Raspberry Pi Hardware includes a ROS
% Indigo installation. A the time of writing, there were no binary packages
% available for ROS Indigo. Hence ROS Indigo was installed from sources
% following the instructions provided
% <matlab:web('http://wiki.ros.org/ROSberryPi/Installing%20ROS%20Indigo%20on%20Raspberry%20Pi','-browser')
% here>. To keep the ROS Indigo installation small, only |roscomm|,
% |std_msgs|, |geometry_msgs| and |sensor_msgs| ROS packages have been
% installed. An installation
% <matlab:edit(fullfile(codertarget.raspi.internal.getSpPkgRootDir,'src','install_ros_indigo.sh'))
% script> has been provided to document the steps taken for installation. A
% ROS Catkin workspace has been created for installation in the home
% directory of the default user *pi*. This workspace is called
% |ros_catkin_ws|. A second workspace has been created to build Simulink
% models, |catkin_ws|. You should use the |catkin_ws| as your default
% Simulink model workspace to reduce compilation time. Use |ros_catkin_ws|
% only to add new packages to the existing ROS distribution (see below).
%
% *Adding New Packages to ROS* A
% <matlab:edit(fullfile(codertarget.raspi.internal.getSpPkgRootDir,'src','install_ros_package.sh'))
% script> called |install_ros_package.sh| has been provided to help adding new ROS
% packages to the existing installation. To use this script to add
% |nav_msgs| package, for example, follow the procedure below:
%
% On the MATLAB prompt:
%
%  r = raspberrypi; 
%  installScript = fullfile(codertarget.raspi.internal.getSpPkgRootDir,'src','install_ros_package.sh');
%  putFile(r,installScript); 
%  system(r,['chmod u+x ' installScript]);
%  openShell(r)
% 
% On the Linux shell:
%
%  ./install_ros_package.sh nav_msgs
%
% Note that this command may take several minutes. Some ROS packages may
% require additional dependencies in the form of Linux packages such as
% |collada-dom|. You may need to manually install the required Linux
% packages. For example, to install |collada-dom| follow the procedure
% below on a Linux shell:
%
%  mkdir ~/ros_catkin_ws/external_src
%  sudo apt-get -y install checkinstall cmake
%  sudo sh -c 'echo "deb-src http://mirrordirector.raspbian.org/raspbian/ testing main contrib non-free rpi" >> /etc/apt/sources.list'
%  sudo apt-get update
%  cd ~/ros_catkin_ws/external_src
%  sudo apt-get -y install libboost-filesystem-dev libxml2-dev
%  wget http://downloads.sourceforge.net/project/collada-dom/Collada%20DOM/Collada%20DOM%202.4/collada-dom-2.4.0.tgz
%  tar -xzf collada-dom-2.4.0.tgz
%  cd collada-dom-2.4.0
%  cmake .
%  sudo checkinstall -y make install
% 
% *Starting a ROS Master on Raspberry Pi* The |raspberrypi| object provides
% two methods to start and stop a ROS master on the Raspberry Pi board:
%
%  startroscore 
%  stoproscore
%
% To start a ROS master on the Raspberry Pi, execute the following on the
% MATLAB prompt:
%
%  r = raspberrypi;
%  startroscore(r);
%
% To stop the |roscore| application running on the Raspberry Pi:
%
%  stoproscore(r);
%
% When using a ROS master running on your Raspberry Pi, set *ROS Master*
% network address for simulation accordingly:
%
% <<rosberrypi_ros_master.png>>

%% Summary
%
% This example showed you how to configure a Simulink model to generate C++
% code for a standalone ROS node that runs on Raspberry Pi hardware. It
% also showed how to with the ROS node running on the Raspberry Pi hardware
% using MATLAB command line interface for ROS.

close_system('rosberrypi_getting_started',0); 
displayEndOfDemoMessage(mfilename) 
