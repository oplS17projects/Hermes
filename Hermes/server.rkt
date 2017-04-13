#lang racket
(require math/base) ;; for random number generation

;; globals
(define welcome-message "Welcome to Hermes coms. Type your message below")
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
   (define (dispatch m)
     (cond [(eq? m 'null-cons) null-cons?]
           [(eq? m 'cons-list) cons-list]
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

;; Several threads may want to print to stdout, so  lets make things civil
(define stdout (make-semaphore 1))

; Takes a string and a semaphore to print safely to stdout
(define displayln-safe
  (lambda (a-string a-semaphore)
    (semaphore-wait a-semaphore)
    (displayln a-string)
    (semaphore-post a-semaphore)))


(define (serve port-no)
  (define main-cust (make-custodian))
  (parameterize ([current-custodian main-cust])
    (define listener (tcp-listen port-no 5 #t))
    (define (loop)
      (accept-and-handle listener)
      (loop))
    (displayln "threading the listener")
    (thread loop)
    ;; Create a thread whose job is to simply call broadcast iteratively
    (thread (lambda ()
              (displayln-safe "Broadcast thread started!\n" stdout)
              (let loopb []
                (sleep 0.5)  ;; wait 0.5 secs before beginning to broadcast
                (broadcast)
                (loopb)))))
  (lambda ()
    (displayln "\nGoodbye, shutting down all services\n")
    (custodian-shutdown-all main-cust)))

(define (accept-and-handle listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))
    ; increment number of connections
    (semaphore-wait c-count-s)
    ((c-count 'increment))
    (semaphore-post c-count-s)

    (displayln-safe (string-append
                      "Successfully connected to a client. "
                      "Sending client a welcome message.")
                    stdout)
    (displayln welcome-message out)
    ;; print to server log and client
    (define print-no-users (string-append "Number of users in chat: "
                                          (number->string ((c-count 'current-count)))))
    (displayln print-no-users out)
    (displayln-safe print-no-users stdout)
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
                                "connecting threads") stdout)
              (sleep 1360)
              (custodian-shutdown-all cust)))))

(define (handle in out) 
  ; deals with queueing incoming messages for server to broadcast to all clients
  (define (something-to-say in)
    (define evt-t0 (sync/timeout 60  (read-line-evt in 'linefeed)))
    (cond [(eof-object? evt-t0)
           (displayln-safe "Connection closed. EOF received"
                           stdout)
           (semaphore-wait c-count-s)
           ((c-count 'decrement))
           (semaphore-post c-count-s)
           ;(exit)
           (kill-thread (current-thread))]
          [(string? evt-t0)
           (semaphore-wait messages-s)
           ; append the message to list of messages
           (display (string-append evt-t0 "\n"))
           ((c-messages 'add) evt-t0)
           (semaphore-post messages-s)]
          [else
           (displayln-safe "Timeout waiting. Nothing received from client" stdout)]))

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
(define broadcast
  (lambda ()
    (semaphore-wait messages-s)
    (cond [(not (null? ((c-messages 'mes-list))))
        (begin (map
                (lambda (ports)
                  (displayln (first ((c-messages 'mes-list))) (get-output-port ports))
                  (flush-output (get-output-port ports)))
                ((c-connections 'cons-list)))
               ;; remove top message
               ((c-messages 'remove-top))
               (displayln "Message broadcasted"))])
    (semaphore-post messages-s)))

; TODO move to its own file
(define stop (serve 4321)) ;; start server then close with stop
(display "Server process started\n")
