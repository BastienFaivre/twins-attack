# semester-project

## Repository content

- `client`: contains a sample client used to debug the project. The client simply connects to the proxy using TCP and sends messages typed by the user.
- `controller`: contains the controller tool used to send commands to the proxy. An example bash script is provided to show how to use the controller. The script executes an arbitrary scenario updating the proxy configuration.
- `node`: contains a sample node used to debug the project. The node simulates a real blockchain node and simply sends back an acknowledgement for all received messages.
- `proxy`: contains the proxy implementation. The proxy is implemented as a TCP server that accepts connections from clients. Then a _proxy_ connection is established with the specific current configuration set by the controller. The proxy is able to handle multiple clients and multiple nodes at the same time. Once a _proxy connection_ is established for a client with a specific configuration, the configuration stays the same even if the proxy receives a new configuration from the controller. It means that a new configuration is applied to all future _proxy connections_ but not to the current ones.
