#lang racket

;; Both `server' and `accept-and-handle' change
;; to use a custodian.
;; To start server
;; (define stop (client 8080))
;; use your web browser to connect localhost:8080 greeted with "hello world"
;; (stop) to close the server

(define (client port-no)
  (define main-client-cust (make-custodian))
  (parameterize ([current-custodian main-client-cust])
    ;; connect to server at port 8080
    (define-values (in out) (tcp-connect "localhost" port-no)) ;; define values
      ;; binds to multiple values akin to unpacking tuples in python
    (thread (lambda ()
      (send-message in out)
      (close-input-port in)
      (close-output-port out))))
    (sleep 20)
    ; (define (loop)
      ; (write (read-line (current-input-port)) out)
      ; (flush-output out)
      ; (write (read-line in) (current-output-port))
    ; (define listener (tcp-listen port-no 5 #t))
    ; (define (loop)
      ; (accept-and-handle listener)
      ; (loop))
    ; (thread loop)))
    (custodian-shutdown-all main-client-cust)
  #| (lambda () |#
    ; (displayln "Goodbye, shutting down client\n")
    #| (custodian-shutdown-all main-client-cust)) |#)

(define (send-message input-port output-port)
 (writeln "Doug: Hello, how's it going?" output-port)
 (flush-output output-port) ;; ports are buffered in racket must flush or you
    ;; will read #eof
 (sleep 10) ;; wait 10 seconds
 (define serv-message (read-line input-port))
 (displayln serv-message) ;; read the servers replay message which is original
    ;; with echo appended to it
 )
