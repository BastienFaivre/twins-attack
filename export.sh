#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Export the client, controller, and proxy to the remote host
#              $HOST:$PORT (see quorum/local/local.env)
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. quorum/local/local.env
. quorum/local/utils/utils.sh

#===============================================================================
# FUNCTIONS
#===============================================================================

# Export the client, controller, and proxy to the remote host $HOST:$PORT
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
export() {
  rsync -rav -e "ssh -p $PORT" \
    --exclude '.*' \
    --exclude 'node/' \
    --exclude 'quorum/' \
    --exclude 'README.md' \
    . $HOST:~/go/src/semester-project
}

#===============================================================================
# MAIN
#===============================================================================

utils::exec_cmd 'export' "Export files to $HOST:$PORT"
