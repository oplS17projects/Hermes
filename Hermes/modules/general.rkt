#lang racket

(provide displayln-safe)
;; Several threads may want to print to stdout, so  lets make things civil
; constant always available
(define stdout (make-semaphore 1))

; prints to stdout with an optional output port
; requires a specified semaphore for the optional output port
(define displayln-safe
  (lambda (a-string [a-semaphore stdout] [a-output-port (current-output-port)])
    (cond [(not (and (eq? a-semaphore stdout) (eq? a-output-port (current-output-port))))
           (semaphore-wait a-semaphore)
           (semaphore-wait stdout)
           (displayln a-string a-output-port)
           (flush-output a-output-port)
           (displayln a-string)
           (semaphore-post stdout)
           (semaphore-post a-semaphore)]
          [else
            (semaphore-wait stdout)
            (displayln a-string)
            (semaphore-post stdout)])))

