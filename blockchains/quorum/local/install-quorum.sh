#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Install Quorum on the remote hosts
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. ../../../utils/local/local.env
. ../../../utils/utils.sh

#===============================================================================
# MAIN
#===============================================================================

# Catch errors
trap 'exit 1' ERR

hosts_array=($(utils::create_remote_hosts_list ${HOST} ${PORT} ${NUMBER_OF_HOSTS}))
utils::exec_cmd_on_remote_hosts './remote/install-quorum.sh' 'Install quorum on remote hosts' "${hosts_array[@]}"

# Remove trap
trap - ERR
