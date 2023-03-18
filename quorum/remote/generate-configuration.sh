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

# prepare all hosts by creating the deploy directory
prepare() {
  # check that no more arguments are provided
  if [ $# -ne 0 ]; then
    echo "Usage: $0 prepare"
    exit 1
  fi
  # check that the installation has been completed
  setup_environment
  # create deploy directory
  if [ -d "$DEPLOY_ROOT" ]; then
    rm -rf $DEPLOY_ROOT
  fi
  mkdir -p $DEPLOY_ROOT
}

# prepare the network root directory and create a directory for each node
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

# set the ip and port of each node in the static-nodes.json file
set_nodes_ip_port() {
  # retrieve arguments
  local static_nodes_file="${1}"
  local nodefile="${2}"
  # create a temporary file
  local index=1
  # read the static-nodes.json file
  while IFS= read -r line; do
    # check if the line contains the string "enode"
    if [[ ! $line == *"enode"* ]]; then
      echo "$line"
      continue
    fi
    # retrieve node ip and port from the nodefile
    local node=$(sed -n "${index}p" $nodefile)
    local node_ip=$(echo $node | cut -d: -f1)
    local node_port=$(echo $node | cut -d: -f2)
    # replace the ip and port in the enode uri
    local new_line=$(echo $line | sed "s/@.*?/@$node_ip:$node_port?/")
    echo "$new_line"
    # increment the index
    index=$((index + 1))
  done < $static_nodes_file > "$static_nodes_file.tmp"
  echo ']' >> "$static_nodes_file.tmp"
  # replace the static-nodes.json file
  mv "$static_nodes_file.tmp" $static_nodes_file
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
    # copy the nodekey to the node directory and remove the old directory
    cp $NETWORK_ROOT/$i/nodekey $NETWORK_ROOT/n$i/nodekey
    chmod 644 $NETWORK_ROOT/n$i/nodekey
    rm -rf $NETWORK_ROOT/$i
    # add port and rpc port files to the node directory
    echo $node_port > $NETWORK_ROOT/n$i/port
    echo $rpc_port > $NETWORK_ROOT/n$i/rpcport
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
    # copy the static-nodes.json file to the node directory
    cp $static_nodes $dir/static-nodes.json
    # initialize the node
    geth --datadir $dir init $genesis > /dev/null 2>&1
  done
  # remove the genesis.json and static-nodes.json files
  rm $genesis $static_nodes
}

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
