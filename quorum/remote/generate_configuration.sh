#!/bin/bash
# Generate configuration files for Quorum
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/deploy-quorum-ibft-worker

# read environment file
. remote/remote.env

# import utility functions
. remote/utils/utils.sh

utils::ask_sudo

setup_environment() {
  # check that quorum is installed
    if [ ! -d "$INSTALL_ROOT" ]; then
      echo 'Quorum is not installed. Please run install_quorum.sh first.'
      exit 1
    fi
    # export bin directories
    export PATH="$PATH:$INSTALL_ROOT/build/bin"
    export PATH="$PATH:$INSTALL_ROOT/istanbul-tools/build/bin"
    # check that the geth and istanbul commands are available
    if ! command -v geth &> /dev/null
    then
      utils::err "Geth command not found in $INSTALL_ROOT/build/bin"
      exit 1
    fi
    if ! command -v istanbul &> /dev/null
    then
      utils::err "Istanbul command not found in $INSTALL_ROOT/istanbul-tools/build/bin"
      exit 1
    fi
}

# setup environment
utils::exec_cmd 'setup_environment' 'Setup environment'
