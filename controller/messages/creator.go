package messages

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code to create messages to send to the proxy.
*/

import (
	"errors"
)

//------------------------------------------------------------------------------
// Public methods
//------------------------------------------------------------------------------

// CreateCommandMessage creates a message to send to the proxy.
func CreateCommandMessage(args []string) (string, error) {
	// initialize message and error
	var message string
	var err error
	// parse command
	if len(args) < 1 {
		return "", errors.New("usage: controller <command> [args...]")
	}
	command := args[0]
	args = args[1:]
	// parse arguments
	switch command {
	case "change-flow":
		message, err = changeFlowMessageBuilder(args)
	default:
		return "", errors.New("unknown command: " + command)
	}
	if err != nil {
		return "", err
	}
	// return the message
	return message, nil
}
