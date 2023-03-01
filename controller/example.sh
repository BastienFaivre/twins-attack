#!/bin/bash

# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Description: This file contains an example of a script that execute an certain
# scenario for the proxy using the controller to send new configuration to the
# proxy.

# countdown
# source: https://superuser.com/questions/611538/is-there-a-way-to-display-a-countdown-or-stopwatch-timer-in-a-terminal
countdown() {
  start="$(( $(date '+%s') + $1))"
  while [ $start -ge $(date +%s) ]; do
    time="$(( $start - $(date +%s) ))"
    printf '%s\r' "$(date -u -d "@$time" +%H:%M:%S)"
    sleep 0.1
  done
}

# build the controller
go build

# start scenario
echo "Starting scenario"

./controller 127.0.0.1:9000 change-flow destination-nodes 127.0.0.1:8001 127.0.0.1:8002 response-node 127.0.0.1:8001
echo "Configuration sent"
countdown 10
./controller 127.0.0.1:9000 change-flow destination-nodes 127.0.0.1:8001 response-node 127.0.0.1:8001
echo "Configuration sent"
countdown 10
./controller 127.0.0.1:9000 change-flow destination-nodes 127.0.0.1:8002 response-node
echo "Configuration sent"
countdown 10
./controller 127.0.0.1:9000 change-flow destination-nodes 127.0.0.1:8001 127.0.0.1:8002 response-node 127.0.0.1:8002
echo "Configuration sent"
countdown 10
# send an invalid confirguration for debugging purpose
./controller 127.0.0.1:9000 change-flow destination-nodes 127.0.0.1:8001 response-node 127.0.0.1:8002
echo "Configuration sent"
countdown 10
# resend a valid configuration
./controller 127.0.0.1:9000 change-flow destination-nodes 127.0.0.1:8001 127.0.0.1:8002 response-node 127.0.0.1:8001
echo "Configuration sent"

# stop scenario
echo "Stopping scenario"

# remove the controller build
rm controller
