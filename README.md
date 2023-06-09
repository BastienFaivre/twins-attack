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

    - Quorum:

        Initiate a Geth connection to a node of one node of one of the blockchains, then execute a transaction from Alice to Bob (in other words, from one wallet to another):

        ```bash
        geth attach http://<node hostname>:<node port>
        > eth.sendTransaction({from: <Alice account>, to: <Bob account>, value: web3.toWei(<Amount>, "ether")})
        ```

        Then, initiate a Geth connection to the proxy, and ask for the transaction receipt or Bob's balance:

        ```bash
        geth attach http://<proxy hostname>:<proxy port>
        > eth.getTransactionByHash(<transaction hash>)
        > eth.getBalance(<Bob account>)
        ```

    - Algorand:

        Execute the `./blockchains/algorand/remote/send.py` script remotely that will sends a transaction from Alice to Bob (in other words, from one wallet to another):

        ```bash
        python3 ./blockchains/algorand/remote/send.py --aldod_address http://<node hostname>:<node port> --sender_mnemonic <Alice mnemonic> --receiver <Bob address> --amount <Amount>
        ```

        Then, send a curl request to the proxy, and ask for the transaction receipt or Bob's balance:

        ```bash
        curl -H "X-Algo-API-Token: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" http://<proxy hostname>:<proxy port>/v2/transactions/pending/<Transaction id>
        curl -H "X-Algo-API-Token: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" http://<proxy hostname>:<proxy port>/v2/accounts/<Bob address>
        ```

    Since the proxy redirects to the blockchain where the transaction exists, the transaction receipt and Bob's balance should be available. But on the other blockchain, assuming the real one, the transaction should not exist and Bob's balance should not have changed. Bob has been successfully tricked by Alice.
