#lang racket
; Author: Ibrahim Mkusa
; About: code that powers Hermes server


(require "modules/general.rkt") ;; common function(s)
(require math/base) ;; for random number generation


;; server messages in blue
(define welcome-message "Welcome to Hermes coms. Type your message below /color blue ")
(define successful-connection-m "Successfully connected to a client. Sending client a welcome message. /color blue ")

(define sleep-t 0.1)

; track number of connections with closure
(define (make-count no-count)
  (define (increment)
    (set! no-count (+ no-count 1))
    no-count)
  (define (decrement)
    (set! no-count (- no-count 1))
    no-count)
  (define (current-count)
    no-count)
  (define (dispatch m)
    (cond [(eq? m 'increment) increment]
          [(eq? m 'decrement) decrement]
          [(eq? m 'current-count) current-count]))
  dispatch)
(define c-count (make-count 0))
; a semaphore to control access to c-count
(define c-count-s (make-semaphore 1))


; track list of input output port pairs in a list contained in a closure
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
; "instantiate" to track the connections
(define c-connections (make-connections '()))
; a semaphore to control acess to c-connections
(define connections-s (make-semaphore 1)) ;; control access to connections

; Track received messages in a closure. Initialy messages is '()
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
; "instantiate" a make-message variable to track our messages
(define c-messages (make-messages '()))
; semaphore to control access to c-messages
(define messages-s (make-semaphore 1))  ;; control access to messages

; two files to store error messages, and channel conversations
(define error-out (open-output-file "./error_server.txt" #:exists 'append))
(define convs-out (open-output-file "./conversations_server.txt" #:exists 'append))
(define error-out-s (make-semaphore 1))
(define convs-out-s (make-semaphore 1))

; Main server code wrapped in a function
(define (serve port-no)
  ; custodian manages resources put under its domain
  (define main-cust (make-custodian))
  ; "parameterize" puts resources under the domain of created custodian
  (parameterize ([current-custodian main-cust])
    (define listener (tcp-listen port-no 5 #t))
    (define (loop)
      (receive-clients listener)
      (loop))
    (displayln-safe "Starting up the listener." error-out-s error-out)
    (thread loop)
    (displayln-safe "Listener successfully started." error-out-s error-out)
    ;; Create a thread whose job is to simply call broadcast iteratively
    (thread (lambda ()
              (displayln-safe "Broadcast thread started!\n")
              (let loopb []
                (sleep sleep-t)  ;; wait 0.5 secs before beginning to broadcast
                (broadcast)
                (loopb)))))
  (lambda ()
    (displayln-safe "Goodbye, shutting down all services" error-out-s error-out)
    (semaphore-wait error-out-s)
    (semaphore-wait convs-out-s)
    (close-output-port error-out)
    (close-output-port convs-out)
    (semaphore-post error-out-s)
    (semaphore-post convs-out-s)
    (custodian-shutdown-all main-cust)))

(define (receive-clients listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))

    ; TODO do some error checking
    (define username-evt (sync (read-line-evt in 'linefeed)))
    

    
    ; increment number of connections
    (semaphore-wait c-count-s)
    ((c-count 'increment))
    (semaphore-post c-count-s)

    (displayln-safe successful-connection-m)
    (displayln welcome-message out)
    ;; print to server log and client
    (define print-no-users (string-append "Number of users in chat: "
                                          (number->string ((c-count 'current-count)))
                                          " /color blue"))
    (displayln print-no-users out)
    (displayln-safe print-no-users convs-out-s convs-out)
    (flush-output out)
    (semaphore-wait connections-s)
    ; TODO add in a username so we have (username input output)
    ((c-connections 'add) username-evt in out)
    (semaphore-post connections-s)

    ; start a thread to deal with specific client and add descriptor value to the list of threads
    (define threadcom (thread (lambda ()
              (chat_with_client in out)))) ; comms between server and particular client

    ;; Watcher thread:
    ;; kills current thread for waiting too long for connection from
    (thread (lambda ()
              (displayln-safe (string-append
                                "Started a thread to kill hanging "
                                "connecting threads"))
              (sleep 1360)
              (custodian-shutdown-all cust)))))

; whisper selector for the username and message
(define (whisper-info exp)
  (cadr exp))

(define (whisper-to exp)
  (caddr exp))

(define (whisper-message exp)
  (cadddr exp))

(define (chat_with_client in out) 
  ; deals with queueing incoming messages for server to broadcast to all clients
  (define (something-to-say in)
    (define evt-t0 (sync  (read-line-evt in 'linefeed)))
    (cond [(eof-object? evt-t0)
           (semaphore-wait connections-s)
           ((c-connections 'remove-ports) in out)
           (semaphore-post connections-s)
           ; TODO some form of identification for this client
           (displayln-safe "Connection closed. EOF received" error-out-s error-out)
           (semaphore-wait c-count-s)
           ((c-count 'decrement))
           (semaphore-post c-count-s)
           ;(exit)
           (kill-thread (current-thread))]
          [(string? evt-t0)
           ; use regexes to evaluate received input from client
           (define whisper (regexp-match #px"(.*)/whisper\\s+(\\w+)\\s+(.*)" evt-t0)) ; is client trying to whisper to someone
           (define list-count  (regexp-match #px"(.*)/list\\s+count\\s*" evt-t0)) ;; is client asking for number of logged in users
           (define list-users (regexp-match #px"(.*)/list\\s+users\\s*" evt-t0)) ;; user names
           ; do something whether it was a message, a whisper, request for number of users and so on

           
           (cond [whisper
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
                        (displayln (string-append "(whisper)"
                                    (whisper-info whisper) (whisper-message whisper))
                                   (get-output-port (car that-user-ports)))
                        (flush-output (get-output-port (car that-user-ports)))))
                  (semaphore-post connections-s)]
                 [list-count
                  ;;should put a semaphore on connections
                  (semaphore-wait c-count-s)
                  (semaphore-wait connections-s)
                  (define no-of-users (string-append "Number of users in chat: "
                                          (number->string ((c-count 'current-count)))
                                          " /color blue"))
                  (displayln no-of-users out)
                  (flush-output out)
                  (semaphore-post connections-s)
                  (semaphore-post c-count-s)
                  ]
                 [list-users
                  (semaphore-wait connections-s)
                  ; map over connections sending the username to the client
                  (displayln "Here is a list of users in chat. /color blue" out)
                  (map
                   (lambda (ports)
                     (displayln (string-append (get-username ports) " /color blue") out))
                   ((c-connections 'cons-list)))
                  (flush-output out)
                  (semaphore-post connections-s)]
                 [else
                  ; Its an ordinarly message
                  ; (displayln-safe evt-t0) debug purposes
                  (semaphore-wait messages-s)
                  ; evaluate it .
                  ((c-messages 'add) evt-t0)
                  (semaphore-post messages-s)])]    
          [else
           (displayln-safe "Timeout waiting. Nothing received from client")]))

  ; Executes methods above in another thread
  (thread (lambda ()
            (let loop []
              (something-to-say in)
              ; (sleep 1)
              (loop)))))

; extracts output port from a list pair of username, input and output port
(define (get-output-port ports)
  (caddr ports))

; extracts input port
(define (get-input-port ports)
  (cadr ports))

; extract username
(define (get-username ports)
  (car ports))

; broadcasts received message from clients periodically
; TODO before broadcasting the message make sure the ports is still open
; no EOF if it is remove client from connections
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

(define stop-server (serve 4321)) ;; start server then close with stop
(displayln-safe "Server process started\n" error-out-s error-out)
