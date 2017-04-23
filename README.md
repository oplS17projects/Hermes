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

The  server continually loops waiting for connections from clients. The clients
are always on standby to receive input.
The GUI continually loops to handle input from the user, 
as well as to keep the canvas it writes the messages on updated.

> Will you use map/filter/reduce? How?

Map was used for dealing with input area of clients, and iterating over a list
of open ports to send messages. Filter was used to find the recipient of
a whisper.

> Will you use object-orientation? How?

Keeping count of the number of clients required working with objects that are able to
increment and decrement the number of users. We handled a list of connection
ports, messages similarly.
We also keep the GUI in an object so the many moving parts of the
user interface are packaged in one place.

> Will you use functional approaches to processing your data? How?

The communication part of Hermes is over tcp which uses a lot of functional
approaches e.g. you start a listener which you can call tcp-accept on.
The result of tcp accept are two pairs of ports which we can then bind to some
variables. Functional approaches are exemplied in most of the code base.

> Will you use state-modification approaches? How? (If so, this should be encapsulated within objects. `set!` pretty much should only exist inside an object.)

State-modification was used e.g. keeping count of logged in users requires
state modification via set! to maintain the true user account, managing the list
of open connections and messages required state-modification.
The user interface also needs a few states that it needs to keep up to date.

> Will you build an expression evaluator, like we did in the symbolic differentatior and the metacircular evaluator?

We allowed the use of a few commands through the user interface. The most notable ones
are the /whisper to send private messages to a user, /list count and /list users
to  view user statistics , and the /color command to allow
the user to change the color of their text.

### Deliverable and Demonstration
There are two big deliverables for this project. Code for the server
, and the clients which not only has code for interacting with Hermes,
but also a GUI for interactivity with a user. 

We are going to  demonstrate Hermes by running the server code on a remote machine.
We will connect to the server via our PCs running client code. We will ssh into
the remote machine to see the server running. Since Hermes is a multichat anyone
can join in the demonstration by connecting their computers to the remote
machine!



### Evaluation of Results
Evaluating Hermes  was very simple. Can at least two clients hold a meaningful
conversation remotely? If Client A speaks at 11:01 am, and client B does so at
11:01 plus a few seconds, Hermes has to convey  this state correctly. Is the GUI
intuitive for current irc users?  We successfully met these questions, and more.


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
I have written the networking code i.e. code that allows communication between
clients through server. I wrote scheduling code responsible for queueing
fairly the client messages and broadcasting to the rest of connected
clients. Implemented the logic for handling /list, /whisper commands.
