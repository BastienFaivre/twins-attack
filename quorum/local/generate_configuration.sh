#!/bin/bash
# this script is used to generate the configuration file for quorum

# read environment file
. local.env

# import utility functions
. utils/utils.sh

trap "echo 'Aborting...'; exit 1" ERR

# prepare all hosts
hosts_array=($(utils::create_remote_hosts_list $HOST $PORT $NUMBER_OF_HOSTS))
utils::exec_cmd_on_remote_hosts './remote/generate_configuration.sh prepare' 'Preparing remote hosts' "${hosts_array[@]}"

# select the first host
host=${hosts_array[0]}
# generate the configuration file
utils::exec_cmd_on_remote_hosts './remote/generate_configuration.sh generate remote/nodefile.txt install/geth-accounts/accounts.txt' 'Generating configuration file' $host

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
}
cmd="retrieve_configuration $host"
utils::exec_cmd "$cmd" 'Retrieving configuration file'

# send the configuration file to all hosts
send_configuration() {
  # retrieve argument
  local hosts_array=("$@")
  # copy the configuration file to all hosts
  for host in "${hosts_array[@]}"; do
    # split host into hostname and port
    IFS=':' read -r -a host_array <<< "${host}"
    # copy the configuration file to the local host
    scp -P ${host_array[1]} ./tmp/network.tar.gz ${host_array[0]}:~/deploy/quorum-ibft/network.tar.gz
    # extract the configuration file
    ssh -p ${host_array[1]} ${host_array[0]} "cd ~/deploy/quorum-ibft && tar -xzf network.tar.gz --strip-components=1"
  done
  # remove the tmp directory
  rm -rf ./tmp
}
cmd="send_configuration ${hosts_array[@]}"
utils::exec_cmd "$cmd" 'Sending configuration file'

# finalize the configuration on all hosts
utils::exec_cmd_on_remote_hosts './remote/generate_configuration.sh finalize' 'Finalizing configuration' "${hosts_array[@]}"

trap - ERR
