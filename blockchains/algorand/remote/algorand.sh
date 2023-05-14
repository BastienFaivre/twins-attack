#!/bin/bash
#===============================================================================
# Modified by: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: May 2023
# Description: Manage the Algorand node of the host
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/algorand
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. blockchains/algorand/remote/remote.env
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
    echo 'Algorand is not installed. Please run install-algorand.sh first.'
    trap - ERR
    exit 1
  fi
  # Export bin directories
  export PATH=${PATH}:${HOME}/go/bin
  export PATH=${PATH}:${HOME}/${INSTALL_ROOT}/algorand-tools
  # Check that the geth and istanbul commands are available
  if ! command -v goal &> /dev/null
  then
    utils::err "Goal command not found in /go/bin"
    trap - ERR
    exit 1
  fi
  # Remove trap
  trap - ERR
}

# Start the nodes
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
start() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local twins=${1}
  export PRIVATE_CONFIG=ignore
  # Start the nodes
  for dir in ${DEPLOY_ROOT}/n*; do
    # check that dir is a directory
    if [ ! -d ${dir} ]; then
    continue
    fi
    # if twins argument is not provided, ignore twin nodes
    if [ -z ${twins} ] && [[ ${dir} == *"twin"* ]]; then
      continue
    fi
    ${dir}/start.sh > ${dir}/log.txt 2>&1 &
  done
  # make sure that the nodes are started and connected
  sleep 5
}

# Stop the nodes
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
stop() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local twins=${1}
  export PRIVATE_CONFIG=ignore
  # Start the nodes
  for dir in ${DEPLOY_ROOT}/n*; do
    # check that dir is a directory
    if [ ! -d ${dir} ]; then
    continue
    fi
    # if twins argument is not provided, ignore twin nodes
    if [ -z ${twins} ] && [[ ${dir} == *"twin"* ]]; then
      continue
    fi
    goal node stop --datadir ${dir} > /dev/null 2>&1
  done
  killall 'algod' > /dev/null 2>&1
}

#===============================================================================
# MAIN
#===============================================================================

# Read arguments
if [ $# -lt 1 ]; then
  echo "Usage: $0 start|stop|kill [twins]"
  exit 1
fi
action=${1}
twins=${2}
if [ ! -z "$twins" ] && [ "$twins" != "twins" ]; then
  echo "Usage: $0 start|stop|kill [twins]"
  exit 1
fi

# Catch errors
trap 'exit 1' ERR

utils::ask_sudo
setup_environment
case ${action} in
  start)
    cmd="start ${twins}"
    utils::exec_cmd "${cmd}" "Start all nodes"
    ;;
  stop)
    utils::exec_cmd stop "Stop all nodes"
    ;;
  *)
    echo "Usage: $0 start|stop [twins]"
    trap - ERR
    exit 1
    ;;
esac

# Remove trap
trap - ERR
