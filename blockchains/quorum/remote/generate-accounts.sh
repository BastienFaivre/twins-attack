#!/bin/bash
#===============================================================================
# Modified by: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Generates Ethereum accounts
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/linux/apt/install-geth-accounts-worker
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

# Install the necessary packages
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
install_necessary_packages() {
  # Catch errors
  trap 'exit 1' ERR
  # Install packages
  sudo apt-get update
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository -y ppa:ethereum/ethereum
  sudo apt-get update
  sudo apt-get install -y python3 python3-pip
  sudo pip3 install web3
  # Remove trap
  trap - ERR
}

# Initialize the necessary directories
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
initialize_directories() {
  # Catch errors
  trap 'exit 1' ERR
  # Initialize directories
  mkdir -p ${INSTALL_FOLDER}
  rm -rf ${ACCOUNTS_ROOT}/*
  mkdir -p ${ACCOUNTS_ROOT}
  # Remove trap
  trap - ERR
}

# generate accounts
# Globals:
#   None
# Arguments:
#   $1: number of accounts to generate
# Outputs:
#   None
# Returns:
#   None
generate_accounts() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local number_of_accounts=${1}
  if [ -z ${number_of_accounts} ]; then
    utils::err 'Missing number of accounts to generate'
    trap - ERR
    exit 1
  fi
  # Get batch size
  local batch=$(cat '/proc/cpuinfo' | grep processor | wc -l)
  # Generate accounts
  total=0
  while [ ${total} -lt ${number_of_accounts} ]; do
    len=$((number_of_accounts - total))
    if [ ${len} -gt ${batch} ]; then
      len=${batch}
    fi
    upto=$((total + len - 1))
    for i in $(seq ${total} ${upto}); do
      (
        mkdir -p ${ACCOUNTS_ROOT}/${i}
        printf "%d\n%d\n" ${i} ${i} | geth --datadir ${ACCOUNTS_ROOT}/${i} account new > /dev/null 2>&1
        local keypath=$(ls -1 ${ACCOUNTS_ROOT}/${i}/keystore | head -n 1)
        keypath=${ACCOUNTS_ROOT}/${i}/keystore/${keypath}
        local address=${keypath##*--}
        echo ${address} > ${ACCOUNTS_ROOT}/${i}/address
        ./remote/extract.py ${keypath} ${i} > ${ACCOUNTS_ROOT}/${i}/private
        rm -rf ${ACCOUNTS_ROOT}/${i}/keystore
      ) &
    done
    wait
    total=$((total + len))
  done
  # Gather addresses and private keys in a single file
  for i in $(seq 0 $((number_of_accounts - 1))); do
    local address=$(cat ${ACCOUNTS_ROOT}/${i}/address)
    local private=$(cat ${ACCOUNTS_ROOT}/${i}/private)
    echo ${address}:${private} >> ${ACCOUNTS_ROOT}/accounts.txt
  done
  # Remove trap
  trap - ERR
}

#===============================================================================
# MAIN
#===============================================================================

# Read arguments
if [ $# -ne 1 ]; then
  echo "Usage: ${0} <number of accounts>"
  exit 1
fi
number_of_accounts=${1}

# Catch errors
trap 'exit 1' ERR

utils::ask_sudo
setup_environment
utils::exec_cmd 'install_necessary_packages' 'Install necessary packages'
utils::exec_cmd 'initialize_directories' 'Initialize directories'
cmd="generate_accounts ${number_of_accounts}"
utils::exec_cmd "${cmd}" 'Generate accounts'

# Remove trap
trap - ERR
