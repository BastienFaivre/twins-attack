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
	"semester-project/proxy/logs"
)

// configListener listens for configuration connections.
func configListener(loggers *logs.Loggers, localAddrConfig string, configManager *configuration.ConfigManager) {
	// listen on local address using TCP
	loggers.Info.Println("Listening on", localAddrConfig, "for configuration connections")
	listener, err := net.Listen("tcp", localAddrConfig)
	if err != nil {
		panic("Error listening on " + localAddrConfig + ": " + err.Error())
	}
	defer listener.Close()
	// listen to upcoming configuration connections
	for {
		// accept connection
		loggers.Info.Println("Waiting for new connection...")
		conn, err := listener.Accept()
		if err != nil {
			loggers.Error.Println("Error accepting new connection:", err)
		}
		loggers.Info.Println("New connection from", conn.RemoteAddr())
		// start goroutine to handle configuration connection
		go connection.HandleConfigConnection(conn, configManager)
	}
}

// clientListener listens for client connections.
func clientListener(loggers *logs.Loggers, localAddrClient string, configManager *configuration.ConfigManager) {
	// listen on local address using TCP
	loggers.Info.Println("Listening on", localAddrClient, "for client connections")
	listener, err := net.Listen("tcp", localAddrClient)
	if err != nil {
		panic("Error listening on " + localAddrClient + ": " + err.Error())
	}
	defer listener.Close()
	// listen to upcoming client connections
	for {
		// accept connection
		loggers.Info.Println("Waiting for new connection...")
		conn, err := listener.Accept()
		if err != nil {
			loggers.Error.Println("Error accepting new connection:", err)
		}
		loggers.Info.Println("New connection from", conn.RemoteAddr())
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
	// get loggers
	clientLoggers, configLoggers, err := logs.GetLoggers("")
	if err != nil {
		panic("Error getting loggers: " + err.Error())
	}
	// initialize loggers
	connection.InitClientLoggers(clientLoggers)
	connection.InitConfigLoggers(configLoggers)
	// create a configuration manager
	configManager := configuration.NewConfigManager()
	// start goroutine to listen for configuration changes
	go configListener(configLoggers, localAddrConfig, configManager)
	// listen for client connections
	clientListener(clientLoggers, localAddrClient, configManager)
}
