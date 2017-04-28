# Hermes project report

## Douglas Richardson
### April 28, 2017

# Overview
Hermes is a multi-user chat program that allows users to setup a server, connect to it
and communicate with all other members of the server.

Hermes uses TCP pipes to tread input and output like a port. Essentially, each client sends
information to the server and depending on the input, the server decides what to do with it
and usually sends output back to all the other users.

# Libraries Used
The code uses two non-default libraries:

```
(require racket/gui/base)
(require math/base)
```

* The ```racket/gui/base``` library is the primary library for the GUI.
* the ```math/base``` is used for random number generation.

# Key Code Excerpts

Here is a discussion of the most essential procedures, including a description of how they embody ideas from 
UMass Lowell's COMP.3010 Organization of Programming languages course.

Five examples are shown and they are individually numbered. 

## 1. Initializing the gui

This line of code allows us to wrap the gui into an object.

```
(define (make-gui)
      ...
      (cond ((eq? command 'show) (lambda () (send main-frame show #t)))
            ((eq? command 'get-color) get-my-color)
            ((eq? command 'set-color) set-color)
            ((eq? command 'prompt-color) prompt-color)
            ((eq? command 'prompt-username) prompt-username)
            ((eq? command 'prompt-hostname) prompt-hostname)
            ((eq? command 'send) send-message) ;; call to show a message in a gui
            ((eq? command 'set-name) (lambda (newname) (if (string? newname)
                                                  (set! name newname)
                                                  (print "Thats not good"))))
            ; ((eq? command 'recieve-message) user-message)
            ; ((eq? command 'get-list) listy)
            ; ((eq? command 'set-list) update)
            ;;Something up with that
            ; else should assume a message and output to screen we do not want it
            ; to fail
            ((eq? command 'get-message) get-message)
            (else (error "Invalid Request" command))
            ))
    ;;dispatch goes below that
    dispatch)```

This allows us to make our code simpler and lets us treat the gui like an object in it's self.
Giving the gui commands to change it's self rather than having to remember all the commands it has.

## 2. Working with lists

This code is code that allows us to append a new message onto the end of the list of messages using recursion

```
(define (appendlist listoflist add-to-end)
  (if (null? listoflist)
      (cons add-to-end '())
      (cons (car listoflist) (appendlist (cdr listoflist) add-to-end))))```
      
Normally there is a function to just append onto the end of a list, however the problem is that if we attempt to append
a list of elements onto the end of a list, it just appends the elements onto the end of the list. For example if I had
a list of the following '(("Doug" "Hello World!" "Purple")) 
and wanted to append the list '("Gordon" "No one else is here Doug." "Black") The list I want back would be
'(("Doug" "Hello World!" "Purple")("Gordon" "No one else is here Doug." "Black")) but if I use the default
list append I get'(("Doug" "Hello World!" "Purple")"Gordon" "No one else is here Doug." "Black")
which is no good for the gui.

This follows on our idea of working with lists and using recursion to walk down a list.

## 3. Re-drawing messages

The following procedure is used to re-draw messages onto the canvas after a screen move or resize.

```
    (define (update-helper given-list)
      (if (null? given-list)
          '()
          (if (null? (car given-list))
              '()
              (begin (user-message
                      (get-username-from-list (car given-list))
                      (get-message-from-list (car given-list))
                      (get-color-from-list (car given-list)))
                     (update-helper (cdr given-list))))))```

While it doesn't actually use the map function, this is a map as for every element of a list (each element is a list of three strings)
it runs a procedure (or in this case a set of procedures) in the order of the list.

## 4. Parsing Messages

This line of code is used to parse a single string message into a three string message

```
    (define (user-message-parse string-i start)
        (define (helper str index)
          (if (eq? (string-ref str (+ start index)) #\~) ; regexes would allow us
                                                         ; to avoid this #\~
              (substring str start (+ start index))
              (helper str (+ index 1))))
        (helper string-i 0))```

This was used to parse a string into smaller strings. In hermes we can only send one string to each client at one time, therefore
the three elements that the gui uses to print messages need to be compressed together. We append a ~ inbetween each of these so we can
parse them out at the client end. 

While we don't run any commands off it (saved that part for the commands we do interpret from strings) 
it is similar to the symbolic differentaitor.

## 5. Color setting
 Here we have an example of when we use a symbolic differentiator in the gui to determine when a user wants to run a command
 rather than input text.
 
 ```
 (define (button-do-stuff b e);b and e do nothing :/
    (if (color-change-request? (send input get-value))
        (set! my-color (get-color-from-input (send input get-value)))
...
 
 (define (color-change-request? given-string)
  (if (> (string-length given-string) 7)
      (if (equal? (substring given-string 0 6) "/color")
          #t
          #f)
      #f))```

The procedure button-do-stuff is run every time the user presses the return key or presses the send button on the gui
and what it will do is check to see if the user typed in "/color", and if they did it sets the internal color to be 
what the user said after that. This is part of our symbolic differentiator that allows the user to use commands
rather than the typical use of the input (which is just to send a message to other clients)

