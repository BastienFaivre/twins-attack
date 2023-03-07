#!/bin/bash
# Install Quorum blockchain
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/linux/apt/install-quorum

# import utility functions
. remote/utils/utils.sh

QUORUM_URL='https://github.com/Consensys/quorum.git'
QUORUM_BRANCH='919800f019cc5d2b931b5cd81600640a8e7cd444'
INSTANBUL_URL='https://github.com/ConsenSys/istanbul-tools.git'
INSTANBUL_BRANCH='1b927b94fff0b24ab683dc76ab73ada5d283c0bb'

utils::ask_sudo

install-necessary-packages() {
  sudo apt-get update
  sudo apt-get install -y git make build-essential wget
}

install-go() {
  wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz > /dev/null 2>&1
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz
  rm go1.20.1.linux-amd64.tar.gz
  # export in .bashrc if not already there
  if ! grep ~/.profile -e "/usr/local/go/bin"
  then
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
  fi
  source ~/.profile
  if ! command -v go &> /dev/null
  then
    utils::err "Go command not found after installation"
    exit 1
  fi
}

# create install directory and remove old quorum directory
initialize-directories() {
  mkdir -p install
  rm -rf install/quorum
}

# clone quorum and build
clone-and-build-quorum() {
  git clone $QUORUM_URL install/quorum
  cd install/quorum
  git checkout $QUORUM_BRANCH
  make all
}

# clone istanbul and build
clone-and-build-istanbul() {
  git clone $INSTANBUL_URL install/quorum/istanbul-tools
  cd install/quorum/istanbul-tools
  git checkout $INSTANBUL_BRANCH
  make
}

trap 'echo "Aborting..."; exit 1' ERR
utils::exec_cmd "install-necessary-packages" "Install necessary packages"
if ! command -v go &> /dev/null
then
  utils::exec_cmd "install-go" "Install Go"
  source ~/.profile
fi
utils::exec_cmd "initialize-directories" "Initialize directories"
utils::exec_cmd "clone-and-build-quorum" "Clone and build Quorum"
utils::exec_cmd "clone-and-build-istanbul" "Clone and build Istanbul"
trap - ERR
