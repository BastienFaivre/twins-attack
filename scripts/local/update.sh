#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Update the remote hosts
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

cd "$(dirname "$0")"
. local.env
. ../utils.sh

#===============================================================================
# MAIN
#===============================================================================

# Catch errors
trap 'exit 1' ERR

hosts_array=($(utils::create_remote_hosts_list ${HOST} ${PORT} ${NUMBER_OF_HOSTS}))
utils::exec_cmd_on_remote_hosts './remote/update.sh' 'Update remote hosts' "${hosts_array[@]}"

# Remove trap
trap - ERR
