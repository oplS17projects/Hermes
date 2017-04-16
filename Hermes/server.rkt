#lang racket

(require "modules/general.rkt")
(require math/base) ;; for random number generation


;; globals
(define welcome-message "Welcome to Hermes coms. Type your message below")
(define successful-connection-m "Successfully connected to a client. Sending client a welcome message.")

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
   (define (add in out)
    (set! connections (append connections (list (list in out))))
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
; a semaphore to control acess to c-connections
(define connections-s (make-semaphore 1)) ;; control access to connections

; Track received messages in a closure
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
; semaphore to control access to c-messages
(define messages-s (make-semaphore 1))  ;; control access to messages

; two files to store error messages, and channel conversations
(define error-out (open-output-file "/home/pcuser/Hermes/Hermes/error.txt" #:exists 'append))
(define convs-out (open-output-file "/home/pcuser/Hermes/Hermes/conversations.txt" #:exists 'append))
(define error-out-s (make-semaphore 1))
(define convs-out-s (make-semaphore 1))
; TODO finish logging all error related messages to 
(define (serve port-no)
  (define main-cust (make-custodian))
  (parameterize ([current-custodian main-cust])
    (define listener (tcp-listen port-no 5 #t))
    (define (loop)
      (accept-and-handle listener)
      (loop))
    (displayln-safe "Starting up the listener." error-out-s error-out)
    (thread loop)
    (displayln-safe "Listener successfully started." error-out-s error-out)
    ;; Create a thread whose job is to simply call broadcast iteratively
    (thread (lambda ()
              (displayln-safe "Broadcast thread started!\n")
              (let loopb []
                (sleep 0.5)  ;; wait 0.5 secs before beginning to broadcast
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

(define (accept-and-handle listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))
    ; increment number of connections
    (semaphore-wait c-count-s)
    ((c-count 'increment))
    (semaphore-post c-count-s)

    (displayln-safe successful-connection-m)
    (displayln welcome-message out)
    ;; print to server log and client
    (define print-no-users (string-append "Number of users in chat: "
                                          (number->string ((c-count 'current-count)))))
    (displayln print-no-users out)
    (displayln-safe print-no-users convs-out-s convs-out)
    (flush-output out)
    (semaphore-wait connections-s)
    ((c-connections 'add) in out)
    (semaphore-post connections-s)

    ; start a thread to deal with specific client and add descriptor value to the list of threads
    (define threadcom (thread (lambda ()
              (handle in out)))) ; comms between server and particular client

    ;; Watcher thread:
    ;; kills current thread for waiting too long for connection from
    (thread (lambda ()
              (displayln-safe (string-append
                                "Started a thread to kill hanging "
                                "connecting threads"))
              (sleep 1360)
              (custodian-shutdown-all cust)))))

(define (handle in out) 
  ; deals with queueing incoming messages for server to broadcast to all clients
  (define (something-to-say in)
    (define evt-t0 (sync/timeout 60  (read-line-evt in 'linefeed)))
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
           (semaphore-wait messages-s)
           ; append the message to list of messages NO NEED done during broadcast
           ; (displayln-safe evt-t0 convs-out-s convs-out)
           ((c-messages 'add) evt-t0)
           (semaphore-post messages-s)]
          [else
           (displayln-safe "Timeout waiting. Nothing received from client")]))

  ; Executes methods above in another thread
  (thread (lambda ()
            (let loop []
              (something-to-say in)
              ; (sleep 1)
              (loop)))))

; extracts output port from a list pair of input and output port
(define (get-output-port ports)
  (cadr ports))

; extracts input port
(define (get-input-port ports)
  (car ports))

; broadcasts received message from clients periodically
; TODO before broadcasting the message make sure the ports is still open
; no EOF if it is remove client from connections
(define broadcast
  (lambda ()
    (semaphore-wait messages-s)
    (cond [(not (null? ((c-messages 'mes-list))))
        (begin (map
                (lambda (ports)
                  (displayln (first ((c-messages 'mes-list))) (get-output-port ports))
                  (flush-output (get-output-port ports)))
                ((c-connections 'cons-list)))
               (displayln-safe (first ((c-messages 'mes-list))) convs-out-s convs-out)
               ;; remove top message
               ((c-messages 'remove-top))
               (displayln "Message broadcasted"))])
    (semaphore-post messages-s)))

; TODO move to its own file
(define stop (serve 4321)) ;; start server then close with stop
(displayln-safe "Server process started\n" error-out-s error-out)
