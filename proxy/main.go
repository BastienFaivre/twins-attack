package main

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the entry point of the proxy.
*/

import (
	"fmt"
	"net"
	"os"
	"semester-project/proxy/configuration"
	"semester-project/proxy/connection"
)

// configListener listens for configuration connections.
func configListener(localAddrConfig string, configManager *configuration.ConfigManager) {
	// listen on local address using TCP
	fmt.Println("Listening on", localAddrConfig, "for configuration connections")
	listener, err := net.Listen("tcp", localAddrConfig)
	if err != nil {
		panic("Error listening on " + localAddrConfig + ": " + err.Error())
	}
	defer listener.Close()
	// listen to upcoming configuration connections
	for {
		// accept connection
		fmt.Println("Waiting for new connection...")
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("Error accepting new connection:", err)
		}
		fmt.Println("New connection from", conn.RemoteAddr())
		// start goroutine to handle configuration connection
		go connection.HandleConfigConnection(conn, configManager)
	}
}

// clientListener listens for client connections.
func clientListener(localAddrClient string, configManager *configuration.ConfigManager) {
	// listen on local address using TCP
	fmt.Println("Listening on", localAddrClient, "for client connections")
	listener, err := net.Listen("tcp", localAddrClient)
	if err != nil {
		panic("Error listening on " + localAddrClient + ": " + err.Error())
	}
	defer listener.Close()
	// listen to upcoming client connections
	for {
		// accept connection
		fmt.Println("Waiting for new connection...")
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("Error accepting new connection:", err)
		}
		fmt.Println("New connection from", conn.RemoteAddr())
		// get the configuration
		config := configManager.GetConfig()
		// start goroutine to handle client connection
		go connection.HandleClientConnection(conn, config)
	}
}

func main() {
	// read arguments
	if len(os.Args) < 2 {
		fmt.Println("Usage: proxy <local address> <port for client> <port for configuration>")
		os.Exit(1)
	}
	localAddrClient := os.Args[1] + ":" + os.Args[2]
	localAddrConfig := os.Args[1] + ":" + os.Args[3]
	// create a configuration manager
	configManager := configuration.NewConfigManager()
	// start goroutine to listen for configuration changes
	go configListener(localAddrConfig, configManager)
	// listen for client connections
	clientListener(localAddrClient, configManager)
}
