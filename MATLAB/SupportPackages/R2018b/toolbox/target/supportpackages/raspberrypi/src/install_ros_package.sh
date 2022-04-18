#!/bin/bash
#
# Copyright 2015 The MathWorks, Inc.
#
# Installs ROS Indigo on Raspbian Jessie
set -e

ROS_PACKAGE=$1

commandUsage() {
   echo "Usage: $(basename $0) ROS_PACKAGE..." $1
   echo "Install ROS Indigo packages from sources." $1
   echo "ROS_PACKAGE is the name of the ROS_PACKAGE to be installed." $1
   echo "This script uses the ~/ros_catkin_ws as the ROS Catkin workspace." $1 
   echo "" $1
   echo "Example:" $1 
   echo "  ./$(basename $0) nav_msgs " $1
}

if [ -z $1 ] || ([ ! -z $1 ] && [ $1 = "-h" ] || [ $1 = "--help" ]) ; then
   commandUsage
   exit 0
fi

if [ ! $# -eq 1 ] ; then
   echoErr "Expected one input argument. Got $#."
   commandUsage 1>&2
   exit 1
fi

# Install dependencies
cd ~/ros_catkin_ws
rosinstall_generator "$ROS_PACKAGE" --rosdistro indigo --deps --wet-only --exclude roslisp --tar > indigo-custom_ros.rosinstall
wstool merge -t src indigo-custom_ros.rosinstall
wstool update -t src
rosdep install --from-paths src --ignore-src --rosdistro indigo -y -r --os=debian:jessie
sudo ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release --install-space /opt/ros/indigo