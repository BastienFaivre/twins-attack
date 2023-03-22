#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Manage the Quorum blockchain
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. local.env
. utils/utils.sh

#===============================================================================
# MAIN
#===============================================================================

# Read argument
if [ $# -lt 1 ]; then
  echo "Usage: $0 start|stop|kill [twins]"
  exit 1
fi
action=${1}; shift
twins=${1}; shift

# Catch errors
trap 'exit 1' ERR

hosts_array=($(utils::create_remote_hosts_list ${HOST} ${PORT} ${NUMBER_OF_HOSTS}))
cmd="./remote/quorum-ibft.sh ${action} ${twins}"
utils::exec_cmd_on_remote_hosts "${cmd}" "Quorum ${action} ${twins}" "${hosts_array[@]}"

# Remove trap
trap - ERR
