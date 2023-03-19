#!/bin/bash

# Author: Bastien Faivre
# Project: EPFL Master Semester Project
# Description: This script initialize the proxy with the basic configuration.

go build

echo "Initialize proxy"

./controller 127.0.0.1:9000 change-flow destination-nodes 127.0.0.1:8022 127.0.0.1:8122 response-node 127.0.0.1:8022
echo "Configuration sent"

rm controller
