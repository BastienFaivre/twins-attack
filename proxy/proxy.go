package main

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code for the proxy server.
*/

// the code is based on https://github.com/maxmcd/tcp-proxy

import (
	"fmt"
	"io"
	"net"
)

// for debugging purpose, the local address and the two remote addresses are hard-coded
const localAddr = "127.0.0.1:8000"
const remoteAddr1 = "127.0.0.1:8001"
const remoteAddr2 = "127.0.0.1:8002"

// proxyClientToRemotes proxies data from client to remotes
func proxyClientToRemotes(closeChannel chan bool, dst []io.Writer, src io.Reader) {
	// copy data from client to (all) dst
	_, err := io.Copy(io.MultiWriter(dst...), src)
	if err != nil {
		fmt.Println("Error proxying data from client to remotes:", err)
	}
	closeChannel <- true
}

// proxyRemotesToClient proxies data from remotes to client
func proxyRemotesToClient(closeChannel chan bool, dst io.Writer, src []io.Reader) {
	// only copy data from one remote to client
	_, err := io.Copy(dst, src[0])
	if err != nil {
		fmt.Println("Error proxying data from remotes to client:", err)
	}
	closeChannel <- true
}

// handleConnection handles a connection from local
func handleConnection(conn net.Conn) {
	defer conn.Close()
	// connect to remote 1 and remote 2
	remoteConn1, err := net.Dial("tcp", remoteAddr1)
	if err != nil {
		fmt.Println("Error connecting to", remoteAddr1, ":", err)
		return
	}
	defer remoteConn1.Close()
	remoteConn2, err := net.Dial("tcp", remoteAddr2)
	if err != nil {
		fmt.Println("Error connecting to", remoteAddr2, ":", err)
		return
	}
	defer remoteConn2.Close()
	// start goroutine to handle proxying in both directions
	closeChannel := make(chan bool)
	go proxyClientToRemotes(closeChannel, []io.Writer{remoteConn1, remoteConn2}, conn)
	go proxyRemotesToClient(closeChannel, conn, []io.Reader{remoteConn1, remoteConn2})
	// wait for proxies to close
	<-closeChannel
	fmt.Println("Connection closed by", conn.RemoteAddr())
}

func main() {
	// read arguments
	// if len(os.Args) < 2 {
	// 	fmt.Println("Usage: client <local address:port> <remote 1 address:port> <remote 2 address:port>")
	// 	os.Exit(1)
	// }
	// localAddr := os.Args[1]
	// remoteAddr1 := os.Args[2]
	// remoteAddr2 := os.Args[3]
	// listen on local address using TCP
	fmt.Println("Listening on", localAddr)
	listener, err := net.Listen("tcp", localAddr)
	if err != nil {
		panic("Error listening on " + localAddr + ": " + err.Error())
	}
	defer listener.Close()
	// start proxy loop
	for {
		// accept connection from local
		fmt.Println("Waiting for new connection...")
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("Error accepting new connection:", err)
		}
		fmt.Println("New connection from", conn.RemoteAddr())
		// start goroutine to handle connection
		go handleConnection(conn)
	}
}
