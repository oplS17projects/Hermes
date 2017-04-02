# Hermes

### Statement
Hermes is a multi-client chat program akin to IRC written in  Racket. Building
Hermes is interesting as it exposes us to various design problems namely networking,
synchronization, scheduling, and GUI design.

### Analysis
> Will you use data abstraction? How?
TCP communication will be abstracted away so will only deal with Hermes
definition of a message.
We will try to encrypt the messages passed around. The encryption will be
abstracted away so we only have to think about it once during implementation

> Will you use recursion? How?
The  server will continually loop waiting for connections from clients.
The Gui will continually loop to handle input with the user, and to and fro
Hermes.

> Will you use map/filter/reduce? How? 
Map will be used for dealing editor area of clients.

> Will you use object-orientation? How?
Keeping account of the number of clients will require an object of some sort.
With procedures to increment and decrement the number of users

> Will you use functional approaches to processing your data? How?
The communication part of Hermes is over tcp which uses a lot of functional
approaches e.g. you start a listener which you can then pass to tcp accept.
The result of tcp accept are two pairs of ports which we can then bind to some
variables. 

> Will you use state-modification approaches? How? (If so, this should be encapsulated within objects. `set!` pretty much should only exist inside an object.)
State-modification will be used e.g. keeping count of logged in users requires
state modification via set! to maintain the true user account

> Will you build an expression evaluator, like we did in the symbolic differentatior and the metacircular evaluator?
Users will type their input into a text field from the GUI. We will retrieve
the command and evaluate it to see if its a message, or a command to change
GUI state. We will do something that resembles the metacircular evaluator.


### Deliverable and Demonstration
There are two big deliverables for this project. Code for the server(Hermes,
get it?), and the clients which not only has code for interacting with Hermes,
but also a GUI for interactivity with a user like myself. 

We plan to demonstrate Hermes by running the server code on a remote machine.
We will connect to the server via our PCs running client code. We will ssh into
the remote machine to see the server running. Since Hermes is a multichat anyone
can join in the demonstration by connecting their computers to the remote
machine!



### Evaluation of Results
Evaluating Hermes is very simple. Can at least two clients hold a meaningful
conversation remotely? If Client A speaks at 11:01 am, and client B does so at
11:01 plus a few seconds, Hermes has to convey  this state correctly.


## Architecture Diagram

![Diagram](https://github.com/oplS17projects/Hermes/blob/master/architecture_diagram.png)


## Schedule
Explain how you will go from proposal to finished product. 

There are three deliverable milestones to explicitly define, below.

The nature of deliverables depend on your project, but may include things like processed data ready for import, core algorithms implemented, interface design prototyped, etc. 

You will be expected to turn in code, documentation, and data (as appropriate) at each of these stages.

Write concrete steps for your schedule to move from concept to working system. 

### First Milestone (Sun Apr 9)
Which portion of the work will be completed (and committed to Github) by this day? 

### Second Milestone (Sun Apr 16)
Which portion of the work will be completed (and committed to Github) by this day?  

### Public Presentation (Mon Apr 24, Wed Apr 26, or Fri Apr 28 [your date to be determined later])
What additionally will be completed before the public presentation?

## Group Responsibilities
Here each group member gets a section where they, as an individual, detail what they are responsible for in this project. Each group member writes their own Responsibility section. Include the milestones and final deliverable.

Please use Github properly: each individual must make the edits to this file representing their own section of work.

### Douglas Richardson @Doug-Richardson
will write the....

### Ibrahim Mkusa @iskm
will work on...
