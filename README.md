# Twins Attack

## Overview

This repository contains the code to set up and simulate a twin attack on various blockchains. The attack is described in my [paper](https://github.com/BastienFaivre/twins-attack/blob/main/paper.pdf).

### Current Blockchains

- Quorum (IBFT)
- Algorand

## Setup

1. Export necessary scripts on remote machines. Execute

    ```bash
    ./scripts/local/export.sh
    ```

    Note that this script assume the remote machines to be under the same hostname but different ports (see the [config file](https://github.com/BastienFaivre/twins-attack/blob/main/scripts/local/local.env)). If your setup is different, you might need to modify the script accordingly.

2. Blockchain initialisation and start

   - Quorum:

       ```bash
       # Install Quorum on remote machines
       ./blockchains/quorum/local/install-quorum.sh
       # Generate Quorum configuration files (executed on a single machine)
       ./blockchains/quorum/local/generate-configuration.sh
       # Generate accounts for Quorum (executed on a single machine)
       ./blockchains/quorum/local/generate-accounts.sh <number of accounts> 
       # Import accounts on remote machines nodes (for attack visualization purposes)
       ./blockchains/quorum/local/import-accounts.sh 
       # Start Quorum twins chains on remote machines
       ./blockchains/quorum/local/quorum-ibft start twins 
       ```

   - Algorand:

       ```bash
       # Install Algorand on remote machines
       ./blockchains/algorand/local/install-algorand.sh
       # Generate Algorand configuration files (executed on a single machine)
       ./blockchains/algorand/local/generate-configuration.sh <number of accounts> 
       # Start Algorand twins chains on remote machines
       ./blockchains/algorand/local/algorand start twins 
       ```

3. Evil twin setup

    On one of the remote machines, start the evil proxy that links two twins nodes of the two blockchains:

    ```bash
    cd go/src/proxy
    go build .
    ./proxy <hostname> <client port> <configuration port>
    ```

    Then, initialize the proxy configuration by executing the controller:

    ```bash
    cd go/src/controller
    go build .
    ./controller <proxy hostname:port> change-flow destination-nodes <node 1 hostname:port> <node 2 hostname:port> response-node <node 2 hostname:port>
    ```

    Note that this setup assume the blockchains whose node 2 is part of to be the evil twin.

4. Attack execution

    To be completed...
