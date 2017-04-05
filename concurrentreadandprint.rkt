#lang racket
;; author: Ibrahim Mkusa
;; about: print and read concurrently

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
  (display usernamei)
  
  (semaphore-wait fair)
  (define input (read-line))
  ;; do something over here with input maybe send it out
  (cond ((string=? input "quit") (exit)))
  (display (string-append output-prompt input "\n"))
  (semaphore-post fair)
  (read-loop-i)
  )


;; print hello world continously
(define (hello-world)
  (semaphore-wait fair)
  (display "Hello, World!\n")
  (semaphore-post fair)
  (hello-world))

(define t (thread (lambda ()
                    (read-loop-i))))
(define a (thread (lambda ()
                    (hello-world))))
;; below doesn't execute
; (sleep 10)
; (kill-thread t)
; (define a (thread (display "hello world!\n")))
; (display "John: hello soso\n")
; (display "Emmanuel: cumbaya!!!!\n")