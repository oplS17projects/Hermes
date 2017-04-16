#lang racket
(require math/base) ;; for random number generation
;; TODO clean up string message output and alignment
;; i.e. seconds and minutes hours specifically
;; author: Ibrahim Mkusa
;; about: print and read concurrently
;; notes: output may need to be aligned and formatted nicely



(define host "10.0.0.160") ; internal home
(define host2 "67.186.191.81")
(define host3 "localhost")
(define port-num 4321)

(define hermes-conf (open-output-file "./hermes.conf" 'append))
(define hermes-conf-s (make-semaphore 1))

(define convs-out (open-output-file "./convs.out" 'append))
(define convs-out-s (make-semaphore 1))

(define error-out (open-output-file "./error.out" 'append))
(define error-out-s (make-semaphore 1))

; custodian for client connections
(define main-client-cust (make-custodian))
; make connection to server
(define (client port-no)
  (parameterize ([current-custodian main-client-cust])
    ;; connect to server at port 8080
    (define-values (in out) (tcp-connect host3 port-no)) ;; define values
    ;; binds to multiple values akin to unpacking tuples in python

    ; store username to a file for later retrieval along with relevent
    ; info used for authentication with server
    (displayln "What's your name?")
    (define username (read-line))

    (define a (thread
                (lambda ()
                  (displayln "Starting receiver thread.")
                  (let loop []
                    (receive-messages in)
                    (sleep 1)
                    (loop)))))
    (define t (thread
                (lambda ()
                  (displayln "Starting sender thread.")
                  (let loop []
                    (send-messages username out)
                    (sleep 1)
                    (loop)))))
    (displayln "Now waiting for sender thread.")
    (thread-wait t) ;; returns prompt back to drracket
    (displayln "Closing client ports.")
    (close-input-port in)
    (close-output-port out))
    (custodian-shutdown-all main-client-cust))


;; sends a message to the server
(define (send-messages username out)
  ; get current time
  (define date-today (seconds->date (current-seconds) #t))
  ;TODO pad the second if its only 1 character
  (define date-print (string-append (number->string (date-hour date-today))
                                    ":"
                                    (number->string (date-minute date-today))
                                    ":"
                                    (number->string (date-second date-today))
                                    " | "))
  ;; intelligent read, quits when user types in "quit"
  (define input (read-line))
  (cond ((string=? input "quit")
             (displayln (string-append date-print username " signing out. See ya!") out)
             (flush-output out)
             (exit)))
  
  (displayln (string-append date-print username ": " input) out)
  (flush-output out))

; receives input from server and displays it to stdout
(define (receive-messages in)
  ; retrieve a message from server
  (define evt (sync/timeout 60 (read-line-evt in)))
  
  (cond [(eof-object? evt)
         (displayln "Server connection closed.")
         (custodian-shutdown-all main-client-cust)
         ;(exit)
         ]
        [(string? evt)
         (displayln evt)] ; could time stamp here or to send message
        [else
          (displayln (string-append "Nothing received from server for 2 minutes."))]))

(displayln "Starting client.")
(define stop (client 4321))
