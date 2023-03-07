#!/bin/bash
# Generate configuration files for Quorum
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/deploy-quorum-ibft-worker

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

prepare() {
  # check that no more arguments are provided
  if [ $# -ne 0 ]; then
    echo "Usage: $0 prepare"
    exit 1
  fi
  # check that the installation has been completed
  setup_environment
  # create deploy directory
  mkdir -p $DEPLOY_ROOT
}

prepare_network_root() {
  # retrieve arguments
  local number_of_nodes="${1}"
  # remove network root if it exists and create it
  if [ -d "$NETWORK_ROOT" ]; then
    rm -rf $NETWORK_ROOT
  fi
  mkdir $NETWORK_ROOT
  # create a directory for each node
  for i in $(seq 0 $((number_of_nodes - 1))); do
    mkdir $NETWORK_ROOT/n$i
  done
}

set_nodes_ip_port() {
  # retrieve arguments
  local static_nodes_file="${1}"
  local nodefile="${2}"
  # create a temporary file
  local tmp_file="$static_nodes_file.tmp"
  index=1
  # read the static-nodes.json file
  while IFS= read -r line; do
    # skip if the line is empty or it is not an enode uri
    if [[ -z "$line" ]] || [[ ! "$line" =~ ^enode://.* ]]; then
      echo "oui" >> $tmp_file
      continue
    fi
    # retrieve node ip and port from the nodefile
    local node=$(sed -n "${index}p" $nodefile)
    local node_ip=$(echo $node | cut -d: -f1)
    local node_port=$(echo $node | cut -d: -f2)
    # replace the ip and port in the enode uri
    echo "$node_ip:$node_port\n" >> $tmp_file
    index=$((index + 1))
    done < $static_nodes_file
    # replace the static-nodes.json file
    mv $tmp_file "$static_nodes_file.tmp"
}

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
}

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
  *)
    echo "Usage: $0 <action> [options...]"
    exit 1
    ;;
esac
