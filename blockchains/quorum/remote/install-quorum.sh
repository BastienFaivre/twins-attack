#!/bin/bash
#===============================================================================
# Modified by: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Install Quorum blockchain
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/linux/apt/install-quorum
#===============================================================================

#===============================================================================
# IMPORTS
#===============================================================================

. remote/remote.env
. utils/utils.sh

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
  sudo apt-get install -y git make build-essential wget
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

# Clone and build Quorum
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
clone_and_build_quorum() {
  # Catch errors
  trap 'exit 1' ERR
  # Clone and build Quorum
  git clone ${QUORUM_URL} ${INSTALL_ROOT}
  cd ${INSTALL_ROOT}
  git checkout ${QUORUM_BRANCH}
  make all
  # Remove trap
  trap - ERR
}

# Clone and build Istanbul
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
clone_and_build_istanbul() {
  # Catch errors
  trap 'exit 1' ERR
  # Clone and build Istanbul
  git clone ${INSTANBUL_URL} ${INSTALL_ROOT}/istanbul-tools
  cd ${INSTALL_ROOT}/istanbul-tools
  git checkout ${INSTANBUL_BRANCH}
  make
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
utils::exec_cmd 'clone_and_build_quorum' 'Clone and build Quorum'
utils::exec_cmd 'clone_and_build_istanbul' 'Clone and build Istanbul'

# Remove trap
trap - ERR
