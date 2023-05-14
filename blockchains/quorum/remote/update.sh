#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Update the host
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. remote/remote.env
. utils/utils.sh

#===============================================================================
# FUNCTIONS
#===============================================================================

# Update the host
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
update_host() {
  # Catch errors
  trap 'exit 1' ERR
  # Update
  sudo apt-get update
  sudo apt-get --with-new-pkgs upgrade -y
  sudo apt-get clean
  sudo apt-get autoclean
  sudo apt-get autoremove --purge -y
  sudo snap refresh
  # Remove trap
  trap - ERR
}

#===============================================================================
# MAIN
#===============================================================================

# Catch errors
trap 'exit 1' ERR

utils::ask_sudo
utils::exec_cmd 'update_host' 'Update host'

# Remove trap
trap - ERR
