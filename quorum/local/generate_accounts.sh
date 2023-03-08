#!/bin/bash
# this script is used to generate accounts with initial balance on the remote hosts

# read environment file
. local.env

# import utility functions
. utils/utils.sh

# read argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <number_of_accounts>"
  exit 1
fi
number_of_accounts=$1

# select the first host
hosts_array=($(utils::create_remote_hosts_list $HOST $PORT $NUMBER_OF_HOSTS))
host=${hosts_array[0]}
# generate accounts
cmd="./remote/generate_accounts.sh $number_of_accounts"
utils::exec_cmd_on_remote_hosts "$cmd" 'Generating accounts' $host
