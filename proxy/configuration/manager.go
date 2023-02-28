package configuration

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
	Nodes            []Node `json:"nodes"`
	ResponseNodeAddr string `json:"responseNodeAddr"`
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
// Public methods
//------------------------------------------------------------------------------

// NewConfigManager creates and returns a new ConfigManager.
func NewConfigManager() *ConfigManager {
	return &ConfigManager{}
}

// IsValid checks if the config is valid.
func (c *Config) IsValid() bool {
	// check that the nodes array is set
	if c.Nodes == nil {
		return false
	}
	// check that if the response node is set, it is in the nodes array
	if c.ResponseNodeAddr != "" {
		for _, node := range c.Nodes {
			if node.Addr == c.ResponseNodeAddr {
				return true
			}
		}
		return false
	}
	return true
}

func (cm *ConfigManager) ParseConfig(configStr string) (Config, error) {
	var config Config
	err := json.Unmarshal([]byte(configStr), &config)
	if err != nil {
		return Config{}, err
	}
	if !config.IsValid() {
		return Config{}, ErrInvalidConfig
	}
	return config, nil
}

// GetConfig updates the config if it is valid.
func (cm *ConfigManager) SetConfig(config Config) error {
	if !config.IsValid() {
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
	str += "\tUseResponseFrom: " + c.ResponseNodeAddr + "\n"
	return str
}
