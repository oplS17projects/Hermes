#lang racket

(define listener (tcp-listen 8083 5 #t)) ;; listener to service connection requests
;; client attempts to connect. Receives an input and output port
(define-values (client-in client-out) (tcp-connect "localhost" 8083))
;; server accepts the connection request. Also gets a pair of ports
(define-values (server-in server-out) (tcp-accept listener))

;; client sends identifying message
(display (string-append "Client:My name is " "Ibrahim" "\n")
         client-out)
(flush-output client-out) ;; must flush as ports are buffered in racket

;; server receives and reads it
;; cooler if on separate racket instances
(read-line server-in)  ;; --> "Client:My name is #hostname.
;; server replies
(display (string-append "Server:Hi " "Ibrahim" "\n") server-out)
(flush-output server-out) ;; flush flush

;; client displays server message
(read-line client-in)
(close-output-port server-out)
(close-output-port client-out)
(read-line client-in)  ;; --> eof object #eof
(read-line server-in)  ;; --> eof object #eof
(tcp-close listener)
; (custodian-shutdown-all (current-custodian)) ;; release all resources including
                                             ;; tcp, file, custom ports
                                             ;; application exits
