package main

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code to simulate a node in the network.
*/

import (
	"fmt"
	"net"
	"os"
)

// for debugging purpose, the local address prefix is hard-coded
var localAddrPrefix = "127.0.0.1:"
var nodePort = "8000"

// handleConnection handles a connection
func handleConnection(conn net.Conn) {
	defer conn.Close()
	for {
		// read data from the connection
		data := make([]byte, 1024)
		n, err := conn.Read(data)
		if err != nil {
			fmt.Println("Connection of", conn.RemoteAddr(), "closed")
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
		// accept connection
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("Error accepting connection:", err)
		}
		fmt.Println("New connection from", conn.RemoteAddr())
		// handle connection
		go handleConnection(conn)
	}
}
