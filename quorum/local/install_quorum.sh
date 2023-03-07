#!/bin/bash
# this script is used to install quorum on the remote hosts

# read environment file
. local.env

# import utility functions
. utils/utils.sh

# install quorum on the remote hosts
hosts_array=($(utils::create_remote_hosts_list $HOST $PORT $NUMBER_OF_HOSTS))
utils::exec_cmd_on_remote_hosts './remote/install_quorum.sh' 'Installing quorum on remote hosts' "${hosts_array[@]}"
