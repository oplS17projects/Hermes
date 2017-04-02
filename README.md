# Project Title Goes Here (10 words maximum): Hermes

### Statement
Describe your project. Why is it interesting? Why is it interesting to you personally? What do you hope to learn? 
Hermes is a multi-client chat program akin to IRC written in  Racket. Building
Hermes is interesting as it exposes us to various design problems namely networking,
synchronization, scheduling, and GUI design.

### Analysis
Explain what approaches from class you will bring to bear on the project.

Be explicit about the techiques from the class that you will use. For example:

- Will you use data abstraction? How?
- Will you use recursion? How?
- Will you use map/filter/reduce? How? 
- Will you use object-orientation? How?
- Will you use functional approaches to processing your data? How?
- Will you use state-modification approaches? How? (If so, this should be encapsulated within objects. `set!` pretty much should only exist inside an object.)
- Will you build an expression evaluator, like we did in the symbolic differentatior and the metacircular evaluator?
- Will you use lazy evaluation approaches?

The idea here is to identify what ideas from the class you will use in carrying out your project. 

**Your project will be graded, in part, by the extent to which you adopt approaches from the course into your implementation, _and_ your discussion about this.**

### External Technologies
As stated previously Hermes will be designed using a client/server model. The
server instance could be running locally or on a remote machine. The same
applies for clients. We can think of the clients as connecting to an external
system, Hermes!
* authentication via databases
You are encouraged to develop a project that connects to external systems. For example, this includes systems that:

- retrieve information or publish data to the web
- generate or process sound
- control robots or other physical systems
- interact with databases

If your project will do anything in this category (not only the things listed above!), include this section and discuss.

### Data Sets or other Source Materials
We won't need to download any data sets. An artificial dataset will be generated
consisting of conversations between clients, plus any additional commands that aren't
messages for testing. 

If you will be working with existing data, where will you get those data from? (Dowload from a website? Access in a database? Create in a simulation you will build? ...)

How will you convert your data into a form usable for your project?  

If you are pulling data from somewhere, actually go download it and look at it before writing the proposal. Explain in some detail what your plan is for accomplishing the necessary processing.

If you are using some other starting materials, explain what they are. Basically: anything you plan to use that isn't code.

### Deliverable and Demonstration
There are two big deliverables for this project. Code for the server(Hermes,
get it?), and the clients which not only has code for interacting with Hermes,
but also a GUI for interactivity with a user like myself. 

We plan to demonstrate Hermes by running the server code on a remote machine.
We will connect to the server via our PCs running client code. We will ssh into
the remote machine to see the server running. Since Hermes is a multichat anyone
can join in the demonstration by connecting their computers to the remote
machine!

Explain exactly what you'll have at the end. What will it be able to do at the live demo?

What exactly will you produce at the end of the project? A piece of software, yes, but what will it do? Here are some questions to think about (and answer depending on your application).

Will it run on some data, like batch mode? Will you present some analytical results of the processing? How can it be re-run on different source data?

Will it be interactive? Can you show it working? This project involves a live demo, so interactivity is good.


### Evaluation of Results
Evaluating Hermes is very simple. Can at least two clients hold a meaningful
conversation remotely?...

How will you know if you are successful? 
If you include some kind of _quantitative analysis,_ that would be good.

## Architecture Diagram
Upload the architecture diagram you made for your slide presentation to your repository, and include it in-line here.

Create several paragraphs of narrative to explain the pieces and how they interoperate.

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

**Additional instructions for teams of three:** 
* Remember that you must have prior written permission to work in groups of three (specifically, an approved `FP3` team declaration submission).
* The team must nominate a lead. This person is primarily responsible for code integration. This work may be shared, but the team lead has default responsibility.
* The team lead has full partner implementation responsibilities also.
* Identify who is team lead.

In the headings below, replace the silly names and GitHub handles with your actual ones.

### Susan Scheme @susanscheme
will write the....

### Leonard Lambda @lennylambda
will work on...

### Frank Funktions @frankiefunk 
Frank is team lead. Additionally, Frank will work on...   
