#lang racket
(require math/base) ;; for random number generation

(define listener (tcp-listen 4326 5 #t))
(define a (thread (lambda ()
          (define-values (s-in s-out) (tcp-accept listener))
          ; Discard the request header (up to blank line):
          ;(regexp-match #rx"(\r\n|^)\r\n" s-in)
          (sleep 10) 
          (define (echo)
            (define input (read-line s-in))
            (displayln input s-out)
            (flush-output s-out)
            (if (eof-object? input)
                (displayln "Done talking\n")
                (echo)))
          (echo)
          (close-input-port s-in)
          (close-output-port s-out)
          (tcp-close listener)
          'ok)))

(define t (thread (lambda ()
          (define-values (c-in c-out) (tcp-connect "localhost" 4326))
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
            ; (display usernamei)
            (define input (read-line))
            ;; do something over here with input maybe send it out
            
            ;; Tests input if its a quit then kills all threads
            ;; An if would be better here tbh
            (cond ((string=? input "quit") (exit)))
            (display (string-append output-prompt input "\n") c-out)
            (flush-output c-out)
            (displayln (read-line c-in)) ;; server echoes back sent input
            ;(semaphore-post fair)
            (read-loop-i)
          )
          (read-loop-i)
          'ok)))
  
;(kill-thread a)
;(kill-thread t)
(thread-wait t)
(display "DONE!!\n")

