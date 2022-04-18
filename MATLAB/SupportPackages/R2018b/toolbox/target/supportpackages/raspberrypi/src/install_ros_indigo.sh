#!/bin/bash
#
# Copyright 2015-2016 The MathWorks, Inc.
#
# Installation script used for installing ROS Indigo on Raspbian Jessie.
set -e

installCollado() {
    # Install collada-dom-dev 
    mkdir ~/ros_catkin_ws/external_src
    sudo apt-get -y install checkinstall cmake
    sudo sh -c 'echo "deb-src http://mirrordirector.raspbian.org/raspbian/ testing main contrib non-free rpi" >> /etc/apt/sources.list'
    sudo apt-get update
    cd ~/ros_catkin_ws/external_src
    sudo apt-get -y install libboost-filesystem-dev libxml2-dev
    wget http://downloads.sourceforge.net/project/collada-dom/Collada%20DOM/Collada%20DOM%202.4/collada-dom-2.4.0.tgz
    tar -xzf collada-dom-2.4.0.tgz
    cd collada-dom-2.4.0
    cmake .
    sudo checkinstall -y make install
}

# Install dependencies
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu jessie main" > /etc/apt/sources.list.d/ros-latest.list'
wget https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -O - | sudo apt-key add -
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install python-pip python-setuptools python-yaml python-distribute python-docutils python-dateutil python-six
sudo pip install rosdep rosinstall_generator wstool rosinstall
sudo rosdep init
rosdep update
mkdir ~/ros_catkin_ws
cd ~/ros_catkin_ws
rosinstall_generator ros_comm rosout std_msgs sensor_msgs geometry_msgs  --rosdistro indigo --deps --wet-only --exclude roslisp --tar > indigo-ros_comm-wet.rosinstall
wstool init src indigo-ros_comm-wet.rosinstall

# Download ROS packagesto
rosdep install --from-paths src --ignore-src --rosdistro indigo -y -r --os=debian:jessie

# Build ROS packages
# Increase swap file size before this step to avoid internal C++ compiler 
# error 
#sudo nano /etc/dphys-swapfile
#sudo dphys-swapfile setup
#sudo dphys-swapfile swapon
sudo ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release --install-space /opt/ros/indigo

# Source setup script for ROS Indigo
source /opt/ros/indigo/setup.bash

# Initialize ROS user workspace ~/catkin_ws
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src
catkin_init_workspace

# Build ROS user workspace. This step creates devel and build directories under the ~/catkin_ws.
cd ~/catkin_ws/
catkin_make
