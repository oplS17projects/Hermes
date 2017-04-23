# Hermes

### Statement
Hermes is a multi-client chat program akin to IRC written in  Racket. Building
Hermes was interesting as it exposed us to various design problems namely networking,
synchronization, scheduling, GUI design, and component design.

### Analysis
> Will you use data abstraction? How?

TCP communication has been abstracted away, so that we deal with Hermes
definition of a message.

> Will you use recursion? How?

The  server continually loops waiting for connections from clients.
The GUI continually loops to handle input from the user, 
as well as to keep the canvas it writes the messages on updated.

> Will you use map/filter/reduce? How?

Map will be used for dealing with input area of clients, and iterating over a list
of open ports to send messages.

> Will you use object-orientation? How?

Keeping count of the number of clients required working with objects that are able to
increment and decrement the number of users.
We also keep the GUI in an object so the many moving parts of the
user interface are packaged in one place.

> Will you use functional approaches to processing your data? How?

The communication part of Hermes is over tcp which uses a lot of functional
approaches e.g. you start a listener which you can call tcp-accept on.
The result of tcp accept are two pairs of ports which we can then bind to some
variables.

> Will you use state-modification approaches? How? (If so, this should be encapsulated within objects. `set!` pretty much should only exist inside an object.)

State-modification will be used e.g. keeping count of logged in users requires
state modification via set! to maintain the true user account.
The user interface also needs a few states that it needs to keep up to date.

> Will you build an expression evaluator, like we did in the symbolic differentatior and the metacircular evaluator?

We allow the use of a few commands through the user interface. The most notable ones
are the /quit command to shut down a connection and the /color command to allow
the user to change the color of their text.

### Deliverable and Demonstration
There are two big deliverables for this project. Code for the server
, and the clients which not only has code for interacting with Hermes,
but also a GUI for interactivity with a user. 

We will demonstrate Hermes by running the server code on a remote machine.
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
The first step in our project was to setup a system to get data from one machine to another. What data exactly wasn't directly important and the other machine didn't really need to display it in a pretty manner, it just needed to relay that it has recieved the correct information.

Next we needed to create a user interface that looked nice. Some way to control the connection and display information in a convient and readable format.

After we finished the user interface and connecting the machines, we needed to merge them together and begin expanding the utility if time permits.

### First Milestone (Sun Apr 9)
Get two different machines to relay information meaningfully.

### Second Milestone (Sun Apr 16)
Get a GUI that looks professional and uses the correct format.

### Public Presentation (Mon Apr 24)
Merging the GUI and information relay together into one program. If time permits we also plan on adding additional features.

## Group Responsibilities

### Douglas Richardson @Doug-Richardson
I have written the code for the GUI. 
It presents the user with a simple readable format for displaying the information
that the server provides. For the most part the program only interacts with the user
through the GUI.

### Ibrahim Mkusa @iskm
Will write the networking code i.e. code that allows communication between
clients through server. I will also write scheduling code responsible for queueing
fairly and orderly the client messages and broadcasting to the rest of connected
clients. If time permits, i will also be responsible for authenticating users
via a backend database. 
