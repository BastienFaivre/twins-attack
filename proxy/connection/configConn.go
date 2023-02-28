package connection

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code to handle configuration updates.
*/

import (
	"net"
	"semester-project/proxy/configuration"
	"semester-project/proxy/logs"
)

//------------------------------------------------------------------------------
// Private variables
//------------------------------------------------------------------------------

// loggers is the logger used by the configuration connection handler.
var configLoggers *logs.Loggers

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

// BUFFER_SIZE is the size of the buffer used to read data.
const BUFFER_SIZE = 1024

//------------------------------------------------------------------------------
// Public methods
//------------------------------------------------------------------------------

// InitConfigLoggers initializes the loggers for the configuration connection handler.
func InitConfigLoggers(loggers *logs.Loggers) {
	configLoggers = loggers
}

// HandleConfigConnection handles a configuration connection.
func HandleConfigConnection(conn net.Conn, configManager *configuration.ConfigManager) {
	defer conn.Close()
	// read data
	data := make([]byte, BUFFER_SIZE)
	n, err := conn.Read(data)
	if err != nil {
		configLoggers.Error.Println("Error reading data:", err)
		return
	}
	// parse configuration
	config, err := configManager.ParseConfig(string(data[:n]))
	if err != nil {
		configLoggers.Error.Println("Error parsing configuration:", err)
		return
	}
	// set configuration
	err = configManager.SetConfig(config)
	if err != nil {
		configLoggers.Error.Println("Error setting configuration:", err)
		return
	}
	configLoggers.Info.Println("Configuration updated")
}
