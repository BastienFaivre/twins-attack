#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Import accounts on the remote hosts
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

cd "$(dirname "$0")"
. ../../../scripts/local/local.env
. ../../../scripts/utils.sh

#===============================================================================
# FUNCTIONS
#===============================================================================

# Verify that the configuration has been generated
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
verify_configuration() {
  # Catch errors
  trap 'exit 1' ERR
  # Check that the configuration has been generated
  if [ ! -f ./tmp/network.tar.gz ]; then
    echo 'The configuration has not been generated. Please run generate-configuration.sh first.'
    trap - ERR
    exit 1
  fi
  # Check that the accounts have been retrieved
  if [ ! -f ./tmp/accounts.txt ]; then
    echo 'The accounts have not been retrieved. Please run generate-configuration.sh first.'
    trap - ERR
    exit 1
  fi
  # Remove trap
  trap - ERR
}

# Create each node accounts file
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
create_node_accounts_file() {
  # Catch errors
  trap 'exit 1' ERR
  # Create the formatted accounts.txt file
  if [ -f ./tmp/accounts_formatted.txt ]; then
    rm ./tmp/accounts_formatted.txt
  fi
  local index=0
  while IFS= read -r line; do
    local key=$(echo ${line} | cut -d: -f2)
    echo ${index}:${key} >> ./tmp/accounts_formatted.txt
    index=$((index+1))
  done < ./tmp/accounts.txt
  for dir in ./tmp/n*; do
    # Check that dir is a directory
    if [ ! -d ${dir} ]; then
    continue
    fi
    local node_number=$(echo ${dir} | sed 's/.*n\([0-9]*\)/\1/')
    cat ./tmp/accounts_formatted.txt >> ${dir}/accounts.txt
    # Add the node account
    echo ${node_number}:$(cat ${dir}/nodekey) >> ${dir}/accounts.txt
  done
  # Remove trap
  trap - ERR
}

# Send the accounts file to the remote hosts
# Globals:
#   None
# Arguments:
#   $@: the remote hosts array
# Outputs:
#   None
# Returns:
#   None
send_accounts_file() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve argument
  local hosts_array=("$@")
  # Send the accounts file to the remote hosts
  local index=0
  for host in "${hosts_array[@]}"; do
    # retrieve the hostname and port
    IFS=':' read -r -a host_array <<< "${host}"
    # copy the accounts file ./tmp/n$index/accounts.txt to the remote host
    scp -P ${host_array[1]} ./tmp/n${index}/accounts.txt ${host_array[0]}:~/deploy/quorum-ibft/accounts.txt
    if [ $? -ne 0 ]; then
      utils::err 'Failed to send accounts file'
      trap - ERR
      exit 1
    fi
    index=$((index+1))
  done
  # Remove trap
  trap - ERR
}

#===============================================================================
# MAIN
#===============================================================================

# Catch errors
trap 'exit 1' ERR

utils::exec_cmd 'verify_configuration' 'Verify configuration'
utils::exec_cmd 'create_node_accounts_file' 'Create node accounts file'
hosts_array=($(utils::create_remote_hosts_list ${HOST} ${PORT} ${NUMBER_OF_HOSTS}))
cmd="send_accounts_file ${hosts_array[@]}"
utils::exec_cmd "${cmd}" 'Send accounts file'
utils::exec_cmd_on_remote_hosts './blockchains/quorum/remote/import-accounts.sh deploy/quorum-ibft/accounts.txt' 'Import accounts' "${hosts_array[@]}"

# Remove trap
trap - ERR
