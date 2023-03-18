#!/bin/bash
# Import accounts to the node

# read environment file
. remote/remote.env

# import utility functions
. remote/utils/utils.sh

utils::ask_sudo

# check that the installation has been completed and the generation of the configuration has been completed
setup_environment() {
  # check that quorum is installed
  if [ ! -d "$INSTALL_ROOT" ]; then
    echo 'Quorum is not installed. Please run install_quorum.sh first.'
    exit 1
  fi
  # export bin directories
  export PATH="$PATH:$HOME/$INSTALL_ROOT/build/bin"
  export PATH="$PATH:$HOME/$INSTALL_ROOT/istanbul-tools/build/bin"
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
  # check that the configuration has been generated
  if [ ! -n "$(ls -d $DEPLOY_ROOT/n*/ 2> /dev/null)" ]; then
    echo 'The configuration has not been generated. Please run generate-configuration.sh first.'
    exit 1
  fi
}

# import accounts to the node
import_accounts() {
  # retrieve private keys
  local private_keys_file="$1"
  # check that the private keys file exists
  if [ ! -f "$private_keys_file" ]; then
    echo "The private keys file $private_keys_file does not exist."
    exit 1
  fi
  # retrieve the directory of the node
  local node_directory="$(ls -d $DEPLOY_ROOT/n*/)" | rev | cut -c2- | rev
  # import accounts
  while IFS= read -r line; do
    # increment line number
    line_number=$((line_number+1))
    # retrieve account password and private key
    local password="$(echo $line | cut -d':' -f1)"
    local key="$(echo $line | cut -d':' -f2)"
    # write private key to temporary file
    echo $key > ./tmp.key
    # import account
    printf "%d\n%d\n" $password $password | geth account import --datadir $node_directory ./tmp.key
    # remove temporary file
    rm ./tmp.key
  done < "$private_keys_file"
}

setup_environment

# read arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 <private-keys-file>"
  exit 1
fi
private_keys_file="$1"

# cmd="import_accounts $private_keys_file"
# utils::exec_cmd "$cmd" "Import accounts to the node"
import_accounts $private_keys_file
