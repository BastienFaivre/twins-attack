#!/bin/bash
# this script is used to generate the configuration file for quorum

# read environment file
. local.env

# import utility functions
. utils/utils.sh

# prepare all hosts
hosts_array=($(utils::create_remote_hosts_list $HOST $PORT $NUMBER_OF_HOSTS))
utils::exec_cmd_on_remote_hosts './remote/generate_configuration.sh prepare' 'Preparing remote hosts' "${hosts_array[@]}"

# select the first host
host=${hosts_array[0]}
# generate the configuration file
utils::exec_cmd_on_remote_hosts './remote/generate_configuration.sh generate remote/nodefile.conf remote/keyfile.conf' 'Generating configuration file' $host
