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
  # Move to the root directory
  cd ../..
  # Export
  for i in $(seq 0 $((NUMBER_OF_HOSTS - 1)))
  do
    (
      # Export blockchains remote directory
      rsync -rav -e "ssh -p $((PORT + i))" \
        blockchains/ \
        --exclude '*/local/' \
        ${HOST}:~/blockchains
      # Export scripts
      ssh -p $((PORT + i)) ${HOST} 'mkdir -p ~/scripts'
      rsync -rav -e "ssh -p $((PORT + i))" \
        scripts/ \
        --exclude 'local/' \
        ${HOST}:~/scripts
      # Export controller
      ssh -p $((PORT + i)) ${HOST} 'mkdir -p ~/go/src/controller'
      rsync -rav -e "ssh -p $((PORT + i))" \
        controller/ \
        ${HOST}:~/go/src/controller
      # Export proxy
      ssh -p $((PORT + i)) ${HOST} 'mkdir -p ~/go/src/proxy'
      rsync -rav -e "ssh -p $((PORT + i))" \
        proxy/ \
        ${HOST}:~/go/src/proxy
    ) &
  done
  wait
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
