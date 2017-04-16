#lang racket

(require "modules/general.rkt")
(require math/base) ;; for random number generation
;; TODO clean up string message output and alignment
;; TODO close ports after done
;; i.e. seconds and minutes hours specifically
;; author: Ibrahim Mkusa
;; about: print and read concurrently
;; notes: output may need to be aligned and formatted nicely


; we will  prompt for these in the gui
(define host3 "localhost")
(define port-num 4321)
(define sleep-t 0.1)

; we won't need this. Just me being overzealous
(define hermes-conf (open-output-file "./hermes_client.conf" #:exists'append))
(define hermes-conf-s (make-semaphore 1))

(define convs-out (open-output-file "./convs_client.out" #:exists 'append))
(define convs-out-s (make-semaphore 1))

(define error-out (open-output-file "./error_client.out" #:exists 'append))
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

    ;send the username to the server (username in out)
    (displayln username out)
    (flush-output out)

    (define a (thread
                (lambda ()
                  (displayln-safe "Starting receiver thread." error-out-s error-out)
                  (let loop []
                    (receive-messages in)
                    (sleep sleep-t)
                    (loop)))))
    (define t (thread
                (lambda ()
                  (displayln-safe "Starting sender thread." error-out-s error-out)
                  (let loop []
                    (send-messages username out)
                    (sleep sleep-t)
                    (loop)))))
    (displayln-safe "Now waiting for sender thread." error-out-s error-out)
    (thread-wait t) ;; returns prompt back to drracket
    (displayln-safe "Closing client ports." error-out-s error-out)
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
  ;; read, quits when user types in "quit"
  (define input (read-line))
  ; TODO /quit instead of quit
  (cond ((string=? input "quit")
             (displayln (string-append date-print username " signing out. See ya!") out)
             (flush-output out)
             (close-output-port error-out)
             (close-output-port convs-out)
             (exit)))
  
  (displayln (string-append date-print username ": " input) out)
  (flush-output out))

; receives input from server and displays it to stdout
(define (receive-messages in)
  ; retrieve a message from server
  (define evt (sync (read-line-evt in)))
  
  (cond [(eof-object? evt)
         (displayln-safe "Server connection closed." error-out-s error-out)
         (custodian-shutdown-all main-client-cust)
         ;(exit)
         ]
        [(string? evt)
         (displayln-safe evt convs-out-s convs-out)] ; could time stamp here or to send message
        [else
          (displayln-safe (string-append "Nothing received from server for 2 minutes.") convs-out-s convs-out)]))

(displayln-safe "Starting client." error-out-s error-out)
(define stop-client (client 4321))
