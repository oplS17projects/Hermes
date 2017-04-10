# Hermes

### Statement
Hermes is a multi-client chat program akin to IRC written in  Racket. Building
Hermes is interesting as it exposes us to various design problems namely networking,
synchronization, scheduling, and GUI design.

### Analysis
> Will you use data abstraction? How?

TCP communication will be abstracted away, so that we deal with Hermes
definition of a message.
We will try to encrypt the messages passed around. The encryption will be
abstracted away, so we only have to think about it once during implementation.

> Will you use recursion? How?

The  server will continually loop waiting for connections from clients.
The GUI will continually loop to handle input from the user, and to and fro
the server.

> Will you use map/filter/reduce? How?

Map will be used for dealing with input area of clients, and iterating over a list
of open ports to send messages.

> Will you use object-orientation? How?

Keeping count of the number of clients will require an object of some sort.
With procedures to increment and decrement the number of users.

> Will you use functional approaches to processing your data? How?

The communication part of Hermes is over tcp which uses a lot of functional
approaches e.g. you start a listener which you can call tcp-accept on.
The result of tcp accept are two pairs of ports which we can then bind to some
variables.

> Will you use state-modification approaches? How? (If so, this should be encapsulated within objects. `set!` pretty much should only exist inside an object.)

State-modification will be used e.g. keeping count of logged in users requires
state modification via set! to maintain the true user account.

> Will you build an expression evaluator, like we did in the symbolic differentatior and the metacircular evaluator?

Users will type their input into a text field from the GUI. We will retrieve
the command and evaluate it to see if its a message, or a command to change
GUI state. We will do something that resembles the metacircular evaluator.


### Deliverable and Demonstration
There are two big deliverables for this project. Code for the server
, and the clients which not only has code for interacting with Hermes,
but also a GUI for interactivity with a user. 

We plan to demonstrate Hermes by running the server code on a remote machine.
We will connect to the server via our PCs running client code. We will ssh into
the remote machine to see the server running. Since Hermes is a multichat anyone
can join in the demonstration by connecting their computers to the remote
machine!



### Evaluation of Results
Evaluating Hermes is very simple. Can at least two clients hold a meaningful
conversation remotely? If Client A speaks at 11:01 am, and client B does so at
11:01 plus a few seconds, Hermes has to convey  this state correctly. Is the GUI
intuitive for current irc users?  When we can successfully answer this questions
satisfactorily we would have met our goals.


## Architecture Diagram

#### Preliminary design
![Architecture](https://github.com/oplS17projects/Hermes/blob/master/ext/arch_diagram.png)


#### The Game plan
![Diagram](https://github.com/oplS17projects/Hermes/blob/master/ext/architecture_diagram.png)


## Schedule
The first step in out project will be to setup a system to get data from one machine to another. What data exactly isn't directly important and the other machine doesn't really need to display it in a pretty manner, it just needs to relay that it has recieved the correct information.

Next we need to create a user interface that looks nice. Some way to control the connection and display information in a convient and readable format.

After we have finished the user interface and connecting the machines, we will need to merge them together and begin expanding the utility if time permits.

### First Milestone (Sun Apr 9)
Get two different machines to relay information meaningfully.

### Second Milestone (Sun Apr 16)
Get a GUI that looks professional and uses the correct format.

### Public Presentation (Mon Apr 24, Wed Apr 26, or Fri Apr 28 [your date to be determined later])
Merging the GUI and information relay together into one program. If time permits we also plan on adding additional features.

## Group Responsibilities

### Douglas Richardson @Doug-Richardson
Will write the GUI code. This should allow the user to access different
aspects of our program in a clean easy to use interface. Most of
how the program responds to user input will be filtered through the gui.
If time permits I will also be writing code to encrypt and decrypt the information
going from the server to the clients. 

### Ibrahim Mkusa @iskm
Will write the networking code i.e. code that allows communication between
clients through server. I will also write scheduling code responsible for queuing
fairly and orderly the client messages and broadcasting to the rest of connected
clients. If time permits, i will also be responsible for authenticating users
via a backend database. 
