# semester-project

## Actual function of each actor

- **Client**: the client connects to the proxy. The user can then type messages in the terminal and send them by typing enter. The client waits for an answer for each message sent. The client can also type `exit` to close the connection.
- **Proxy**: upon a connection from the client, the proxy connects to 2 remote nodes and _opens_ a proxy between the client and the remote nodes. The proxy forwards the messages from the client to the remote nodes. However, the proxy only forwards the answer of one of the remote nodes (arbitrary for now) to the client, not both.
- **Node**: upon a connection from the proxy, the node waits for a message from the proxy. When it receives a message, it sends an ACK answer to the proxy.
