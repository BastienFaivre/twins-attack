package connection

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code to handle configuration updates.
*/

import (
	"fmt"
	"net"
	"semester-project/proxy/configuration"
)

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

const BUFFER_SIZE = 1024

//------------------------------------------------------------------------------
// Public methods
//------------------------------------------------------------------------------

// HandleConfigConnection handles a configuration connection.
func HandleConfigConnection(conn net.Conn, configManager *configuration.ConfigManager) {
	defer conn.Close()
	// read data
	data := make([]byte, BUFFER_SIZE)
	n, err := conn.Read(data)
	if err != nil {
		fmt.Println("Error reading data:", err)
		return
	}
	// parse configuration
	config, err := configManager.ParseConfig(string(data[:n]))
	if err != nil {
		fmt.Println("Error parsing configuration:", err)
		return
	}
	// set configuration
	err = configManager.SetConfig(config)
	if err != nil {
		fmt.Println("Error setting configuration:", err)
		return
	}
	fmt.Println("Configuration updated")
}
