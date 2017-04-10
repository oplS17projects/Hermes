#lang racket

(require racket/gui/base)

;; Create a new window via the frame class
(define frame (new frame% [label "Example"]))

;; Show frame(window) by calling it show method
(send frame show #t) ;; you call object methods via send
