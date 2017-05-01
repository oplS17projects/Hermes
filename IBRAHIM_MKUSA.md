# Hermes - A chat server and client written in Racket

## Ibrahim Mkusa
### April 30, 2017

# Overview
Hermes is a chat server and client written in Racket. One can run the Hermes
server on any machine that is internet accessible. The Hermes clients then
connect to the server from anywhere on the internet. It's inspired by chat
systems and clients like irc.

The goal in building Hermes was to expose myself to several concepts integral to
systems like networking, synchronization, and multitasking.


**Authorship note:** All of the code described here was written by myself.

# Libraries Used
Most libraries and utilities used are part of base Drracket installation and
therefore do not need to be imported.

The date and time modules were used for various time related queries.
The tcp module was used for communication via Transmission Control Protocol.
Concurrency and synchronization modules that provide threads, and semaphores
were also used.

Below are libraries that were not part of base system:

```
(require racket/gui/base)
(require math/base)
```

* The ```racket/gui/base``` library used to build graphical user interface.
* The ```math/base``` library was used for testing purposes. It was used to
generated random numbers.

# Key Code Excerpts

Here is a discussion of the most essential procedures, including a description of how they embody ideas from 
UMass Lowell's COMP.3010 Organization of Programming languages course.

Five examples are shown and they are individually numbered. 

## 1. Tracking client connections using an object and closures.

The following code defines and creates a global object, ```make-connections```
that abstracts client connections. It also creates a semaphore to control access
to ```make-connections``` object.

```
(define (make-connections connections)
  (define (null-cons?)
    (null? connections))
   (define (add username in out)
    (set! connections (append connections (list (list username in out))))
    connections)
   (define (cons-list)
     connections)
   (define (remove-ports in out)
     (set! connections
       (filter 
         (lambda (ports)
           (if (and (eq? in (get-input-port ports))
                    (eq? out (get-output-port ports)))
             #f
             #t))
         connections)))
   (define (dispatch m)
     (cond [(eq? m 'null-cons) null-cons?]
           [(eq? m 'cons-list) cons-list]
           [(eq? m 'remove-ports) remove-ports]
           [(eq? m 'add) add]))
   dispatch)

(define c-connections (make-connections '()))

(define connections-s (make-semaphore 1)) ;; control access to connections
 ```
 When the tcp-listener accepts a connection from a client, the associated input
 output ports along with username  are added as an entry in ```make-connections``` via ```add``` function.
 External functions can operate on the connections by securing the semaphore,
 and then calling ```cons-list``` to expose the underlying list of connections.
 ```remove-ports``` method is also available to remove input output ports from
 managed connections.


 
 
## 2. Tracking received messages via objects and closures.

The code below manages broadcast messages from one client to the rest. It wraps
a list of strings inside an object that has functions similar to ```make-connections``` for
exposing and manipulating the list from external functions. The code creates
```make-messages``` global object and a semaphore to control access to it from
various threads of execution.

```
(define (make-messages messages)
  (define (add message)
    (set! messages (append messages (list message)))
    messages)
  (define (mes-list)
    messages)
  (define (remove-top)
    (set! messages (rest messages))
    messages)
  (define (dispatch m)
    (cond [(eq? m 'add) add]
          [(eq? m 'mes-list) mes-list]
          [(eq? m 'remove-top) remove-top]))
  dispatch)

(define c-messages (make-messages '()))

(define messages-s (make-semaphore 1))  ;; control access to messages
```

## 3. Using map to broadcast messages from client to clients

The ```broadcast``` function is called repeatedly in a loop to extract a message
from ```make-messages``` object, and send it to every other client. It uses the
```make-connections``` objects to extract output port of a client. The ```map```
routine is called on every client in the connections object to send it
a message.

```
(define broadcast
  (lambda ()
    (semaphore-wait messages-s)
    (cond [(not (null? ((c-messages 'mes-list))))
        (map
            (lambda (ports)
              (if (not (port-closed? (get-output-port ports)))
                (begin 
                    (displayln (first ((c-messages 'mes-list))) (get-output-port ports))
                    (flush-output (get-output-port ports)))
                (displayln-safe "Failed to broadcast. Port not open." error-out-s error-out)))
            ((c-connections 'cons-list)))
        (displayln-safe (first ((c-messages 'mes-list))) convs-out-s convs-out)
        ;; remove top message from "queue" after broadcasting
        ((c-messages 'remove-top))
        ; debugging displayln below
        ; (displayln "Message broadcasted")
        ]) ; end of cond
    (semaphore-post messages-s)))
```
After the message is send, the message is removed from the "queue" via the
```remove-top```.

The code snippet below creates a thread that iteratively calls ```broadcast```
every interval, where interval(in secs) is defined by ```sleep-t```.

** note ** : ```sleep``` is very important for making Hermes behave gracefully
in a system. Without it, it would be called at the rate derived from cpu clock
rate. This raises cpu temperatures substantially, and make cause a pre-mature
system shutdown.

```
(thread (lambda ()
              (displayln-safe "Broadcast thread started!")
              (let loopb []
                (sleep sleep-t)  ;; wait 0.2 ~ 0.5 secs before beginning to broadcast
                (broadcast)
                (loopb))))
```

## 4. Filtering a List of connections to find recipient of a whisper

I implemented a whisper functionality, where a user can whisper to any user in
the chat room. The whisper message is only sent to specified user. To implement
this i used ```filter``` over the connections, where the predicate tested whether the
current list item matched that of a specific user.

'''
(define whisper (regexp-match #px"(.*)/whisper\\s+(\\w+)\\s+(.*)" evt-t0))

[whisper
                  (semaphore-wait connections-s)
                  ; get output port for user
                  ; this might be null
                  (define that-user-ports
                    (filter
                     (lambda (ports)
                       (if (string=? (whisper-to whisper) (get-username ports))
                           #t
                           #f))
                     ((c-connections 'cons-list))))
                  ; try to send that user the whisper
                  (if (and (null? that-user-ports)
                           #t) ; #t is placeholder for further checks
                      (begin
                        (displayln "User is unavailable. /color blue" out)
                        (flush-output out))
                      (begin
                        (displayln (string-append "(whisper) "
                                    (whisper-info whisper) (whisper-message whisper))
                                   (get-output-port (car that-user-ports)))
                        (flush-output (get-output-port (car that-user-ports)))))
                  (semaphore-post connections-s)]
'''

The snippet above is part of cond statement that tests contents of input from
clients to determine what the client is trying wants/trying to do. The top-line
is using regexes to determine whether the received message is a whisper or not.



## 5. Selectors for dealing with content of a whisper from clients

Below are are three selectors that help abstract the contents of a whisper
message.



```
; whisper selector for the username and message
(define (whisper-info exp)
  (cadr exp))

(define (whisper-to exp)
  (caddr exp))

(define (whisper-message exp)
  (cadddr exp))
(define (list-all-folders folder-id)
  (let ((this-level (list-folders folder-id)))
    (begin
      (display (length this-level)) (display "... ")
      (append this-level
              (flatten (map list-all-folders (map get-id this-level)))))))
```

```whisper-info``` retrieves the date-time and username info.
```whisper-to``` retrieves the username of the intented recipient of a whisper.
```whisper-message``` retrieves the actual whisper.
