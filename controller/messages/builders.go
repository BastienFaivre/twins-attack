package messages

import (
	"encoding/json"
	"errors"
	"fmt"
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

//------------------------------------------------------------------------------
// Private methods (Message builders)
//------------------------------------------------------------------------------

// changeFlowMessageBuilder builds the message to change the flow.
func changeFlowMessageBuilder(args []string) (string, error) {
	if len(args) < 2 {
		fmt.Println("A")
		return "", errors.New("usage: controller change-flow destination-nodes [nodes...] response-node [node]")
	}
	// parse the destination nodes
	if args[0] != "destination-nodes" {
		fmt.Println("B")
		return "", errors.New("usage: controller change-flow destination-nodes [nodes...] response-node [node]")
	}
	destinationNodes := []Node{}
	for i := 1; i < len(args); i++ {
		if args[i] == "response-node" {
			args = args[i:]
			break
		}
		destinationNodes = append(destinationNodes, Node{Addr: args[i]})
	}
	// parse the response node
	if args[0] != "response-node" {
		fmt.Println("C")
		return "", errors.New("usage: controller change-flow destination-nodes [nodes...] response-node [node]")
	}
	responseNode := ""
	if len(args) > 1 {
		responseNode = args[1]
	}
	// create the config
	config := Config{
		Nodes:            destinationNodes,
		ResponseNodeAddr: responseNode,
	}
	// create the message
	message, err := json.Marshal(config)
	if err != nil {
		fmt.Println("D")
		return "", err
	}
	return string(message), nil
}
