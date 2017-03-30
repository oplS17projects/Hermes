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
    ; (thread (lambda ()
      (chat in out)
      (close-input-port in)
      (close-output-port out))
      (custodian-shutdown-all main-client-cust))

    ; (sleep 60)  ;; run for 3 minutes then close
    ; (define (loop)
      ; (write (read-line (current-input-port)) out)
      ; (flush-output out)
      ; (write (read-line in) (current-output-port))
    ; (define listener (tcp-listen port-no 5 #t))
    ; (define (loop)
      ; (accept-and-handle listener)
      ; (loop))
    ; (thread loop)))
    ; (custodian-shutdown-all main-client-cust)
  #| (lambda () |#
    ; (displayln "Goodbye, shutting down client\n")
    #| (custodian-shutdown-all main-client-cust)) |#

(define (chat in out)
 ; (driver-loop in out)
 (writeln "Ibrahim: Hello, anyone in chat?" out)
 (flush-output out) ;; ports are buffered in racket must flush or you
    ;; will read #eof
 (sleep 10) ;; wait 10 seconds
 (define serv-message (read-line in))
 (displayln serv-message) ;; read the servers replay message which is original
    ;; with echo appended to it
 )

; (define input-prompt "Hermes: ")

(define (driver-loop in out)
  ; (prompt-for-input input-prompt)
  (display ">>> ")
  (define input (read))
  (writeln (string-append "Ibrahim: " input) out)
  (flush-output out)
  ; (sleep 10)
  (define output (read-line in))
  (displayln output)
  (driver-loop in out))


#|   (let ((input (read))) |#
;     )
;   (let ((input (read)))
;     (let ((output (mc-eval input the-global-environment)))
;       (announce-output output-prompt)
;       (user-print output)))
;   (driver-loop))
;
; (define (announce-output string)
;   (display string))
#|  |#
