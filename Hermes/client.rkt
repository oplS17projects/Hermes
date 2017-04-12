#lang racket
(require math/base) ;; for random number generation
;; TODO clean up string message output and alignment
;; author: Ibrahim Mkusa
;; about: print and read concurrently
;; notes: output may need to be aligned and formatted nicely


; custodian for client connections
(define main-client-cust (make-custodian))
; make connection to server
(define (client port-no)
  (parameterize ([current-custodian main-client-cust])
    ;; connect to server at port 8080
    (define-values (in out) (tcp-connect "localhost" port-no)) ;; define values
    (display in)
    (displayln out)
    ;; binds to multiple values akin to unpacking tuples in python
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
  ;; intelligent read, quits when user types in "quit"
  (define input (read-line))
  (cond ((string=? input "quit") (exit)))
  (displayln (string-append username ": " input) out)
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

(define stop (client 4321))
(displayln "Client started.")
