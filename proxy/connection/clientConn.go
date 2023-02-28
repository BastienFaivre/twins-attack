package connection

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code to handle client connections.
*/

import (
	"io"
	"net"
	"semester-project/proxy/configuration"
	"semester-project/proxy/logs"
)

//------------------------------------------------------------------------------
// Private variables
//------------------------------------------------------------------------------

// loggers is the logger used by the client connection handler.
var clientLoggers *logs.Loggers

//------------------------------------------------------------------------------
// Private methods
//------------------------------------------------------------------------------

// proxyClientToNodes copies data from the client connection to all nodes.
func proxyClientToNodes(closeChannel chan bool, dst []io.Writer, src io.Reader) {
	// copy data from client to all destination nodes
	_, err := io.Copy(io.MultiWriter(dst...), src)
	if err != nil {
		clientLoggers.Warning.Println("Error transmitting data from client to nodes:", err)
	}
	closeChannel <- true
}

// proxyNodeToClient copies data from the node connection to the client.
func proxyNodeToClient(closeChannel chan bool, dst io.Writer, src io.Reader) {
	// copy data from Node to client
	_, err := io.Copy(dst, src)
	if err != nil {
		clientLoggers.Warning.Println("Error transmitting data from node to client:", err)
	}
	closeChannel <- true
}

//------------------------------------------------------------------------------
// Public methods
//------------------------------------------------------------------------------

// InitClientLoggers initializes the loggers for the client connection handler.
func InitClientLoggers(loggers *logs.Loggers) {
	clientLoggers = loggers
}

// HandleClientConnection handles a client connection.
func HandleClientConnection(conn net.Conn, config configuration.Config) {
	defer conn.Close()
	// check if the configuration is valid
	if !config.IsValid() {
		clientLoggers.Error.Println("Invalid configuration")
		return
	}
	// connect to nodes if any
	var nodeConns []net.Conn
	var responseNodeConn net.Conn
	if len(config.Nodes) > 0 {
		nodeConns = make([]net.Conn, len(config.Nodes))
		for i, node := range config.Nodes {
			NodeConn, err := net.Dial("tcp", node.Addr)
			if err != nil {
				clientLoggers.Error.Println("Error connecting to", node.Addr, ":", err)
				return
			}
			defer NodeConn.Close()
			nodeConns[i] = NodeConn
			if node.Addr == config.ResponseNodeAddr {
				responseNodeConn = NodeConn
			}
		}
	}
	// start goroutines to handle data transmission in both directions
	closeChannel := make(chan bool)
	// if there are nodes, start the goroutine
	if len(config.Nodes) > 0 {
		writers := make([]io.Writer, len(nodeConns))
		for i, NodeConn := range nodeConns {
			writers[i] = NodeConn
		}
		go proxyClientToNodes(closeChannel, writers, conn)
		// if there is a response node, start the goroutine
		if config.ResponseNodeAddr != "" {
			go proxyNodeToClient(closeChannel, conn, responseNodeConn)
		}
	} else {
		// if there are no nodes, just close the connection
		clientLoggers.Info.Println("No nodes, closing connection")
		return
	}
	// wait for the goroutines to finish
	<-closeChannel
	clientLoggers.Info.Println("Connection of", conn.RemoteAddr(), "closed")
}
