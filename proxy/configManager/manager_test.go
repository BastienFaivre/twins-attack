package configManager

/*
Author: Bastien Faivre
Project: EPFL Master Semester Project
Description: This file contains the tests for the config manager of the proxy.
*/

import (
	"testing"
)

//------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------

// compareConfig compares two configs and returns true if they are equal.
func compareConfig(c1, c2 Config) bool {
	if len(c1.Nodes) != len(c2.Nodes) {
		return false
	}
	for i := range c1.Nodes {
		if c1.Nodes[i].Addr != c2.Nodes[i].Addr {
			return false
		}
	}
	return c1.UseResponseFrom == c2.UseResponseFrom
}

//------------------------------------------------------------------------------
// Tests
//------------------------------------------------------------------------------

func TestValidParseConfig(t *testing.T) {
	cm := NewConfigManager()
	configStr := "{" +
		"\"nodes\":[{\"addr\":\"127.0.0.1:8001\"}]," +
		"\"useResponseFrom\":\"127.0.0.1:8001\"" +
		"}"
	_, err := cm.ParseConfig(configStr)
	if err != nil {
		t.Error("Error parsing valid config:", err)
	}
}

func TestInvalidParseConfig(t *testing.T) {
	cm := NewConfigManager()
	configStr := ""
	_, err := cm.ParseConfig(configStr)
	if err == nil {
		t.Error("Error parsing invalid config: no error returned")
	}
	configStr = "{\"abc\":123}"
	_, err = cm.ParseConfig(configStr)
	if err == nil {
		t.Error("Error parsing invalid config: no error returned")
	}
	if err != ErrInvalidConfig {
		t.Error("Error parsing invalid config: wrong error returned")
	}
}

func TestValidSetConfig(t *testing.T) {
	cm := NewConfigManager()
	configStr := "{" +
		"\"nodes\":[{\"addr\":\"127.0.0.1:8001\"}]," +
		"\"useResponseFrom\":\"127.0.0.1:8001\"" +
		"}"
	config, err := cm.ParseConfig(configStr)
	if err != nil {
		t.Error("Error parsing valid config:", err)
	}
	err = cm.SetConfig(config)
	if err != nil {
		t.Error("Error setting valid config:", err)
	}
}

func TestInvalidSetConfig(t *testing.T) {
	cm := NewConfigManager()
	config := Config{}
	err := cm.SetConfig(config)
	if err == nil {
		t.Error("Error setting invalid config: no error returned")
	}
	if err != ErrInvalidConfig {
		t.Error("Error setting invalid config: wrong error returned")
	}
}

func TestGetConfig(t *testing.T) {
	cm := NewConfigManager()
	configStr := "{" +
		"\"nodes\":[{\"addr\":\"127.0.0.1:8001\"}]," +
		"\"useResponseFrom\":\"127.0.0.1:8001\"" +
		"}"
	config, err := cm.ParseConfig(configStr)
	if err != nil {
		t.Error("Error parsing valid config:", err)
	}
	err = cm.SetConfig(config)
	if err != nil {
		t.Error("Error setting valid config:", err)
	}
	config2 := cm.GetConfig()
	if !compareConfig(config, config2) {
		t.Error("Error getting config: wrong config returned")
	}
}
