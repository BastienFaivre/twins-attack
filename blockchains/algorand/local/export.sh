#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: May 2023
# Description: Export the remote directory to the remote hosts
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. ../../../utils/local/local.env
. ../../../utils/utils.sh

#===============================================================================
# FUNCTIONS
#===============================================================================

# Export the remote directory to the remote hosts
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
export_remote_directory() {
  # Catch errors
  trap 'exit 1' ERR
  # Export
  (
    cd ..
    for i in $(seq 0 $((NUMBER_OF_HOSTS - 1)))
    do
      rsync -rav -e "ssh -p $((PORT + i))" --exclude 'local/' . ${HOST}:~ &
    done
    wait
  )
  # Remove trap
  trap - ERR
}

#===============================================================================
# MAIN
#===============================================================================

# Catch errors
trap 'exit 1' ERR

utils::exec_cmd 'export_remote_directory' "Export the remote directory to remote hosts"

# Remove trap
trap - ERR
