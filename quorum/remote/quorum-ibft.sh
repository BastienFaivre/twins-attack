#!/bin/bash
# Start or stop the quorum nodes present in the remote host
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/quorum-ibft

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

start() {
  export PRIVATE_CONFIG=ignore
  # start the nodes
  for dir in $DEPLOY_ROOT/n*; do
    # check that dir is a directory
    if [ ! -d "$dir" ]; then
    continue
    fi
    # retrieve node port and rpc port
    port=$(cat $dir/port)
    rpcport=$(cat $dir/rpcport)
    # verify the ports
    if [ -z "$port" ] || [ -z "$rpcport" ]; then
      utils::err "Could not retrieve port or rpc port for node $dir"
      exit 1
    fi
    # start the node
    geth --datadir $dir \
      --allow-insecure-unlock \
      --nodiscover \
      --istanbul.blockperiod 5 \
      --syncmode full \
      --mine \
      --miner.threads 1 \
      --verbosity 2 \
      --networkid 10 \
      --ws \
      --ws.addr 0.0.0.0 \
      --ws.port $rpcport \
      --ws.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
      --ws.origins "*" \
      --emitcheckpoints \
      --port $port \
      --http \
      --http.port $rpcport \
      > $dir/out.log 2> $dir/err.log &
    pid=$!
    echo $pid > $dir/pid
  done
  # make sure that the nodes are started and connected
  sleep 5
}

_kill() {
  # read argument
  local sig="${1}"
  # kill the nodes
  for dir in $DEPLOY_ROOT/n*; do
    # check that dir is a directory
    if [ ! -d "$dir" ]; then
      continue
    fi
    # retrieve pid
    if [ ! -f "$dir/pid" ]; then
      continue
    fi
    pid=$(cat $dir/pid)
    # kill the node
    kill $sig $pid
    # remove pid file
    rm $dir/pid
  done
}

stop() {
  _kill -SIGINT
}

nkill() {
  _kill -SIGKILL
}

setup_environment

# read argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 start|stop|kill"
  exit 1
fi
action=$1; shift

case $action in
  start)
    utils::exec_cmd start "Start all nodes"
    ;;
  stop)
    utils::exec_cmd stop "Stop all nodes"
    ;;
  kill)
    utils::exec_cmd nkill "Kill all nodes"
    ;;
  *)
    echo "Usage: $0 start|stop|kill"
    exit 1
    ;;
esac
