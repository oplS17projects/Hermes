#lang racket
(require math/base) ;; for random number generation

;; a proof of concept
;; one thread waits for input
;; another displays messages in the background


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
(define fair (make-semaphore 1))

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
