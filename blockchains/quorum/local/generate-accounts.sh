#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Generate accounts on one remote host
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
if [ $# -ne 1 ]; then
  echo "Usage: $0 <number_of_accounts>"
  exit 1
fi
number_of_accounts=${1}

# Catch errors
trap 'exit 1' ERR

hosts_array=($(utils::create_remote_hosts_list ${HOST} ${PORT} ${NUMBER_OF_HOSTS}))
host=${hosts_array[0]}
cmd="./remote/generate-accounts.sh ${number_of_accounts}"
utils::exec_cmd_on_remote_hosts "${cmd}" 'Generating accounts' ${host}

# Remove trap
trap - ERR
