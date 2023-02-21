package main

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code for the node server.
*/

// the code is based on https://www.linode.com/docs/guides/developing-udp-and-tcp-clients-and-servers-in-go/#create-the-tcp-server

import (
	"fmt"
	"net"
	"os"
)

// for debugging purpose, the local address prefix is hard-coded
var localAddrPrefix = "127.0.0.1:"
var nodePort = "8000"

// handleConnection handles a connection from local
func handleConnection(conn net.Conn) {
	defer conn.Close()
	for {
		// read data from the connection
		data := make([]byte, 1024)
		n, err := conn.Read(data)
		if err != nil {
			// check is connection is closed
			if err.Error() == "EOF" {
				fmt.Println("Connection closed by", conn.RemoteAddr())
			} else {
				fmt.Println("Error reading data from ", conn.RemoteAddr(), ":", err)
			}
			return
		}
		fmt.Println("Data from", conn.RemoteAddr(), ":", string(data[:n-1]))
		// send response to the connection
		_, err = conn.Write([]byte("OK from node " + nodePort))
		if err != nil {
			fmt.Println("Error sending response to", conn.RemoteAddr(), ":", err)
			return
		}
	}
}

func main() {
	// read arguments
	// if len(os.Args) < 2 {
	// 	fmt.Println("Usage: node <local address:port>")
	// 	os.Exit(1)
	// }
	// localAddr := os.Args[1]
	if len(os.Args) < 2 {
		fmt.Println("Usage: node <port>")
		os.Exit(1)
	}
	nodePort = os.Args[1]
	localAddr := localAddrPrefix + nodePort
	// listen on local address using TCP
	fmt.Println("Listening on", localAddr)
	listener, err := net.Listen("tcp", localAddr)
	if err != nil {
		panic("Error listening on" + localAddr + ": " + err.Error())
	}
	defer listener.Close()
	// start node loop
	for {
		// accept connection from local
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("Error accepting connection:", err)
		}
		fmt.Println("Connection accepted from", conn.RemoteAddr())
		// handle connection
		go handleConnection(conn)
	}
}
