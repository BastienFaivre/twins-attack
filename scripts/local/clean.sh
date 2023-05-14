#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Clean the remote hosts
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
cmd='sudo rm -rf *; sudo rm -rf /usr/local/go; sed -i "/\/usr\/local\/go/d" ~/.profile'
utils::exec_cmd_on_remote_hosts "${cmd}" 'Clean remote hosts' "${hosts_array[@]}"

# Remove trap
trap - ERR
