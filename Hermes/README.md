# Hermes - the code
## Installation

The only pre-requisite is to have a recent version of Drracket, then go ahead
and launch an instance of Drracket running server.rkt and one or more
instances running client.rkt.

## Using Hermes

### General

The clients can run on the same computer with the server, or you can run the
server alone in another compute on the internet. As long as you have the
server's public ip address, the port its listening on(must port forward on home
network!), and the server allows communication through that port in the firewall
you are good to go.

### Clients

In the clients follow the prompts to set you up. Type in messages to send to
other clients. You may try connecting to server instance running locally
"localhost" or have an ip-address for a hermes server running elsewhere.

#### Commands
* Change color of your messages with /color color. Default is black.
* You can list users in chat with /list users. 
* You can get the count of users with /list count. 
* If you want to send a message to a particular user, do /whisper username message in chat.
* If you want to leave chat, type /quit. 

### Server

You can stop the server by typing in (stop-server) in the interactive window.
It's really important you do this to free up the ports.
