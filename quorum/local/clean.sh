#!/bin/bash
# this script is used to clean the remote hosts

# read configuration file
. hosts.conf

# import utility functions
. utils/utils.sh

cmd="sudo rm -rf *; sudo rm -rf /usr/local/go; sed -i '/\/usr\/local\/go/d' ~/.profile"

# clean the remote hosts
hosts_array=($(utils::create_remote_hosts_list $HOST $PORT $NUMBER_OF_HOSTS))
utils::exec_cmd_on_remote_hosts "${cmd}" "Cleaning remote hosts" "${hosts_array[@]}"
