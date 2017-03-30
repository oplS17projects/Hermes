#lang racket

;; Both `server' and `accept-and-handle' change
;; to use a custodian.
;; To start server
;; (define stop (serve 8080))
;; use your web browser to connect localhost:8080 greeted with "hello world"
;; (stop) to close the server

(define (serve port-no)
  (define main-cust (make-custodian))
  (parameterize ([current-custodian main-cust])
    (define listener (tcp-listen port-no 5 #t))
    (define (loop)
      (accept-and-handle listener)
      (loop))
    (thread loop))
  (lambda ()
    (displayln "\nGoodbye, shutting down all services\n")
    (custodian-shutdown-all main-cust)))

(define (accept-and-handle listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))
    (thread (lambda ()
              (handle in out) ;; this handles connection with that specific client
              (close-input-port in)
              (close-output-port out))))
  ;; Watcher thread:
  (thread (lambda ()
            (sleep 120)
            (custodian-shutdown-all cust))))

(define (handle in out) 
  ; (server-loop in out)
  (sleep 5) ;; wait 5 seconds to guarantee client has already send message
  (define echo (read-line in)) ;; bind message to echo
  (displayln (string-append echo "\n"))
  ; echo back the message, appending echo
  ; could regex match the input to extract the name
  (writeln  "Admin: Hello there" out) ;; append "echo " to echo and send back
  (flush-output out)
)

(define input-prompt "Hermes: ")

(define (server-loop in out)
  (define echo (read-line in))
  (displayln echo)
  (display ">>> ")

  (define input (read))
  (writeln (string-append "Admin: " input) out)
  (flush-output out)
  ; (sleep 10)
  (server-loop in out))

