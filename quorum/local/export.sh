#!/bin/bash
# export all scripts in this directory to the remote hosts

# read configuration file
. hosts.conf

# import utility functions
. utils/utils.sh

# export all scripts except this one to the remote hosts
export-scripts() {
  cd ..
  for i in $(seq 0 $((NUMBER_OF_HOSTS - 1)))
  do
    rsync -rav -e "ssh -p $((PORT + i))" --exclude 'local/' . $HOST:~ &
  done
  wait
}

# export all scripts
utils::exec_cmd "export-scripts" "Exporting scripts to remote hosts"
