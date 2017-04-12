#lang racket
(require math/base) ;; for random number generation
;; TODO clean up string message output and alignment
;; author: Ibrahim Mkusa
;; about: print and read concurrently
;; notes: output may need to be aligned and formatted nicely
;; look into
;; https://docs.racket-lang.org/gui/text-field_.html#%28meth._%28%28%28lib._mred%2Fmain..rkt%29._text-field~25%29._get-editor%29%29


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

  ; (thread (lambda ()
    ;; make threads 2 lines
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


;; the send-messages
(define (send-messages username out)
  ;; intelligent read, quits when user types in "quit"
  ;(semaphore-wait fair)
  ; (display usernamei)
  (define input (read-line))
  ;; do something over here with input maybe send it out
  
  ;; Tests input if its a quit then kills all threads
  ;; An if would be better here tbh
  ;; (cond ((string=? input "quit") (begin (kill-thread a)
                                        ;(kill-thread t))))
  (cond ((string=? input "quit") (exit)))
  ;; modify to send messages to out port 
  (displayln (string-append username ": " input) out)
  (flush-output out)

  ;(semaphore-post fair)
  ; (read-loop-i out)
)



;; print hello world continously
;; "(hello-world)" can be executed as part of background thread
;; that prints in the event there is something in the input port
(define (receive-messages in)
  ; (sleep (random-integer 0 15)) ;; sleep between 0 and 15 seconds to simulate coms
                                ;; with server
  ;(semaphore-wait fair)
  ;; we will retrieve the line printed below from the server
  (define evt (sync/timeout 60 (read-line-evt in)))
  (cond [(eof-object? evt)
         (displayln "Server connection closed.")
         (custodian-shutdown-all main-client-cust)
         ;(exit)
         ]
        [(string? evt)
         (displayln evt)] ; could time stamp here or to send message
        [else
          (displayln (string-append "Nothing received from server for 2 minutes."))]
        )
  ;(semaphore-post fair)
) 

(define stop (client 4321))
(displayln "Client started.")

