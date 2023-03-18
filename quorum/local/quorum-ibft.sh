#!/bin/bash
# this script is used to start or stop the quorum network

# read environment file
. local.env

# import utility functions
. utils/utils.sh

# read argument
if [ $# -lt 1 ]; then
  echo "Usage: $0 start|stop|kill [twins]"
  exit 1
fi
action=$1; shift
twins=$1; shift

# send the command to the remote hosts
hosts_array=($(utils::create_remote_hosts_list $HOST $PORT $NUMBER_OF_HOSTS))
cmd="./remote/quorum-ibft.sh $action $twins"
utils::exec_cmd_on_remote_hosts "$cmd" "Quorum $action" "${hosts_array[@]}"
