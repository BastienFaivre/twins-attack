package configManager

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the code for the config manager of the proxy.
*/

import (
	"encoding/json"
	"errors"
	"sync"
)

//------------------------------------------------------------------------------
// Types
//------------------------------------------------------------------------------

// A Node is a destination node for the proxy.
type Node struct {
	Addr string `json:"addr"`
}

// A Config is the configuration for the proxy.
// It contains the list of destination nodes and the node to use for the
// response.
type Config struct {
	Nodes           []Node `json:"nodes"`
	UseResponseFrom string `json:"useResponseFrom"`
}

// A ConfigManager manages the proxy configuration.
// It is thread-safe.
type ConfigManager struct {
	ConfigLock sync.Mutex
	Config     Config
}

//------------------------------------------------------------------------------
// Errors
//------------------------------------------------------------------------------

// ErrInvalidConfig is returned when the config is invalid.
var ErrInvalidConfig = errors.New("invalid config")

//------------------------------------------------------------------------------
// Private methods
//------------------------------------------------------------------------------

// isValid checks if the config is valid.
func (c *Config) isValid() bool {
	// check that the nodes array is set
	return c.Nodes != nil
}

//------------------------------------------------------------------------------
// Public methods
//------------------------------------------------------------------------------

// NewConfigManager creates and returns a new ConfigManager.
func NewConfigManager() *ConfigManager {
	return &ConfigManager{}
}

func (cm *ConfigManager) ParseConfig(configStr string) (Config, error) {
	var config Config
	err := json.Unmarshal([]byte(configStr), &config)
	if err != nil {
		return Config{}, err
	}
	if !config.isValid() {
		return Config{}, ErrInvalidConfig
	}
	return config, nil
}

// GetConfig updates the config if it is valid.
func (cm *ConfigManager) SetConfig(config Config) error {
	if !config.isValid() {
		return ErrInvalidConfig
	}
	cm.ConfigLock.Lock()
	defer cm.ConfigLock.Unlock()
	cm.Config = config
	return nil
}

// GetConfig returns the config.
func (cm *ConfigManager) GetConfig() Config {
	cm.ConfigLock.Lock()
	defer cm.ConfigLock.Unlock()
	return cm.Config
}

func (c *Config) String() string {
	str := "Config:\n"
	str += "\tNodes:\n"
	for _, node := range c.Nodes {
		str += "\t\t" + node.Addr + "\n"
	}
	str += "\tUseResponseFrom: " + c.UseResponseFrom + "\n"
	return str
}
