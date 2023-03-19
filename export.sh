#!/bin/bash
# export the client, controller, and proxy to the remote host

# read environment file
. quorum/local/local.env

# import utility functions
. quorum/local/utils/utils.sh

# export the client, controller, and proxy to the remote host
export_scripts() {
  rsync -rav -e "ssh -p $PORT" --exclude '.*' --exclude 'node/' --exclude 'quorum/' --exclude 'README.md' . $HOST:~/go/src/semester-project &
  wait
}
utils::exec_cmd 'export_scripts' 'Export scripts to remote host'
