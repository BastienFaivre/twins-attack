package main

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the entry point of the controller.
*/

import (
	"fmt"
	"os"
	"semester-project/controller/messages"
	"semester-project/controller/sender"
)

func main() {
	// read arguments
	if len(os.Args) < 3 {
		fmt.Println("Usage: controller <proxy address:port> <command> [args...]")
	}
	proxyAddr := os.Args[1]
	args := os.Args[2:]
	// parse command
	message, err := messages.CreateCommandMessage(args)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	// send the message
	err = sender.Send(proxyAddr, message)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
