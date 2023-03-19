package main

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code to simulate a client.
*/

import (
	"context"
	"fmt"
	"os"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// read arguments
	if len(os.Args) < 2 {
		fmt.Println("Usage: client <node address:port>")
		os.Exit(1)
	}
	nodeAddr := os.Args[1]
	// connect to the node
	client, err := ethclient.Dial("http://" + nodeAddr)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	account := common.HexToAddress("0xfa0e6307aefa5873ca7e57dea75aa103a2beefa5")
	balance, err := client.BalanceAt(context.Background(), account, nil)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Println(balance)
}
