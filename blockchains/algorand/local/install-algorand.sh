#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: May 2023
# Description: Install Algorand on the remote hosts
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

cd "$(dirname "$0")"
. ../../../scripts/local/local.env
. ../../../scripts/utils.sh

#===============================================================================
# MAIN
#===============================================================================

# Catch errors
trap 'exit 1' ERR

hosts_array=($(utils::create_remote_hosts_list ${HOST} ${PORT} ${NUMBER_OF_HOSTS}))
utils::exec_cmd_on_remote_hosts './blockchains/algorand/remote/install-algorand.sh' 'Install algorand on remote hosts' "${hosts_array[@]}"

# Remove trap
trap - ERR
