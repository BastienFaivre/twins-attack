#!/bin/bash
# this script is used to import accounts to the nodes

# read environment file
. local.env

# import utility functions
. utils/utils.sh

trap "echo 'Aborting...'; exit 1" ERR

# check that the configuration has been generated and the accounts have been retrieved
verify_configuration() {
  # check that the configuration has been generated
  if [ ! -f ./tmp/network.tar.gz ]; then
    echo 'The configuration has not been generated. Please run generate-configuration.sh first.'
    exit 1
  fi
  # check that the accounts have been retrieved
  if [ ! -f ./tmp/accounts.txt ]; then
    echo 'The accounts have not been retrieved. Please run generate-configuration.sh first.'
    exit 1
  fi
}
utils::exec_cmd 'verify_configuration' 'Verify configuration'

# create each node accounts file
create_node_accounts_file() {
  # create the accounts file password:private_key from the accounts.txt file
  if [ -f ./tmp/accounts_formatted.txt ]; then
    rm ./tmp/accounts_formatted.txt
  fi
  index=0
  while IFS= read -r line; do
    key=$(echo $line | cut -d: -f2)
    echo "$index:$key" >> ./tmp/accounts_formatted.txt
    index=$((index+1))
  done < ./tmp/accounts.txt
  for dir in ./tmp/n*; do
    # check that dir is a directory
    if [ ! -d "$dir" ]; then
    continue
    fi
    # get the node number
    node_number=$(echo $dir | sed 's/.*n\([0-9]*\)/\1/')
    # add all account from the formatted accounts.txt file
    cat ./tmp/accounts_formatted.txt >> $dir/accounts.txt
    # add the node account: node_number:nodekey
    echo "$node_number:$(cat $dir/nodekey)" >> $dir/accounts.txt
  done
}
utils::exec_cmd 'create_node_accounts_file' 'Create node accounts file'

hosts_array=($(utils::create_remote_hosts_list $HOST $PORT $NUMBER_OF_HOSTS))

# send the accounts file to the remote hosts
send_accounts_file() {
  # retrieve argument
  local hosts_array=("$@")
  # send the accounts file to the remote hosts
  local index=0
  for host in "${hosts_array[@]}"; do
    # retrieve the hostname and port
    IFS=':' read -r -a host_array <<< "${host}"
    # copy the accounts file ./tmp/n$index/accounts.txt to the remote host
    scp -P ${host_array[1]} ./tmp/n$index/accounts.txt ${host_array[0]}:~/deploy/quorum-ibft/accounts.txt
    if [ $? -ne 0 ]; then
      utils::err 'Failed to send accounts file'
      exit 1
    fi
    index=$((index+1))
  done
}
cmd="send_accounts_file ${hosts_array[@]}"
utils::exec_cmd "$cmd" 'Send accounts file'

# import the accounts on the remote hosts
utils::exec_cmd_on_remote_hosts './remote/import-accounts.sh deploy/quorum-ibft/accounts.txt' 'Import accounts' "${hosts_array[@]}"

trap - ERR
