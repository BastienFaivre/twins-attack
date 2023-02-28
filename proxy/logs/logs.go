package logs

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code to log messages.
*/

import (
	"io"
	"log"
	"os"
)

// Loggers contains all the loggers.
type Loggers struct {
	Info    *log.Logger
	Warning *log.Logger
	Error   *log.Logger
}

// GetLoggers returns all the loggers.
func GetLoggers(filepath string) (*Loggers, *Loggers, error) {
	var output io.Writer
	// if the filepath is empty, use stdout
	if filepath == "" {
		output = os.Stdout
	} else {
		file, err := os.OpenFile(filepath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
		if err != nil {
			return nil, nil, err
		}
		output = file
	}
	return &Loggers{
			Info:    log.New(output, "\033[44;37m[CLIENT]\033[0;32m INFO:    \033[0m", log.Ldate|log.Ltime|log.Lshortfile),
			Warning: log.New(output, "\033[44;37m[CLIENT]\033[0;33m WARNING: \033[0m", log.Ldate|log.Ltime|log.Lshortfile),
			Error:   log.New(output, "\033[44;37m[CLIENT]\033[0;31m ERROR:   \033[0m", log.Ldate|log.Ltime|log.Lshortfile),
		}, &Loggers{
			Info:    log.New(output, "\033[43;37m[CONFIG]\033[0;32m INFO:    \033[0m", log.Ldate|log.Ltime|log.Lshortfile),
			Warning: log.New(output, "\033[43;37m[CONFIG]\033[0;33m WARNING: \033[0m", log.Ldate|log.Ltime|log.Lshortfile),
			Error:   log.New(output, "\033[43;37m[CONFIG]\033[0;31m ERROR:   \033[0m", log.Ldate|log.Ltime|log.Lshortfile),
		}, nil
}
