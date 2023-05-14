#!/bin/bash
#===============================================================================
# Modified by: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: May 2023
# Description: Install Algorand blockchain
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/linux/apt/install-algorand
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. blockchains/algorand/remote/remote.env
. scripts/utils.sh

#===============================================================================
# FUNCTIONS
#===============================================================================

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
  sudo apt-get install -y git make python3 python3-pip wget libtool-bin libboost-all-dev jq
  # Remove trap
  trap - ERR
}

# Install Go
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
install_go() {
  # Catch errors
  trap 'exit 1' ERR
  # Install Go
  wget ${GO_URL} > /dev/null 2>&1
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf ${GO_URL##*/}
  rm ${GO_URL##*/}
  # Export in .profile if not already there
  if ! grep ~/.profile -e ${GO_PATH} &> /dev/null
  then
    echo "export PATH=\$PATH:${GO_PATH}" >> ~/.profile
  fi
  source ~/.profile
  if ! command -v go &> /dev/null
  then
    utils::err 'Go command not found after installation'
    trap - ERR
    exit 1
  fi
  # Remove trap
  trap - ERR
}

# Initialize directories
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
  rm -rf ${INSTALL_ROOT}
  # Remove trap
  trap - ERR
}

# Clone and build Algorand
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
clone_and_build_algorand() {
  # Catch errors
  trap 'exit 1' ERR
  # Clone and build Algorand
  git clone ${ALGORAND_URL} ${INSTALL_ROOT}
  (
    cd ${INSTALL_ROOT}
    git checkout ${ALGORAND_BRANCH}
    sudo --non-interactive --preserve-env='PATH' ./scripts/configure_dev.sh
    make install
  )
  pip3 install pyteal
  mkdir ${INSTALL_ROOT}/algorand-tools
  (
    cd ${INSTALL_ROOT}/algorand-tools
    cp ~/blockchains/algorand/remote/main.go .
    go mod init "algorand-chainfile-generator"
    go mod tidy
    go build -o algorand-chainfile-generator
  )
  # Remove trap
  trap - ERR
}

#===============================================================================
# MAIN
#===============================================================================

# Catch errors
trap 'exit 1' ERR

utils::ask_sudo
utils::exec_cmd 'install_necessary_packages' 'Install necessary packages'
if ! command -v go &> /dev/null
then
  utils::exec_cmd 'install_go' 'Install Go'
  source ~/.profile
  if ! command -v go &> /dev/null
  then
    utils::err 'Go command not found after installation'
    trap - ERR
    exit 1
  fi
fi
utils::exec_cmd 'initialize_directories' 'Initialize directories'
utils::exec_cmd 'clone_and_build_algorand' 'Clone and build Algorand'

# Remove trap
trap - ERR
