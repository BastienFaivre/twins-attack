#!/bin/bash
# this script is used to generate the configuration file for quorum

# read environment file
. local.env

# import utility functions
. utils/utils.sh

trap "echo 'Aborting...'; exit 1" ERR

# prepare all hosts
hosts_array=($(utils::create_remote_hosts_list $HOST $PORT $NUMBER_OF_HOSTS))
utils::exec_cmd_on_remote_hosts './remote/generate-configuration.sh prepare' 'Preparing remote hosts' "${hosts_array[@]}"

# select the first host
host=${hosts_array[0]}
# generate the configuration file
utils::exec_cmd_on_remote_hosts './remote/generate-configuration.sh generate remote/nodefile.txt install/geth-accounts/accounts.txt' 'Generating configuration file' $host

# copy the configuration file to the local host
retrieve_configuration() {
  # retrieve argument
  local host=$1
  # split host into hostname and port
  IFS=':' read -r -a host_array <<< "${host}"
  # empty the tmp directory if it exists
  if [ -d ./tmp ]; then
    rm -rf ./tmp
  fi
  mkdir -p ./tmp
  # copy the configuration file to the local host
  scp -P ${host_array[1]} ${host_array[0]}:~/deploy/quorum-ibft/network.tar.gz ./tmp/network.tar.gz
  if [ $? -ne 0 ]; then
    utils::err 'Failed to retrieve configuration file'
    exit 1
  fi
  # copy the accounts file to the local host
  scp -P ${host_array[1]} ${host_array[0]}:~/install/geth-accounts/accounts.txt ./tmp/accounts.txt
  if [ $? -ne 0 ]; then
    utils::err 'Failed to retrieve accounts file'
    exit 1
  fi
}
cmd="retrieve_configuration $host"
utils::exec_cmd "$cmd" 'Retrieving configuration file'

# extract the configuration file
extract_configuration() {
  tar -xzf ./tmp/network.tar.gz --strip-components=1 -C ./tmp
}
utils::exec_cmd 'extract_configuration' 'Extracting configuration file'

# create each node configuration file
create_node_configuration() {
  for dir in ./tmp/n*; do
    # check that dir is a directory and not a twin directory
    if [ ! -d "$dir" ] || [[ "$dir" == *"twin"* ]]; then
      continue
    fi
    mkdir -p ./tmp/tmp
    # copy the genesis.json and static-nodes.json files
    cp ./tmp/genesis.json ./tmp/tmp
    cp ./tmp/static-nodes.json ./tmp/tmp
    cp ./tmp/static-nodes.json.twin ./tmp/tmp
    # copy the node directory
    cp -r "$dir" ./tmp/tmp
    cp -r "${dir}_twin" ./tmp/tmp
    # archive the node directory
    tar -czf "${dir}.tar.gz" -C ./tmp/tmp .
    # remove the tmp directory
    rm -rf ./tmp/tmp
  done
}
utils::exec_cmd 'create_node_configuration' 'Creating node configuration files'

# send the configuration files to the remote hosts
send_configuration_files() {
  # retrieve argument
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
    # send the configuration file to the remote host
    scp -P ${host_array[1]} "$config" ${host_array[0]}:~/deploy/quorum-ibft
    if [ $? -ne 0 ]; then
      utils::err 'Failed to send configuration file'
      exit 1
    fi
    # untar the configuration file
    ssh -p ${host_array[1]} ${host_array[0]} "cd ~/deploy/quorum-ibft; tar -xzf ${config##*/} --strip-components=1"
    # increment the index
    index=$((index + 1))
  done
}
cmd="send_configuration_files ${hosts_array[@]}"
utils::exec_cmd "$cmd" 'Sending configuration files'

# finalize the configuration on all hosts
utils::exec_cmd_on_remote_hosts './remote/generate-configuration.sh finalize' 'Finalizing configuration' "${hosts_array[@]}"

trap - ERR
