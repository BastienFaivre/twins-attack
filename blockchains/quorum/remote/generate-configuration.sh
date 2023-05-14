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
  # Catch errors
  trap 'exit 1' ERR
  # Setup environment
  setup_environment
  # Create deploy directory
  rm -rf ${DEPLOY_ROOT}
  mkdir -p ${DEPLOY_ROOT}
  # Remove trap
  trap - ERR
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
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local number_of_nodes=${1}
  if [ -z ${number_of_nodes} ]; then
    echo 'Missing number of nodes.'
    trap - ERR
    exit 1
  fi
  # Create network root directory
  rm -rf ${NETWORK_ROOT}
  mkdir -p ${NETWORK_ROOT}
  # Create a directory for each node
  for i in $(seq 0 $((number_of_nodes - 1))); do
    mkdir ${NETWORK_ROOT}/n${i}
    mkdir ${NETWORK_ROOT}/n${i}_twin
  done
  # Remove trap
  trap - ERR
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
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local static_nodes_file=${1}
  local nodefile=${2}
  if [ ! -f ${static_nodes_file} ]; then
    echo "Static-nodes.json file ${static_nodes_file} does not exist."
    trap - ERR
    exit 1
  fi
  if [ ! -f ${nodefile} ]; then
    echo "Nodefile ${nodefile} does not exist."
    trap - ERR
    exit 1
  fi
  # Read the static-nodes.json file
  local index=1
  while IFS= read -r line; do
    # Check if the line does not contain the string "enode"
    if [[ ! ${line} == *"enode"* ]]; then
      echo ${line} >> ${static_nodes_file}.tmp
      echo ${line} >> ${static_nodes_file}.twin
      continue
    fi
    # Retrieve node ip and port from the nodefile
    local node=$(sed -n "${index}p" ${nodefile})
    local node_ip=$(echo ${node} | cut -d: -f1)
    local node_port=$(echo ${node} | cut -d: -f2)
    local node_port_twin=$(echo ${node} | cut -d: -f4)
    # Replace the ip and port in the enode uri
    local new_line=$(echo ${line} | sed "s/@.*?/@${node_ip}:${node_port}?/")
    echo ${new_line} >> ${static_nodes_file}.tmp
    local new_line_twin=$(echo ${line} | sed "s/@.*?/@${node_ip}:${node_port_twin}?/")
    echo ${new_line_twin} >> ${static_nodes_file}.twin
    # Increment the index
    index=$((index + 1))
  done < ${static_nodes_file}
  echo ']' >> ${static_nodes_file}.tmp
  echo ']' >> ${static_nodes_file}.twin
  # Replace the static-nodes.json file with the new one
  mv ${static_nodes_file}.tmp ${static_nodes_file}
  # Remove trap
  trap - ERR
}

# Initialize the accounts in the genesis file
# Globals:
#   None
# Arguments:
#   $1: genesis file
#   $2: keyfile
# Outputs:
#   None
# Returns:
#   None
initialize_accounts() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local genesis=${1}
  local keyfile=${2}
  if [ ! -f ${genesis} ]; then
    echo "Genesis file ${genesis} does not exist."
    trap - ERR
    exit 1
  fi
  if [ ! -f ${keyfile} ]; then
    echo "Keyfile ${keyfile} does not exist."
    trap - ERR
    exit 1
  fi
  # Read the genesis file
  while IFS= read -r line; do
    echo "${line}" # double quotes are important to preserve spaces
    # Check if the line contains the string "alloc"
    if [[ ${line} == *"alloc"* ]]; then
      while IFS= read -r account; do
        address=$(echo ${account} | cut -d: -f1)
        printf "        \"%s\": {\n" ${address}
		    printf "            \"balance\": \"%s\"\n" ${BALANCE}
		    printf "        },\n"
      done < ${keyfile}
    fi
  done < ${genesis} > ${genesis}.tmp
  echo '}' >> ${genesis}.tmp
  # Replace the genesis file
  mv ${genesis}.tmp ${genesis}
  # Remove trap
  trap - ERR
}

# Initialize the nodes with their nodekey, port, and rpc port
# Globals:
#   None
# Arguments:
#   $1: nodefile
#   $2: number of nodes
# Outputs:
#   None
# Returns:
#   None
initialize_nodes() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local nodefile=${1}
  local number_of_nodes=${2}
  if [ ! -f ${nodefile} ]; then
    echo "Nodefile ${nodefile} does not exist."
    trap - ERR
    exit 1
  fi
  if [ -z ${number_of_nodes} ]; then
    echo 'Missing number of nodes.'
    trap - ERR
    exit 1
  fi
  # Initialize nodes
  for i in $(seq 0 $((number_of_nodes - 1))); do
    # Retrieve node port and rpc port from the nodefile
    local node=$(sed -n "$((i+1))p" ${nodefile})
    local node_port=$(echo ${node} | cut -d: -f2)
    local rpc_port=$(echo ${node} | cut -d: -f3)
    local node_port_twin=$(echo ${node} | cut -d: -f4)
    local rpc_port_twin=$(echo ${node} | cut -d: -f5)
    # Copy the nodekey to the node directory and remove the old directory
    cp ${NETWORK_ROOT}/${i}/nodekey ${NETWORK_ROOT}/n${i}/nodekey
    cp ${NETWORK_ROOT}/${i}/nodekey ${NETWORK_ROOT}/n${i}_twin/nodekey
    chmod 644 ${NETWORK_ROOT}/n${i}/nodekey
    chmod 644 ${NETWORK_ROOT}/n${i}_twin/nodekey
    rm -rf ${NETWORK_ROOT}/${i}
    # Add port and rpc port files to the node directory
    echo ${node_port} > ${NETWORK_ROOT}/n${i}/port
    echo ${rpc_port} > ${NETWORK_ROOT}/n${i}/rpcport
    echo ${node_port_twin} > ${NETWORK_ROOT}/n${i}_twin/port
    echo ${rpc_port_twin} > ${NETWORK_ROOT}/n${i}_twin/rpcport
  done
  # Remove trap
  trap - ERR
}

# Generate the configuration files
# Globals:
#   None
# Arguments:
#   $1: nodefile
#   $2: keyfile
# Outputs:
#   None
# Returns:
#   None
generate() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  if [ $# -ne 2 ]; then
    echo "Usage: $0 generate <nodefile> <keyfile>"
    trap - ERR
    exit 1
  fi
  local nodefile=${1}
  local keyfile=${2}
  if [ ! -f ${nodefile} ]; then
    echo "Nodefile ${nodefile} does not exist."
    trap - ERR
    exit 1
  fi
  if [ ! -f ${keyfile} ]; then
    echo "Keyfile ${keyfile} does not exist."
    trap - ERR
    exit 1
  fi
  # Setup environment
  setup_environment
  # Count the number of nodes
  local number_of_nodes=$(wc -l < ${nodefile})
  # prepare network root
  prepare_network_root ${number_of_nodes}
  # run istanbul setup
  (
    cd ${NETWORK_ROOT}
    istanbul setup --num ${number_of_nodes} --nodes --quorum --save --verbose
  )
  set_nodes_ip_port ${NETWORK_ROOT}/static-nodes.json ${nodefile}
  initialize_accounts ${NETWORK_ROOT}/genesis.json ${keyfile}
  initialize_nodes ${nodefile} ${number_of_nodes}
  tar -C ${DEPLOY_ROOT} -czf ${NETWORK_ROOT}.tar.gz 'network'
  rm -rf ${NETWORK_ROOT}
  # Remove trap
  trap - ERR
}

# Finalize the configuration
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
finalize() {
  # Catch errors
  trap 'exit 1' ERR
  # Setup environment
  setup_environment
  local genesis=${DEPLOY_ROOT}/genesis.json
  local static_nodes=${DEPLOY_ROOT}/static-nodes.json
  # Remove network root
  rm -rf ${NETWORK_ROOT}
  # Iterate over all nodes directories
  for dir in ${DEPLOY_ROOT}/n*; do
    # Check that dir is a directory
    if [ ! -d ${dir} ]; then
      continue
    fi
    # Copy the right static-nodes.json file to the node directory
    if [[ ${dir} == *"twin"* ]]; then
      cp ${static_nodes}.twin ${dir}/static-nodes.json
    else
      cp ${static_nodes} ${dir}/static-nodes.json
    fi
    # Initialize the node
    geth --datadir ${dir} init ${genesis} > /dev/null 2>&1
  done
  # Remove the genesis.json and static-nodes.json files
  rm ${genesis} ${static_nodes}*
  # Remove trap
  trap - ERR
}

#===============================================================================
# Main
#===============================================================================

# Read arguments
if [ $# -eq 0 ]; then
  echo "Usage: $0 <action> [options...]"
  exit 1
fi
action=$1; shift

# Catch errors
trap 'exit 1' ERR

utils::ask_sudo
case ${action} in
  'prepare')
    cmd="prepare $@"
    utils::exec_cmd "${cmd}" 'Prepare all hosts'
    ;;
  'generate')
    cmd="generate $@"
    utils::exec_cmd "${cmd}" 'Generate configuration files'
    ;;
  'finalize')
    cmd="finalize $@"
    utils::exec_cmd "${cmd}" 'Finalize configuration'
    ;;
  *)
    echo "Usage: $0 <action> [options...]"
    trap - ERR
    exit 1
    ;;
esac

# Remove trap
trap - ERR
