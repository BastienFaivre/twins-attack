#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: May 2023
# Description: Export the setup to the remote hosts
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

cd "$(dirname "$0")"
. local.env
. ../utils.sh

#===============================================================================
# FUNCTIONS
#===============================================================================

# Export the setup to the remote hosts
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
export() {
  # Catch errors
  trap 'exit 1' ERR
  # Create directory
  ssh -p ${PORT} ${HOST} 'mkdir -p ~/go/src/semester-project'
  # Export
  rsync -rav -e "ssh -p ${PORT}" \
    --exclude '.*' \
    --exclude 'node/' \
    --exclude 'quorum/' \
    --exclude 'client/' \
    --exclude 'algorand/' \
    --exclude 'README.md' \
    . ${HOST}:~/go/src/semester-project
  # Remove trap
  trap - ERR
}

#===============================================================================
# MAIN
#===============================================================================

# Catch errors
trap 'exit 1' ERR

hosts_array=($(utils::create_remote_hosts_list ${HOST} ${PORT} ${NUMBER_OF_HOSTS}))
cmd="export ${hosts_array[@]}"
utils::exec_cmd "${cmd}" 'Export the setup to the remote hosts'

# Remove trap
trap - ERR
