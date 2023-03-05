#!/bin/bash
# export all scripts in this directory to the remote hosts

# import utility functions
. utils/utils.sh

PORT=2212
NUMBER_OF_HOSTS=5

# export all scripts except this one to the remote hosts
export-scripts() {
  for i in $(seq 0 $((NUMBER_OF_HOSTS - 1)))
  do
    rsync -rav -e "ssh -p $((PORT + i))" --exclude 'export.sh' . user@dclbigmem.epfl.ch:~/quorum
  done
}

# export all scripts
utils::exec_cmd "export-scripts" "Exporting scripts to remote hosts"
