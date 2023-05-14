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

cd "$(dirname "$0")"
. ../../../scripts/local/local.env
. ../../../scripts/utils.sh

#===============================================================================
# FUNCTIONS
#===============================================================================

# Copy the configuration file to local host
# Globals:
#   None
# Arguments:
#   $1: the remote host
# Outputs:
#   None
# Returns:
#   None
retrieve_configuration() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve argument
  local host=$1
  if [ -z ${host} ]; then
    utils::err 'Missing argument'
    trap - ERR
    exit 1
  fi
  # Split host into hostname and port
  IFS=':' read -r -a host_array <<< ${host}
  local hostname=${host_array[0]}
  local port=${host_array[1]}
  # Empty the tmp directory if it exists
  rm -rf ./tmp
  mkdir -p ./tmp
  # Copy the configuration file to the local host
  scp -P ${port} ${hostname}:~/deploy/algorand/network.tar.gz ./tmp/network.tar.gz
  if [ $? -ne 0 ]; then
    utils::err 'Failed to retrieve configuration file'
    trap - ERR
    exit 1
  fi
  # Remove trap
  trap - ERR
}

# Extract the configuration file
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
extract_configuration() {
  # Catch errors
  trap 'exit 1' ERR
  # Extract the configuration file
  tar -xzf ./tmp/network.tar.gz --strip-components=1 -C ./tmp
  # Remove trap
  trap - ERR
}

# Create each node configuration file
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
create_node_configuration() {
  # Catch errors
  trap 'exit 1' ERR
  # Create each node configuration file
  for dir in ./tmp/n*; do
    # Check that dir is a directory and not a twin directory
    if [ ! -d ${dir} ] || [[ ${dir} == *"twin"* ]]; then
      continue
    fi
    rm -rf ./tmp/tmp
    mkdir -p ./tmp/tmp
    # Copy the node directory
    cp -r ${dir} ./tmp/tmp
    cp -r ${dir}_twin ./tmp/tmp
    # Archive the node directory
    tar -czf ${dir}.tar.gz -C ./tmp/tmp .
    # Remove the tmp directory
    rm -rf ./tmp/tmp
  done
  # Remove trap
  trap - ERR
}

# Send the configuration files to the remote hosts
# Globals:
#   None
# Arguments:
#   $@: the remote hosts array
# Outputs:
#   None
# Returns:
#   None
send_configuration_files() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve argument
  local hosts_array=("$@")
  # send the configuration files to the remote hosts
  local index=0
  for config in ./tmp/n*.tar.gz; do
    # ignore initial configuration archive
    if [ "$config" == './tmp/network.tar.gz' ]; then
      continue
    fi
    # retrieve the hostname and port
    IFS=':' read -r -a host_array <<< "${hosts_array[$index]}"
    local hostname=${host_array[0]}
    local port=${host_array[1]}
    # send the configuration file to the remote host
    scp -P ${port} ${config} ${hostname}:~/deploy/algorand
    if [ $? -ne 0 ]; then
      utils::err 'Failed to send configuration file'
      trap - ERR
      exit 1
    fi
    # untar the configuration file
    ssh -p ${port} ${hostname} "cd ~/deploy/algorand; tar -xzf ${config##*/} --strip-components=1"
    # increment the index
    index=$((index + 1))
  done
  # Remove trap
  trap - ERR
}

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
utils::exec_cmd_on_remote_hosts './blockchains/algorand/remote/generate-configuration.sh prepare' 'Preparing remote hosts' "${hosts_array[@]}"
host=${hosts_array[0]}
utils::exec_cmd_on_remote_hosts "./blockchains/algorand/remote/generate-configuration.sh generate blockchains/algorand/remote/nodefile.txt ${number_of_accounts}" 'Generating configuration' "${host}"
cmd="retrieve_configuration ${host}"
utils::exec_cmd "${cmd}" 'Retrieving configuration file'
utils::exec_cmd 'extract_configuration' 'Extracting configuration file'
utils::exec_cmd 'create_node_configuration' 'Creating node configuration file'
cmd="send_configuration_files ${hosts_array[@]}"
utils::exec_cmd "${cmd}" 'Sending configuration files'

trap - ERR
