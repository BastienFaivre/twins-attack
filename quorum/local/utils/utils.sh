#!/bin/bash
#===============================================================================
# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Date: March 2023
# Description: Define a set of utility functions
# Source: https://github.com/BastienFaivre/bash-scripts/blob/main/utils/utils.sh
#===============================================================================

#######################################
# Show an error
# Globals:
#   None
# Arguments:
#   $*: messages to display
# Outputs:
#   Writes error to stderr
# Returns:
#   None
# Sources:
#   https://google.github.io/styleguide/shellguide.html#stdout-vs-stderr
#######################################
utils::err() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] \033[0;31mERROR:\033[0m $*" >&2
}

#######################################
# Ask for sudo
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes error to stderr if sudo refused
# Returns:
#   None
#######################################
utils::ask_sudo() {
  # Ask for super user
  sudo -v > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    utils::err "You need to be root to run this script."
    exit 1
  fi
}

#######################################
# Execute a command while displaying a loader
# Globals:
#   None
# Arguments:
#   $1: command to execute
#   $2: command explanation
# Outputs:
#   Writes loader and command explanation to stdout
# Returns:
#   1 if the command failed, 0 otherwise
#######################################
utils::exec_cmd() {
  # retrieve arguments
  local cmd="${1}"
  local cmd_explanation="${2}"
  # check if a command is provided
  if [[ -z "${cmd}" ]]; then
    utils::err 'function exec_cmd(): No command provided.'
    exit 1
  fi
  # execute the command in background and redirect output to log file
  ${cmd} > /tmp/log.txt 2> /tmp/log.txt &
  # display loader while command is running
  local pid=$!
  local i=1
  local sp='⣾⣽⣻⢿⡿⣟⣯⣷'
  trap 'kill ${pid} 2 > /dev/null' EXIT
  while kill -0 ${pid} 2> /dev/null; do
    echo -ne "\r${sp:i++%${#sp}:1} ${cmd_explanation}"
    sleep 0.1
  done
  wait ${pid}
  # check is the command succeeded
  if [ "$?" -ne 0 ]; then
    echo -ne "\r\033[0;31mFAIL\033[0m ${cmd_explanation}\n"
    # display log file
    cat /tmp/log.txt
    # remove log file
    rm /tmp/log.txt
    trap - EXIT
    return 1
  else
    echo -ne "\r\033[0;32mDONE\033[0m ${cmd_explanation}\n"
    # remove log file
    rm /tmp/log.txt
    trap - EXIT
    return 0
  fi
}

#######################################
# Create list of remote hosts
# Globals:
#   None
# Arguments:
#   $1: hostname
#   $2: starting port
#   $3: number of hosts
# Outputs:
#   None
# Returns:
#   The list of remote hosts
#######################################
utils::create_remote_hosts_list() {
  # retrieve arguments
  local hostname="${1}"
  local starting_port="${2}"
  local number_of_hosts="${3}"
  # check if a hostname is provided
  if [[ -z "${hostname}" ]]; then
    utils::err 'function create_remote_hosts_list(): No hostname provided.'
    exit 1
  fi
  # check if a starting port is provided
  if [[ -z "${starting_port}" ]]; then
    utils::err 'function create_remote_hosts_list(): No starting port provided.'
    exit 1
  fi
  # check if a number of hosts is provided
  if [[ -z "${number_of_hosts}" ]]; then
    utils::err 'function create_remote_hosts_list(): No number of hosts provided.'
    exit 1
  fi
  # create list of remote hosts
  local remote_hosts_list=""
  for i in $(seq 0 $((number_of_hosts - 1)))
  do
    remote_hosts_list="${remote_hosts_list} ${hostname}:$((starting_port + i))"
  done
  echo "${remote_hosts_list}"
}

#######################################
# Execute a command on all remote hosts in parallel while displaying a loader
# Globals:
#   None
# Arguments:
#   $1: command to execute
#   $2: command explanation
#   $3: array of remote hosts
# Outputs:
#   Writes loader and command explanation to stdout
# Returns:
#   1 if the command failed, 0 otherwise
#######################################
utils::exec_cmd_on_remote_hosts() {
  # retrieve arguments
  local cmd="${1}"
  local cmd_explanation="${2}"
  local remote_hosts=("${@:3}")
  # check if a command is provided
  if [[ -z "${cmd}" ]]; then
    utils::err 'function exec_cmd_on_remote_hosts(): No command provided.'
    exit 1
  fi
  # check if a command explanation is provided
  if [[ -z "${cmd_explanation}" ]]; then
    utils::err 'function exec_cmd_on_remote_hosts(): No command explanation provided.'
    exit 1
  fi
  # check if remote hosts are provided
  if [[ -z "${remote_hosts}" ]]; then
    utils::err 'function exec_cmd_on_remote_hosts(): No remote hosts provided.'
    exit 1
  fi
  # execute the command in background and redirect output to log file
  array_of_pids=()
  index=0
  for remote_host in "${remote_hosts[@]}"
  do
    # split remote host into hostname and port
    IFS=':' read -r -a remote_host_array <<< "${remote_host}"
    {
      local res
      res=$(ssh -p ${remote_host_array[1]} ${remote_host_array[0]} "${cmd}" > /tmp/log_${remote_host_array[0]}_${remote_host_array[1]}.txt 2> /tmp/log_${remote_host_array[0]}_${remote_host_array[1]}.txt)
      if [ "$?" -ne 0 ]; then
        exit 1
      fi
    } &
    array_of_pids[${index}]=$!
    index=$((index + 1))
  done
  # display loader while command is running
  local i=1
  local sp='⣾⣽⣻⢿⡿⣟⣯⣷'
  trap 'kill ${array_of_pids[@]} 2 > /dev/null' EXIT
  for pid in "${array_of_pids[@]}"
  do
    while kill -0 ${pid} 2> /dev/null; do
      echo -ne "\r${sp:i++%${#sp}:1} ${cmd_explanation}"
      sleep 0.1
    done
  done
  # reset output
  echo -ne "\r"
  # check if the command succeeded
  fail=0
  index=0
  for pid in "${array_of_pids[@]}"
  do
    wait ${pid}
    if [ "$?" -ne 0 ]; then
      # split remote host into hostname and port
      IFS=':' read -r -a remote_host_array <<< "${remote_host}"
      # display log file
      echo -e "\033[0;31mFAIL\033[0m ${cmd_explanation} on ${remote_host_array[0]}:${remote_host_array[1]}"
      cat /tmp/log_${remote_host_array[0]}_${remote_host_array[1]}.txt
      fail=1
    fi
  done
  # remove log files
  rm /tmp/log_*.txt
  # check is the command succeeded
  if [ "${fail}" -ne 0 ]; then
    echo -ne "\r\033[0;31mFAIL\033[0m ${cmd_explanation}\n"
    trap - EXIT
    return 1
  else
    echo -ne "\r\033[0;32mDONE\033[0m ${cmd_explanation}\n"
    trap - EXIT
    return 0
  fi
}
