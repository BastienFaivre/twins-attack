#!/bin/bash
#===============================================================================
# Modified by: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Manage the Quorum node of the host
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/quorum-ibft
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. remote/remote.env
. utils/utils.sh

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
    # retrieve node port and rpc port
    local port=$(cat ${dir}/port)
    local rpcport=$(cat ${dir}/rpcport)
    # verify the ports
    if [ -z ${port} ] || [ -z ${rpcport} ]; then
      utils::err "Could not retrieve port or rpc port for node ${dir}"
      trap - ERR
      exit 1
    fi
    # start the node
    geth --datadir ${dir} \
      --allow-insecure-unlock \
      --nodiscover \
      --istanbul.blockperiod 5 \
      --syncmode full \
      --mine \
      --miner.threads 1 \
      --verbosity 2 \
      --networkid 10 \
      --ws \
      --ws.addr 0.0.0.0 \
      --ws.port ${rpcport} \
      --ws.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
      --ws.origins "*" \
      --emitcheckpoints \
      --port ${port} \
      --http \
      --http.addr 0.0.0.0 \
      --http.port ${rpcport} \
      --http.corsdomain "*" \
      --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
      > ${dir}/out.log 2> ${dir}/err.log &
    local pid=$!
    echo ${pid} > ${dir}/pid
  done
  # make sure that the nodes are started and connected
  sleep 5
}

# Stop the nodes with a signal
# Globals:
#   None
# Arguments:
#   $1: signal to send to the nodes
# Outputs:
#   None
# Returns:
#   None
_kill() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local sig="${1}"
  if [ -z "${sig}" ]; then
    utils::err "Signal not provided"
    trap - ERR
    exit 1
  fi
  # Kill the nodes
  for dir in ${DEPLOY_ROOT}/n*; do
    # Check that dir is a directory
    if [ ! -d ${dir} ]; then
      continue
    fi
    # Retrieve pid
    if [ ! -f ${dir}/pid ]; then
      continue
    fi
    pid=$(cat ${dir}/pid)
    # Kill the node
    kill ${sig} ${pid}
    # Remove pid file
    rm ${dir}/pid
  done
  # Remove trap
  trap - ERR
}

# Stop the nodes with SIGINT
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
  # Stop the nodes
  _kill -SIGINT
  # Remove trap
  trap - ERR
}

# Kill the nodes with SIGKILL
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
nkill() {
  # Catch errors
  trap 'exit 1' ERR
  # Kill the nodes
  _kill -SIGKILL
  # Remove trap
  trap - ERR
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
  kill)
    utils::exec_cmd nkill "Kill all nodes"
    ;;
  *)
    echo "Usage: $0 start|stop|kill [twins]"
    trap - ERR
    exit 1
    ;;
esac

# Remove trap
trap - ERR
