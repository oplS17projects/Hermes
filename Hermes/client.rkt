#lang racket
; Author: Ibrahim Mkusa
; About: code that enables communication with the client. It uses GUI code
; authored by Doug-Richardson


(require "modules/general.rkt" "GUI.rkt")
(require math/base) ;; for random number generation
;; TODO clean up string message output and alignment
;; TODO close ports after done
;; i.e. seconds and minutes hours specifically
;; author: Ibrahim Mkusa
;; about: print and read concurrently
;; notes: output may need to be aligned and formatted nicely


(define hermes-gui (make-gui)) ;; our gui
((hermes-gui 'show))
;(sleep 0.25)


; (define host3 "localhost")
(define hostname ((hermes-gui 'prompt-hostname))) 
(define port-num 4321)
(define sleep-t 0.1)

(define hermes-gui-s (make-semaphore 1))

; we won't need this. Just me being overzealous
(define hermes-conf (open-output-file "./hermes_client.conf" #:exists 'append))
(define hermes-conf-s (make-semaphore 1))

(define convs-out (open-output-file "./convs_client.out" #:exists 'append))
(define convs-out-s (make-semaphore 1))

(define error-out (open-output-file "./error_client.out" #:exists 'append))
(define error-out-s (make-semaphore 1))

; custodian for client connections. Define at top level since a function needs
; to see it
(define main-client-cust (make-custodian))
; make connection to server
(define (client port-no)
  (parameterize ([current-custodian main-client-cust])
    ;; connect to server at port 8080
    ;; TODO catch error here
    (define-values (in out) (tcp-connect hostname port-no)) ;; define values
    ;; binds to multiple values akin to unpacking tuples in python

    ;; TODO could store theses info in a file for retrieval later
    (define username ((hermes-gui 'prompt-username)))
    ((hermes-gui 'prompt-color))

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
    ; (thread-wait t) ;; returns prompt back to drracket
    )

  (lambda ()
    (displayln-safe "Closing client ports." error-out-s error-out)
    ;(close-input-port in)
    ;(close-output-port out)
    (custodian-shutdown-all main-client-cust)))


;; sends a message to the server
(define (send-messages username out)
  ; get current time
  (define date-today (seconds->date (current-seconds) #t))
  ;TODO pad the second if its only 1 character
  (define date-print (string-append (pad-date (number->string (date-hour date-today)))
                                    ":"
                                    (pad-date (number->string (date-minute date-today)))
                                    ":"
                                    (pad-date (number->string (date-second date-today)))
                                    " | "))
  ;; read, quits when user types in "quit"
  ;; TODO read from GUI instead
  ;(define input (read-line))
  ;(semaphore-wait hermes-gui-s)
  (define input ((hermes-gui 'get-message)))
  ;(semaphore-post hermes-gui-s)
  
  ; /color color is appended to input to specify the color the message should
  ; be displayed in
  (cond ((string=? input "/quit")
             (displayln (string-append date-print username " signing out. See ya!"
                                       " /color " ((hermes-gui 'get-color))) out)
             (flush-output out)
             (close-output-port error-out)
             (close-output-port convs-out)
             ;(custodian-shutdown-all main-client-cust)
             (exit)))
  
  (displayln (string-append date-print username ": " input
                            " /color " ((hermes-gui 'get-color))) out)
  (flush-output out))

; a wrap around to call ((hermes-gui 'send) zzz yyy) without complaints from
; drracket
(define send-to-gui
  (lambda (message color)
    ((hermes-gui 'send) message color)))

; receives input from server and displays it to stdout
(define (receive-messages in)
  ; retrieve a message from server
  (define evt (sync (read-line-evt in)))
  
  (cond [(eof-object? evt)
         (displayln-safe "Server connection closed." error-out-s error-out)
         (exit)
         ;(custodian-shutdown-all main-client-cust)
         ;(exit)
         ]
        [(string? evt)
            (displayln-safe evt convs-out-s convs-out)
            (define evt-matched
              (regexp-match #px"(.*)\\s+/color\\s+(\\w+).*"
                            evt))
            ; TODO set color to current client if the message is from him
            ; otherwise set it to the remote
            ;(semaphore-wait hermes-gui-s)
            ;(send-to-gui evt ((hermes-gui 'get-color)))
            
            ; extracts the message and color from received message
            (send-to-gui (cadr evt-matched) (caddr evt-matched))
            ;(semaphore-post hermes-gui-s)
            ] ; could time stamp here or to send message
        [else
          (displayln-safe (string-append "Nothing received from server for 2 minutes.") convs-out-s convs-out)]))

(displayln-safe "Starting client." error-out-s error-out)
(define stop-client (client 4321))
;(define stop-client (client 4321))
; we will  prompt for these in the gui

