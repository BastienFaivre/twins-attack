#!/bin/bash
# Install Quorum blockchain
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/linux/apt/install-quorum

# read environment file
. remote/remote.env

# import utility functions
. remote/utils/utils.sh

utils::ask_sudo

install_necessary_packages() {
  sudo apt-get update
  sudo apt-get install -y git make build-essential wget
}

install_go() {
  wget $GO_URL > /dev/null 2>&1
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf ${GO_URL##*/}
  rm ${GO_URL##*/}
  # export in .bashrc if not already there
  if ! grep ~/.profile -e $GO_PATH &> /dev/null
  then
    echo "export PATH=\$PATH:$GO_PATH" >> ~/.profile
  fi
  source ~/.profile
  if ! command -v go &> /dev/null
  then
    utils::err 'Go command not found after installation'
    exit 1
  fi
}

# create install directory and remove old quorum directory
initialize_directories() {
  mkdir -p $INSTALL_FOLDER
  rm -rf $INSTALL_ROOT
}

# clone quorum and build
clone_and_build_quorum() {
  git clone $QUORUM_URL $INSTALL_ROOT
  cd $INSTALL_ROOT
  git checkout $QUORUM_BRANCH
  make all
}

# clone istanbul and build
clone_and_build_istanbul() {
  git clone $INSTANBUL_URL $INSTALL_ROOT/istanbul-tools
  cd $INSTALL_ROOT/istanbul-tools
  git checkout $INSTANBUL_BRANCH
  make
}

trap "echo 'Aborting...'; exit 1" ERR
utils::exec_cmd 'install_necessary_packages' 'Install necessary packages'
if ! command -v go &> /dev/null
then
  utils::exec_cmd 'install_go' 'Install Go'
  source ~/.profile
  if ! command -v go &> /dev/null
  then
    utils::err 'Go command not found after installation'
    exit 1
  fi
fi
utils::exec_cmd 'initialize_directories' 'Initialize directories'
utils::exec_cmd 'clone_and_build_quorum' 'Clone and build Quorum'
utils::exec_cmd 'clone_and_build_istanbul' 'Clone and build Istanbul'
trap - ERR
