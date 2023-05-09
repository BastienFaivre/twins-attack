#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: May 2023
# Description: Generate the configuration file on one remote host
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. local.env
. utils/utils.sh

#===============================================================================
# FUNCTIONS
#===============================================================================



#===============================================================================
# MAIN
#===============================================================================

# Catch errors
trap 'exit 1' ERR

hosts_array=($(utils::create_remote_hosts_list ${HOST} ${PORT} ${NUMBER_OF_HOSTS}))
utils::exec_cmd_on_remote_hosts './remote/generate-configuration.sh prepare' 'Preparing remote hosts' "${hosts_array[@]}"
host=${hosts_array[0]}
utils::exec_cmd_on_remote_hosts './remote/generate-configuration.sh generate remote/nodefile.txt' 'Generating configuration' "${host}"

trap - ERR
