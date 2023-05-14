#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Import accounts to all nodes of the host
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. blockchains/quorum/remote/remote.env
. scripts/utils.sh

#===============================================================================
# FUNCTIONS
#===============================================================================

# Check that the necessary commands are available and export them
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
setup_environment() {
  # Catch errors
  trap 'exit 1' ERR
  # Check that quorum is installed
  if [ ! -d ${INSTALL_ROOT} ]; then
    echo 'Quorum is not installed. Please run install-quorum.sh first.'
    trap - ERR
    exit 1
  fi
  # Export bin directories
  export PATH=${PATH}:${HOME}/${INSTALL_ROOT}/build/bin
  export PATH=${PATH}:${HOME}/${INSTALL_ROOT}/istanbul-tools/build/bin
  # Check that the geth and istanbul commands are available
  if ! command -v geth &> /dev/null
  then
    utils::err "Geth command not found in ${INSTALL_ROOT}/build/bin"
    trap - ERR
    exit 1
  fi
  if ! command -v istanbul &> /dev/null
  then
    utils::err \
      "Istanbul command not found in ${INSTALL_ROOT}/istanbul-tools/build/bin"
    trap - ERR
    exit 1
  fi
  # Remove trap
  trap - ERR
}

# Import accounts to all nodes of the host
# Globals:
#   None
# Arguments:
#   $1: private keys file
# Outputs:
#   None
# Returns:
#   None
import_accounts() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local private_keys_file=${1}
  if [ ! -f ${private_keys_file} ]; then
    utils::err "The private keys file ${private_keys_file} does not exist."
    trap - ERR
    exit 1
  fi
  # Iterate over all nodes directories
  for dir in ${DEPLOY_ROOT}/n*; do
    # Check that dir is a directory
    if [ ! -d ${dir} ]; then
      continue
    fi
    # Import accounts
    while IFS= read -r line; do
      # Retrieve account password and private key
      local password="$(echo ${line} | cut -d':' -f1)"
      local key="$(echo ${line} | cut -d':' -f2)"
      # Write private key to temporary file
      echo ${key} > ./tmp.key
      # Import account
      printf "%d\n%d\n" ${password} ${password} | geth account import --datadir ${dir} ./tmp.key
      # Remove temporary file
      rm ./tmp.key
    done < ${private_keys_file}
  done
  # Remove trap
  trap - ERR
}

#===============================================================================
# MAIN
#===============================================================================

# Read arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 <private-keys-file>"
  exit 1
fi
private_keys_file=${1}

# Catch errors
trap 'exit 1' ERR

utils::ask_sudo
setup_environment
cmd="import_accounts ${private_keys_file}"
utils::exec_cmd "${cmd}" "Import accounts to the node"

# Remove trap
trap - ERR
