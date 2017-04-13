#lang racket
(require math/base) ;; for random number generation

;; TODO wrap "safer send in a function that takes care of semaphores"

;; globals
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

(define connections-s (make-semaphore 1)) ;; control access to connections

;; every 5 seconds run to broadcast top message in list
;; and remove it from list
(define messages-s (make-semaphore 1))  ;; control access to messages
(define messages '())  ;; stores a list of messages(strings) from currents

(define threads-s (make-semaphore 1))  ;; control access to threads
;; lets keep thread descriptor values
(define threads '())  ;; stores a list of client serving threads as thread descriptor values

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
                      "Successfully connected to a client.\n"
                      "Sending client a welcome message.")
                    stdout)
    (displayln "Welcome to Hermes coms\nType your message below" out)
    (flush-output out)
    (semaphore-wait connections-s)
    ; (set! connections (append connections (list (list in out))))
    ((c-connections 'add) in out)
    (semaphore-post connections-s)

    ; start a thread to deal with specific client and add descriptor value to the list of threads
    (semaphore-wait threads-s)
    (define threadcom (thread (lambda ()
              (handle in out)))) ; comms between server and particular client
    (set! threads (append threads (list threadcom)))
    (semaphore-post threads-s)

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
           (set! messages (append messages (list evt-t0)))
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
    (cond [(not (null? messages))
        (begin (map
                (lambda (ports)
                  (displayln (first messages) (get-output-port ports))
                  (flush-output (get-output-port ports)))
                ((c-connections 'cons-list)))
               ;; remove top message
               (set! messages (rest messages))
               (displayln "Message broadcasted"))])
    (semaphore-post messages-s)))

; TODO move to its own file
(define stop (serve 4321)) ;; start server then close with stop
(display "Server process started\n")
