#lang racket
(require math/base) ;; for random number generation

;; globals
;; must control access via semaphore as listener thread or broadcast thread
;; might need to access it
(define connections '())  ;; maintains a list of open ports
;; ((in1, out1), (in2, out2), (in3, out3), (in4, out4) ...)

;; lets keep thread descriptor values
;

(define fair (make-semaphore 1)) ;; managing connections above

(define can-i-broadcast (make-semaphore 1))

;; alternative one keep running list of input and output ports directly
;; broadcasts a message to all connected clients
(define broadcast-message
  (lambda (message connections)
    (map send_message connections)
    'ok))

; port pair -> '(input-port output-port)

(define (get-input-port port-pair)
  (car port-pair))

(define (get-output-port  port-pair)
  (cadr port-pair))

;; gets pair of input and output port of a client and sends a message
(define send-message
  (lambda (client_ports)
    (displayln message (get-output-port (client-ports)))
    (flush-output (get-output-port (client-ports)))
    'ok))


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
    (thread loop))
  (lambda ()
    (displayln "\nGoodbye, shutting down all services\n")
    (custodian-shutdown-all main-cust)))

(define (accept-and-handle listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))
    (semaphore-wait fair)
    ;; keep track of open ports
    (append connections (list (list in out)))
    (semaphore-wait fiar)

    ; thread will communicate to all clients at once in a broadcast
    ; manner
    (thread (lambda ()
              (handle in out) ;; this handles connection with that specific client
              (close-input-port in)
              (close-output-port out)))
    )
  ;; Watcher thread:
  ;; kills current thread for waiting too long for connection from
  ;; clients
  (thread (lambda ()
            (sleep 120)
            (custodian-shutdown-all cust))))

; (define (handle connections)
;   ())
;; each thread needs 2 new threads
(define (handle in out) 
  ; define function to deal with in
  (define (something-to-say in)
    (sync/timeout 4 (read-line-evt in 'linefeed)))
  ; define function to deal with out
  ; thread them each
  ; (server-loop in out)
  (sleep 5) ;; wait 5 seconds to guarantee client has already send message
  (define echo (read-line in)) ;; bind message to echo
  (displayln (string-append echo "\n"))
  ; echo back the message, appending echo
  ; could regex match the input to extract the name
  (writeln  "Admin: Hello there" out) ;; append "echo " to echo and send back
  (flush-output out)
)
;; This is a single server communicating directly to the client

;;;;;;;;;;;;;;;;;;;;;;Server Client communication;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (serve in-port out-port)
  (let loop []
    (define evt (sync/timeout 2
                              (read-line-evt in-port 'any)
                              (thread-receive-evt)))
    (cond
      [(not evt)
       (displayln "Timed out, exiting")
       (tcp-abandon-port in-port)
       (tcp-abandon-port out-port)]
      [(string? evt)
       (fprintf out-port "~a~n" evt) ;; echoes back received string
       (flush-output out-port) ;; flushes the buffer
       (loop)]  ;; iterates again
      [else
        (printf "Received a message in mailbox: ~a~n"
                (thread-receive))
        (loop)])))

(define port-num 4322)
(define (start-server)
  (define listener (tcp-listen port-num))
  (thread
    (lambda ()
      (let loop ()  ;; the server now loops continously listening in for connections
      (define-values [in-port out-port] (tcp-accept listener))
      ;; lets add this open ports to global list of connections
      (semaphore-wait fair)
      (append connections (list (list in-port out-port)))
      (semaphore-post fair)
      (serve in-port out-port) ; could be do the greeting in here
      (loop)))))

(start-server)

(define client-thread
  (thread
    (lambda ()
      (define-values [in-port out-port] (tcp-connect "localhost" port-num))
      
      (display "first\nsecond\nthird\n" out-port)
      (flush-output out-port)
      ; copy-port will block until EOF is read from in-port
      (copy-port in-port (current-output-port)))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; author: Ibrahim Mkusa
;; about: print and read concurrently
;; notes: output may need to be aligned and formatted nicely
;; look into
;; https://docs.racket-lang.org/gui/text-field_.html#%28meth._%28%28%28lib._mred%2Fmain..rkt%29._text-field~25%29._get-editor%29%29

;; create custodian for managing all resources
;; so we can shutdown everything at once
;(define guard (make-custodian (current-custodian)))
;(current-custodian guard)
;; reads values continously from stdin and redisplays them
(define (read-loop)
  (display (read-line))
  (display "\n")
  (read-loop)
  )

(define input-prompt "input: ")
(define output-prompt "output: ")

;; prompt for username and bind to a variable username
(display "What's your name?\n")
(define username (read-line))
(define usernamei (string-append username ": ")) ;; make username appear nicer in a prompt

;; intelligent read, quits when user types in "quit"
(define (read-loop-i)
  
  
  ;(semaphore-wait fair)
  (display usernamei)
  (define input (read-line))
  ;; do something over here with input maybe send it out
  
  ;; Tests input if its a quit then kills all threads
  ;; An if would be better here tbh
  (cond ((string=? input "quit") (begin (kill-thread a)
                                        (kill-thread t))))
  (display (string-append output-prompt input "\n"))
  ;(semaphore-post fair)
  (read-loop-i)
  )


;; print hello world continously
;; "(hello-world)" can be executed as part of background thread
;; that prints in the event there is something in the input port
(define (hello-world)
  (sleep (random-integer 0 15)) ;; sleep between 0 and 15 seconds to simulate coms
                                ;; with server
  ;(semaphore-wait fair)
  ;; we will retrieve the line printed below from the server
  ;; at this time we simulate the input from different users
  (define what-to-print (random-integer 0 2))
  (if (= what-to-print 0)
      (display "Doug: What's up, up?\n")
      (display "Fred: Looking good, good!\n"))
  ;(semaphore-post fair)
  (hello-world))

(define t (thread (lambda ()
                    (read-loop-i))))
(define a (thread (lambda ()
                    (hello-world))))

(thread-wait t) ;; returns prompt back to drracket
;; below doesn't execute
; (sleep 10)
; (kill-thread t)
; (define a (thread (display "hello world!\n")))
; (display "John: hello soso\n")
; (display "Emmanuel: cumbaya!!!!\n")
