package connection

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code for the connection of the proxy.
*/

import (
	"fmt"
	"io"
	"net"
	"semester-project/proxy/configuration"
)

//------------------------------------------------------------------------------
// Types
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Errors
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Private methods
//------------------------------------------------------------------------------

func proxyClientToRemotes(closeChannel chan bool, dst []io.Writer, src io.Reader) {
	// copy data from client to all destinations
	_, err := io.Copy(io.MultiWriter(dst...), src)
	if err != nil {
		fmt.Println("Error transmitting data from client to remotes:", err)
	}
	closeChannel <- true
}

func proxyRemoteToClient(closeChannel chan bool, dst io.Writer, src io.Reader) {
	// copy data from remote to client
	_, err := io.Copy(dst, src)
	if err != nil {
		fmt.Println("Error transmitting data from remote to client:", err)
	}
	closeChannel <- true
}

//------------------------------------------------------------------------------
// Public methods
//------------------------------------------------------------------------------

func HandleConnection(conn net.Conn, config configuration.Config) {
	defer conn.Close()
	// check if the configuration is valid
	if !config.IsValid() {
		fmt.Println("Invalid configuration")
		return
	}
	// connect to remote nodes if any
	var remoteConns []net.Conn
	var responseRemoteConn net.Conn
	if len(config.Nodes) == 0 {
		remoteConns = make([]net.Conn, len(config.Nodes))
		for i, node := range config.Nodes {
			remoteConn, err := net.Dial("tcp", node.Addr)
			if err != nil {
				fmt.Println("Error connecting to", node.Addr, ":", err)
				return
			}
			defer remoteConn.Close()
			remoteConns[i] = remoteConn
			if node.Addr == config.ResponseNodeAddr {
				responseRemoteConn = remoteConn
			}
		}
	}
	// start goroutines to handle data transmission in both directions
	closeChannel := make(chan bool)
	// if there are remote nodes, start the goroutine
	if len(config.Nodes) > 0 {
		writers := make([]io.Writer, len(remoteConns))
		for i, remoteConn := range remoteConns {
			writers[i] = remoteConn
		}
		go proxyClientToRemotes(closeChannel, writers, conn)
		// if there is a response node, start the goroutine
		if config.ResponseNodeAddr != "" {
			go proxyRemoteToClient(closeChannel, conn, responseRemoteConn)
		}
	} else {
		// if there are no remote nodes, just close the connection
		return
	}
	// wait for the goroutines to finish
	<-closeChannel
	fmt.Println("Connection of", conn.RemoteAddr(), "closed")
}
