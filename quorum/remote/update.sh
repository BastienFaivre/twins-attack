#!/bin/bash
# this script is used to update the packages on the remote hosts

sudo apt-get update
sudo apt-get --with-new-pkgs upgrade -y
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove --purge -y

sudo snap refresh
