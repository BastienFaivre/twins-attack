#!/bin/bash
# Generates accounts with initial balance
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/linux/apt/install-geth-accounts-worker

# read environment file
. remote/remote.env

# import utility functions
. remote/utils/utils.sh

utils::ask_sudo

# check that the installation has been completed
setup_environment() {
  # check that quorum is installed
  if [ ! -d "$INSTALL_ROOT" ]; then
    echo 'Quorum is not installed. Please run install_quorum.sh first.'
    exit 1
  fi
  # export bin directories
  export PATH="$PATH:$HOME/$INSTALL_ROOT/build/bin"
  export PATH="$PATH:$HOME/$INSTALL_ROOT/istanbul-tools/build/bin"
  # check that the geth and istanbul commands are available
  if ! command -v geth &> /dev/null
  then
    utils::err "Geth command not found in $INSTALL_ROOT/build/bin"
    exit 1
  fi
  if ! command -v istanbul &> /dev/null
  then
    utils::err "Istanbul command not found in $INSTALL_ROOT/istanbul-tools/build/bin"
    exit 1
  fi
}

# install necessary packages
install_necessary_packages() {
  sudo apt-get update
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository -y ppa:ethereum/ethereum
  sudo apt-get update
  sudo apt-get install -y python3 python3-pip
  sudo pip3 install web3
}

# create install directory and empty accounts directory
initialize_directories() {
  mkdir -p $INSTALL_FOLDER
  if [ -d "$ACCOUNTS_ROOT" ]; then
    rm -rf $ACCOUNTS_ROOT/*
  else
    mkdir -p $ACCOUNTS_ROOT
  fi
}

# generate accounts
generate_accounts() {
  # retrieve arguments
  local number_of_accounts="${1}"
  # get batch size
  local batch=$(cat '/proc/cpuinfo' | grep processor | wc -l)
  # generate accounts
  total=0
  while [ $total -lt $number_of_accounts ]; do
    len=$((number_of_accounts - total))
    if [ $len -gt $batch ]; then
      len=$batch
    fi
    upto=$((total + len - 1))
    for i in $(seq $total $upto); do
      (
        mkdir -p $ACCOUNTS_ROOT/$i
        printf "%d\n%d\n" $i $i | geth --datadir $ACCOUNTS_ROOT/$i account new > /dev/null 2>&1
        local keypath=$(ls -1 $ACCOUNTS_ROOT/$i/keystore | head -n 1)
        keypath=$ACCOUNTS_ROOT/$i/keystore/$keypath
        local address=${keypath##*--}
        echo $address > $ACCOUNTS_ROOT/$i/address
        ./remote/extract.py $keypath $i > $ACCOUNTS_ROOT/$i/private
        rm -rf $ACCOUNTS_ROOT/$i/keystore
      ) &
    done
    wait
    total=$((total + len))
  done
  # gather addresses and private keys in a single file
  for i in $(seq 0 $((number_of_accounts - 1))); do
    local address=$(cat $ACCOUNTS_ROOT/$i/address)
    local private=$(cat $ACCOUNTS_ROOT/$i/private)
    echo "$address:$private" >> $ACCOUNTS_ROOT/accounts.txt
  done
}

setup_environment

# read argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <number of accounts>"
  exit 1
fi
number_of_accounts=$1

# install necessary packages
utils::exec_cmd 'install_necessary_packages' 'Install necessary packages'
# initialize directories
utils::exec_cmd 'initialize_directories' 'Initialize directories'
# generate accounts
cmd="generate_accounts $number_of_accounts"
utils::exec_cmd "$cmd" 'Generate accounts'
