#lang racket
(require math/base) ;; for random number generation

;; globals
;; must control access via semaphore as listener thread or broadcast thread
;; might need to access it
(define connections '())  ;; maintains a list of open ports
;; ((in1, out1), (in2, out2), (in3, out3), (in4, out4) ...)
(define connections-s (make-semaphore 1)) ;; control access to connections

;; every 5 seconds run to broadcast top message in list
;; and remove it from list
(define messages-s (make-semaphore 1))  ;; control access to messages
(define messages '("hello, world!"))  ;; stores a list of messages(strings) from currents

(define threads-s (make-semaphore 1))  ;; control access to threads
;; lets keep thread descriptor values
(define threads '())  ;; stores a list of client serving threads as thread descriptor values



;;

;; This is a relay server making two clients communicate
;; Both `server' and `accept-and-handle' change
;; to use a custodian.
;; To start server
;; (define stop (serve 8080))
;; (stop) to close the server

(define (serve port-no)
  (define main-cust (make-custodian))
  (parameterize ([current-custodian main-cust])
    (define listener (tcp-listen port-no 5 #t))
    (define (loop)
      (accept-and-handle listener)
      (loop))
    (thread loop)
    ;; Create a thread whose job is to simply call broadcast iteratively
    (thread (lambda ()
              (let loopb []
                (sleep 30)  ;; wait 30 secs before beginning to broadcast
                (broadcast)
                (sleep 10) ;; sleep for 10 seconds between broadcasts
                (loopb)))))
  (lambda ()
    (displayln "\nGoodbye, shutting down all services\n")
    (custodian-shutdown-all main-cust)))

(define (accept-and-handle listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))
    ; discard request header
    ; Discard the request header (up to blank line):
    (regexp-match #rx"(\r\n|^)\r\n" in)
    (semaphore-wait connections-s)
    ;; keep track of open ports
    (set! connections (append connections (list (list in out))))
    (semaphore-post connections-s)

    ; start a thread to deal with specific client and add descriptor value to the list of threads
    (set! threads (append threads (list (thread (lambda ()
              (handle in out) ;; this handles connection with that specific client
              (close-input-port in)
              (close-output-port out))))
            )
    ) 
  ;; Watcher thread:
  ;; kills current thread for waiting too long for connection from
  ;; clients
  (thread (lambda ()
            (sleep 360)
            (custodian-shutdown-all cust)))))

; (define (handle connections)
;   ())
;; each thread needs 2 new threads
(define (handle in out) 
  ; define function to deal with incoming messages from client
  (define (something-to-say in)
    (define evt-t0 (sync/timeout 30  (read-line-evt in 'linefeed)))
    (cond [(eof-object? evt-t0)
           (displayln (string-append "Connection closed " (current-thread) "exiting"))
           (exit)
           ]
          [(string? evt-t0)
           (semaphore-wait messages-s)
           ; append the message to list of messages
           (display (string-append evt-t0 "\n"))
           (set! messages (append messages (list evt-t0)))
           (semaphore-post messages-s)]
          [else
           (displayln (string-append "Nothing received from " (current-thread)))]))


  ; define function to deal with out
  (define (something-to-send out)
    (define evt-t1 (sync/timeout 120 (thread-receive-evt)))
    ;; send message to client
    (fprintf out "~a~n" (thread-receive))
    (flush-output out)
    )
  ; thread them each

  ;; i could bind to values, and call wait on them
  ;; thread that deals with incoming messages for that particular thread
  (thread (lambda ()
            (let loop []
              (something-to-say in)
              (sleep 1)
              (loop))))

  (thread (lambda ()
            (let loop []
              (something-to-send out)
              (sleep 1)
              (loop))))
  ; (server-loop in out)
  ; (sleep 5) ;; wait 5 seconds to guarantee client has already send message
  'ok
 )

;; define a broadcast function
(define broadcast
  (lambda ()
    (semaphore-wait messages-s)
    (semaphore-wait threads-s)
    (if (not (null? messages))
        (begin (map (lambda (thread-descriptor)
            (thread-send thread-descriptor (first messages)))
                    threads)
               (set! messages (rest messages))
        )
      (display "No message to display\n") ; for later create file port for errors and save error messages to that file
      )
    (semaphore-post threads-s)
    (semaphore-post messages-s)))

(define stop (serve 4321)) ;; start server then close with stop