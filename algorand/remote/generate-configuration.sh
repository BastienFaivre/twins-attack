#!/bin/bash
#===============================================================================
# Modified by: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: May 2023
# Description: Generate configuration files for Algorand
# Source: https://github.com/Blockchain-Benchmarking/minion/blob/cleanup/script/remote/deploy-algorand-worker
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
    echo 'Algorand is not installed. Please run install-algorand.sh first.'
    trap - ERR
    exit 1
  fi
  # Export bin directories
  export PATH=${PATH}:${HOME}/go/bin
  export PATH=${PATH}:${HOME}/${INSTALL_ROOT}/algorand-tools
  # Check that the geth and istanbul commands are available
  if ! command -v goal &> /dev/null
  then
    utils::err "Goal command not found in /go/bin"
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
  # Create prepare directory
  rm -rf ${PREPARE_ROOT}
  mkdir -p ${PREPARE_ROOT}
  # Remove trap
  trap - ERR
}

function build_network_template() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local path="$1"
  local nodefile="$2"
  local nodenum=$(wc -l < ${nodefile})
  local walletnum=$nodenum
  local share=$(echo "scale=2; 100.0 / $walletnum" | bc)
  local rem=$(echo "scale=2; 100.0 - ($share * $walletnum)" | bc)
  echo "{" > "$path"
  echo '    "Genesis": {' >> "$path"
  echo '        "NetworkName": "PrivateNet",' >> "$path"
  echo '        "Wallets": [' >> "$path"
  local sep=""
  for ((i = 0; i < walletnum; i++)); do
    if [ $i -eq 0 ]; then
      stake=$(echo "scale=2; $share + $rem" | bc)
    else
      stake=$share
    fi
    echo -n "$sep" >> "$path"
    cat << EOF >> "$path"
      {
        "Name": "wallet_$i",
        "Stake": $stake,
        "Online": true
      }
EOF
    sep=','
  done

  echo '        ]' >> "$path"
  echo '    },' >> "$path"
  echo '    "Nodes": [' >> "$path"
  sep=""
  for ((i = 0; i < walletnum; i++)); do
    name="n$i"
    printf "%s" "$sep" >> "$path"
    cat << EOF >> "$path"
    {
      "Name": "$name",
      "IsRelay": true,
      "Wallets": [
        {
          "Name": "wallet_$i",
          "ParticipationOnly": false
        }
      ]
    }
EOF
    sep=","
  done

  echo '    ]' >> "$path"
  echo "}" >> "$path"
  # Remove trap
  trap - ERR
}

# Kill all kmd processes
# Globals:
#   None
# Arguments:
#   $1: network root directory
# Outputs:
#   None
# Returns:
#   None
kill_kmd_processes() {
  # Catch errors
  trap 'exit 1' ERR
  # Kill all kmd processes
  local netroot=${1}
  local datadir pid pids
  for datadir in ${netroot}/n* ${netroot}/c*; do
    pid=$(ps -eo pid,args | grep -v 'grep' | grep 'kmd' \
		  | grep "${datadir}kmd-v" | awk '{print $1}')
    pids+=(${pid})
  done
  if [ ${#pids[@]} -ne 0 ]; then
    kill -TERM ${pids[@]}
  fi
  # Remove trap
  trap - ERR
}

# Set the goal network address
# Globals:
#   None
# Arguments:
#   $1: network root directory
#   $2: nodefile
# Outputs:
#   None
# Returns:
#   None
set_goal_network_address() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local netroot=${1}
  local nodefile=${2}
  local nodenum i peerport clientport
  nodenum=$(wc -l < ${nodefile})
  # Set the goal network address
  for i in $(seq 1 ${nodenum}); do
    peerport=$(sed -n "${i}p" ${nodefile} | cut -d: -f2)
    clientport=$(sed -n "${i}p" ${nodefile} | cut -d: -f3)
    sed -ri 's/"NetAddress":.*/"NetAddress": "'"0.0.0.0:${peerport}"'",/' \
        "${netroot}/n$(( i - 1 ))/config.json"
    sed -ri 's/\{/\{\n\t"ConnectionsRateLimitingWindowSeconds": 0,/' \
        "${netroot}/n$(( i - 1 ))/config.json"
    sed -ri 's/\{/\{\n\t"EndpointAddress": "'":${clientport}"'",/' \
        "${netroot}/n$(( i - 1 ))/config.json"
    sed -ri 's/\{/\{\n\t"EnableDeveloperAPI": true,/' \
        "${netroot}/n$(( i - 1 ))/config.json"
  done
  # Remove trap
  trap - ERR
}

# Generate full and client nodes start script
# Globals:
#   None
# Arguments:
#   $1: network root directory
#   $2: nodefile
# Outputs:
#   None
# Returns:
#   None
generate_start_scripts() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local netroot=${1}
  local nodefile=${2}
  local nodenum i addr peers sep
  nodenum=$(wc -l < ${nodefile})
  sep=''
  # Generate full and client nodes start script
  for i in $(seq 1 ${nodenum}); do
    (
      echo "#!/bin/bash"
      if [ "x${peers}" = 'x' ]; then
        echo 'exec goal node start --datadir "${0%/*}"'
      else
        echo 'exec goal node start --datadir "${0%/*}" --peer' \
        "'${peers}'"
      fi
    ) > "${netroot}/n$(( i - 1 ))/start.sh"
    chmod +x "${netroot}/n$(( i - 1 ))/start.sh"
    addr=$(sed -n "${i}p" ${nodefile} | cut -d: -f1,2)
    peers="${peers}${sep}${addr}"
    sep=';'
  done
  # Remove trap
  trap - ERR
}

# Generate an Algorand token for each node
# Globals:
#   None
# Arguments:
#   $1: network root directory
#   $2: nodefile
# Outputs:
#   None
# Returns:
#   None
generate_algod_tokens() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local netroot=${1}
  local nodefile=${2}
  local nodenum clientnum i token path
  nodenum=$(wc -l < ${nodefile})
  token='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  # Generate an Algorand token for each node
  for i in $(seq 1 ${nodenum}); do
    path="${netroot}/n$(( i - 1 ))/algod.token"
    printf "%s" "${token}" > "${path}"
  done
  # Remove trap
  trap - ERR
}

# Generate the extra config containing the account addresses and mnemonics
# Globals:
#   None
# Arguments:
#   $1: network root directory
#   $2: nodefile
# Outputs:
#   None
# Returns:
#   None
generate_chainconfig() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local netroot=${1}
  local nodefile=${2}
  local nodenum
  nodenum=$(wc -l < ${nodefile})
  # Generate the extra config containing the account addresses and mnemonics
  algorand-chainfile-generator "${netroot}" "${nodenum}" "${netroot}/accounts.yaml"
  # Remove trap
  trap - ERR
}

generate_accounts() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  local netroot=${1}
  local accountnum=${2}
  mkdir -p "${netroot}/accounts"
  # Generate accounts
  for i in $(seq 1 ${accountnum}); do
    wallet_output=$(algokey generate)
    private_key=$(echo "$wallet_output" | grep "Private key mnemonic" | cut -d ':' -f 2- | xargs)
    public_key=$(echo "$wallet_output" | grep "Public key" | cut -d ':' -f 2 | xargs)
    echo "${private_key}" > "${netroot}/accounts/account-$(( i - 1 )).sk"
    echo "${public_key}" > "${netroot}/accounts/account-$(( i - 1 )).pk"
  done
  find "${netroot}" -type f -name "genesis.json" | while read -r filepath; do
    genesis=$(cat "${filepath}")
    echo "Adding accounts to genesis file $filepath"
    find "${netroot}/accounts" -type f -name "account-*.pk" | while read -r pubkey_file; do
      echo "Adding account $pubkey_file to genesis"
      pubkey=$(cat "${pubkey_file}")
      jq ".alloc += [
    {
      "addr": \"${pubkey}\",
      "comment": \"wallet_${pubkey}\",
      "state": {
        "algo": 1000000000000000,
        "onl": 1
      }
    }
  ]"  <<< "$genesis" > "$filepath"
    genesis=$(cat "${filepath}")
    done
  done
  # Remove trap
  trap - ERR
}




generate() {
  # Catch errors
  trap 'exit 1' ERR
  # Retrieve arguments
  if [ $# -ne 2 ]; then
    echo "Usage: $0 generate <nodefile> <account number>"
    trap - ERR
    exit 1
  fi
  local nodefile=${1}
  local accountnum=${2}
  local template=${DEPLOY_ROOT}/template.json
  local logfile=${DEPLOY_ROOT}/generate.log
  local netroot=${NETWORK_ROOT}
  setup_environment
  if ! build_network_template ${template} ${nodefile} > ${logfile} 2>&1; then
    cat ${logfile}
    utils::err 'Failed to build network template'
    trap - ERR
    exit 1
  fi
  rm -rf ${netroot}
  local nodenum=$(wc -l < ${nodefile})
  local prepared_path=${PREPARE_ROOT}/network-${nodenum}
  if [ ! -e ${prepared_path} ]; then
    echo ${prepared_path}
    echo ${template}
    if ! goal network create --rootdir ${prepared_path} --network 'private' \
      --template ${template} > ${logfile} 2>&1; then
      cat ${logfile}
      utils::err 'Failed to create network'
      trap - ERR
      exit 1
    fi
    rm ${template}
    kill_kmd_processes ${prepared_path}
    generate_chainconfig ${prepared_path} ${nodefile}
    generate_algod_tokens ${prepared_path} ${nodefile}
    rm ${prepared_path}/genesis.json
    rm ${prepared_path}/network.json
    rm ${prepared_path}/*.rootkey*
    rm ${prepared_path}/*.partkey*
  fi
  cp -r ${prepared_path} ${netroot}
  set_goal_network_address ${netroot} ${nodefile}
  generate_start_scripts ${netroot} ${nodefile}
  generate_accounts ${netroot} ${accountnum}
  tar -C ${DEPLOY_ROOT} -czf ${netroot}.tar.gz 'network'
  rm -rf ${netroot}
  rm -rf ${prepared_path}
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
  *)
    echo "Usage: $0 <action> [options...]"
    trap - ERR
    exit 1
    ;;
esac

# Remove trap
trap - ERR
