package main

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code to simulate a client.
*/

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"strings"
	"time"
)

// for debugging purpose, the remote address is hard-coded
const remoteAddr = "127.0.0.1:8000"

func main() {
	// read arguments
	// if len(os.Args) < 2 {
	// 	fmt.Println("Usage: client <remote address:port>")
	// 	os.Exit(1)
	// }
	// remoteAddr := os.Args[1]
	// connect to remote using TCP
	fmt.Println("Connecting to", remoteAddr)
	conn, err := net.Dial("tcp", remoteAddr)
	if err != nil {
		fmt.Println("Error connecting to remote:", err)
		os.Exit(1)
	}
	defer conn.Close()
	fmt.Println("Connected to remote!")
	// start client loop
	for {
		// read data from stdin
		reader := bufio.NewReader(os.Stdin)
		fmt.Print("Enter data to send: ")
		data, _ := reader.ReadString('\n')
		// stop client if asked to
		if data == "exit\n" {
			fmt.Println("Exiting...")
			os.Exit(0)
		}
		// send data to remote
		fmt.Println("Sending data to remote...")
		_, err = conn.Write([]byte(data))
		if err != nil {
			fmt.Println("Error sending data to remote:", err)
			os.Exit(1)
		}
		// read reponse from remote
		fmt.Println("Waiting for response from remote...")
		conn.SetReadDeadline(time.Now().Add(2 * time.Second))
		response := make([]byte, 1024)
		_, err = conn.Read(response)
		if err != nil {
			if strings.Contains(err.Error(), "i/o timeout") {
				fmt.Println("No response from remote")
				continue
			} else {
				fmt.Println("Error reading response from remote:", err)
				os.Exit(1)
			}
		}
		fmt.Println("Response from remote:", string(response))
	}

}
