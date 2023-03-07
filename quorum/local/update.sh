#!/bin/bash
# this script is used to update the remote hosts

# read configuration file
. hosts.conf

# import utility functions
. utils/utils.sh

# update the remote hosts
hosts_array=($(utils::create_remote_hosts_list $HOST $PORT $NUMBER_OF_HOSTS))
utils::exec_cmd_on_remote_hosts "./remote/update.sh" "Updating remote hosts" "${hosts_array[@]}"

