package logs

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
			Info:    log.New(output, "[CLIENT] INFO:    ", log.Ldate|log.Ltime|log.Lshortfile),
			Warning: log.New(output, "[CLIENT] WARNING: ", log.Ldate|log.Ltime|log.Lshortfile),
			Error:   log.New(output, "[CLIENT] ERROR:   ", log.Ldate|log.Ltime|log.Lshortfile),
		}, &Loggers{
			Info:    log.New(output, "[CONFIG] INFO:    ", log.Ldate|log.Ltime|log.Lshortfile),
			Warning: log.New(output, "[CONFIG] WARNING: ", log.Ldate|log.Ltime|log.Lshortfile),
			Error:   log.New(output, "[CONFIG] ERROR:   ", log.Ldate|log.Ltime|log.Lshortfile),
		}, nil
}
