#!/bin/bash
#===============================================================================
# Modified by: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Generate configuration files for Quorum
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/deploy-quorum-ibft-worker
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. remote/remote.env
. remote/utils/utils.sh

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
  if [ ! -d "${INSTALL_ROOT}" ]; then
    echo 'Quorum is not installed. Please run install_quorum.sh first.'
    trap - ERR
    exit 1
  fi
  # Export bin directories
  export PATH="${PATH}:${HOME}/${INSTALL_ROOT}/build/bin"
  export PATH="${PATH}:${HOME}/${INSTALL_ROOT}/istanbul-tools/build/bin"
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
      "Istanbul command not found in ${INSTALL_ROOT}/istanbul-tools/build/bin"$
    trap - ERR
    exit 1
  fi
  # Remove trap
  trap - ERR
}

# Prepare the host for the configuration generation
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
prepare() {
  setup_environment
  # Create deploy directory
  if [ -d "${DEPLOY_ROOT}" ]; then
    rm -rf ${DEPLOY_ROOT}
  fi
  mkdir -p ${DEPLOY_ROOT}
}

# Prepare the network root directory and create a directory for each node
# Globals:
#   None
# Arguments:
#   $1: number of nodes
# Outputs:
#   None
# Returns:
#   None
prepare_network_root() {
  # Retrieve arguments
  local number_of_nodes="${1}"
  # Create network root directory
  if [ -d "${NETWORK_ROOT}" ]; then
    rm -rf ${NETWORK_ROOT}
  fi
  mkdir ${NETWORK_ROOT}
  # Create a directory for each node
  for i in $(seq 0 $((number_of_nodes - 1))); do
    mkdir ${NETWORK_ROOT}/n${i}
    mkdir ${NETWORK_ROOT}/n${i}_twin
  done
}

# Set the ip and port of each node in the static-nodes.json file
# Globals:
#   None
# Arguments:
#   $1: static-nodes.json file
#   $2: nodefile
# Outputs:
#   None
# Returns:
#   None
set_nodes_ip_port() {
  # Retrieve arguments
  local static_nodes_file="${1}"
  local nodefile="${2}"
  # Create a twin file
  local static_nodes_file_twin="${static_nodes_file}.twin"
  # Read the static-nodes.json file
  local index=1
  while IFS= read -r line; do
    # Check if the line contains the string "enode"
    if [[ ! ${line} == *"enode"* ]]; then
      echo "${line}" >> "${static_nodes_file}.tmp"
      echo "${line}" >> "${static_nodes_file}_twin"
      continue
    fi
    # Retrieve node ip and port from the nodefile
    local node=$(sed -n "${index}p" ${nodefile})
    local node_ip=$(echo ${node} | cut -d: -f1)
    local node_port=$(echo ${node} | cut -d: -f2)
    local node_port_twin=$(echo ${node} | cut -d: -f4)
    # Replace the ip and port in the enode uri
    local new_line=$(echo ${line} | sed "s/@.*?/@${node_ip}:${node_port}?/")
    echo ${new_line} >> "${static_nodes_file}.tmp"
    local new_line_twin=$(echo ${line} | sed "s/@.*?/@${node_ip}:${node_port_twin}?/")
    echo ${new_line_twin} >> ${static_nodes_file_twin}
    # Increment the index
    index=$((index + 1))
  done < ${static_nodes_file}
  echo ']' >> "${static_nodes_file}.tmp"
  echo ']' >> ${static_nodes_file_twin}
  # Replace the static-nodes.json file with the new one
  mv "${static_nodes_file}.tmp" ${static_nodes_file}
}

# set the account address and balance present in the keyfile in the genesis.json file
initialize_accounts() {
  # retrieve arguments
  local genesis="${1}"
  local keyfile="${2}"
  # read the genesis file
  while IFS= read -r line; do
    echo "$line"
    # check if the line contains the string "alloc"
    if [[ $line == *"alloc"* ]]; then
      while IFS= read -r account; do
        address=$(echo $account | cut -d: -f1)
        printf "        \"%s\": {\n" "${address}"
		    printf "            \"balance\": \"%s\"\n" "${BALANCE}"
		    printf "        },\n"
      done < $keyfile
    fi
  done < $genesis > "$genesis.tmp"
  echo '}' >> "$genesis.tmp"
  # replace the genesis file
  mv "$genesis.tmp" $genesis
}

# fill the nodes directory with the nodekey, port and rpc port files
initialize_nodes() {
  # retrieve arguments
  local nodefile="${1}"
  local number_of_nodes="${2}"
  # initialize nodes
  for i in $(seq 0 $((number_of_nodes - 1))); do
    # retrieve node port and rpc port from the nodefile
    local node=$(sed -n "$((i+1))p" $nodefile)
    local node_port=$(echo $node | cut -d: -f2)
    local rpc_port=$(echo $node | cut -d: -f3)
    local node_port_twin=$(echo $node | cut -d: -f4)
    local rpc_port_twin=$(echo $node | cut -d: -f5)
    # copy the nodekey to the node directory and remove the old directory
    cp $NETWORK_ROOT/$i/nodekey $NETWORK_ROOT/n$i/nodekey
    cp $NETWORK_ROOT/$i/nodekey $NETWORK_ROOT/n${i}_twin/nodekey
    chmod 644 $NETWORK_ROOT/n$i/nodekey
    chmod 644 $NETWORK_ROOT/n${i}_twin/nodekey
    rm -rf $NETWORK_ROOT/$i
    # add port and rpc port files to the node directory
    echo $node_port > $NETWORK_ROOT/n$i/port
    echo $rpc_port > $NETWORK_ROOT/n$i/rpcport
    echo $node_port_twin > $NETWORK_ROOT/n${i}_twin/port
    echo $rpc_port_twin > $NETWORK_ROOT/n${i}_twin/rpcport
  done
}

# generate the configuration file for quorum
generate() {
  if [ $# -ne 2 ]; then
    echo "Usage: $0 generate <nodefile> <keyfile>"
    exit 1
  fi
  # check that the installation has been completed
  setup_environment
  # retrieve arguments
  local nodefile="${1}"
  local keyfile="${2}"
  # check that the nodefile and keyfile exist
  if [ ! -f "$nodefile" ]; then
    utils::err "Nodefile $nodefile does not exist"
    exit 1
  fi
  if [ ! -f "$keyfile" ]; then
    utils::err "Keyfile $keyfile does not exist"
    exit 1
  fi
  # count the number of nodes
  local number_of_nodes=$(wc -l < $nodefile)
  # prepare network root
  prepare_network_root $number_of_nodes
  # run istanbul setup
  (
    cd $NETWORK_ROOT
    istanbul setup --num $number_of_nodes --nodes --quorum --save --verbose > /tmp/istanbul.log 2>&1
    if [ $? -ne 0 ]; then
      utils::err "Istanbul setup failed: $(cat /tmp/istanbul.log)"
      exit 1
    fi
    rm /tmp/istanbul.log
  )
  # set nodes ip and port
  set_nodes_ip_port "$NETWORK_ROOT/static-nodes.json" $nodefile
  # initialize accounts
  initialize_accounts "$NETWORK_ROOT/genesis.json" $keyfile
  # initialize nodes
  initialize_nodes $nodefile $number_of_nodes
  # zip the network root
  tar -C $DEPLOY_ROOT -czf $NETWORK_ROOT.tar.gz 'network'
  # remove the network root
  rm -rf $NETWORK_ROOT
}

# finalize the network by initializing each node
finalize() {
  local genesis=$DEPLOY_ROOT/genesis.json
  local static_nodes=$DEPLOY_ROOT/static-nodes.json
  # check that the installation has been completed
  setup_environment
  # remove network root if it exists
  if [ -d "$NETWORK_ROOT" ]; then
    rm -rf $NETWORK_ROOT
  fi
  # iterate over all nodes directories
  for dir in $DEPLOY_ROOT/n*; do
    # check that dir is a directory
    if [ ! -d "$dir" ]; then
      continue
    fi
    # copy the right static-nodes.json file to the node directory
    if [[ $dir == *"twin"* ]]; then
      cp $static_nodes.twin $dir/static-nodes.json
    else
      cp $static_nodes $dir/static-nodes.json
    fi
    # initialize the node
    geth --datadir $dir init $genesis > /dev/null 2>&1
  done
  # remove the genesis.json and static-nodes.json files
  rm $genesis $static_nodes $static_nodes.twin
}

utils::ask_sudo

# check that at least one argument has been provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <action> [options...]"
  exit 1
fi

# read action
action=$1; shift

case $action in
  'prepare')
    cmd="prepare $@"
    utils::exec_cmd "$cmd" 'Prepare all hosts'
    ;;
  'generate')
    cmd="generate $@"
    utils::exec_cmd "$cmd" 'Generate configuration files'
    ;;
  'finalize')
    cmd="finalize $@"
    utils::exec_cmd "$cmd" 'Finalize configuration'
    ;;
  *)
    echo "Usage: $0 <action> [options...]"
    exit 1
    ;;
esac
