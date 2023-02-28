package sender

import "net"

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code to send messages to the proxy.
*/

func Send(proxyAddr string, message string) error {
	// connect to the proxy
	conn, err := net.Dial("tcp", proxyAddr)
	if err != nil {
		return err
	}
	defer conn.Close()
	// send the message
	_, err = conn.Write([]byte(message))
	if err != nil {
		return err
	}
	return nil
}
