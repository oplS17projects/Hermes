#lang racket
(require racket/gui/base)
;;Step 1. Create a window to draw into
(define frame(new frame% [label "Example"]))
;;I don't know what frame% means, but new must be a procedure
;;(send frame show #t) Running this command displays the frame
;;send appears to be a command to be a procedure that takes a frame
;; followed by a command and a boolean.
;;the boolean is fed into the command in this case
;;if you said #f it would close the window
;;that is usefull
;;Below is a slight expantion on example code
;;letting the button be a toggle
(define frame2 (new frame%[label "Example2"]))
(define msg (new message% [parent frame2] [label " Nothing  "]))
(define thingy #t)
(define button-to-click (new button%
     [parent frame2]
     [label "Click"]
     [callback (lambda (button event)
                 (if thingy
                 (begin (set! thingy #f)
                        (send msg set-label "Something"))
                 (begin (set! thingy #t)
                        (send msg set-label " Nothing  "))))]))
;;Frames are okay ish for error messages but the real stuff is
;;in canvas stuff
(define my-canvas%
  (class canvas%
    (define/override (on-event event)
      (send msg set-label "Canvas mouse"))
    (define/override (on-char event)
      (send msg set-label "Canvas keyboard"))
    (super-new)));;Don't know what that one means

(define canvas-thing (new my-canvas% [parent frame2]));;unfortunately
;;we still need to re-size it manually
;;Now I wonder if we could create a procedure to make any text
;;appear
(define frame3 (new frame%[label "Example3"]))
(define blank (new message% [parent frame3] [label "                                                                                "]))
(define (make-text string) (begin (send blank set-label string)))
;(send frame3 show #t)
;(make-text "Hello World") works exactly fine.
;;Now lets do something more complicated
;;We want to create a procedure that creates a new line
;;each time it is called so...
(define frame4 (new frame%[label "Example4"]))
;;now blank4 should be a procedure to create multiple lines in the frame
(define (make-text-line string) (begin (new message%
                                            [parent frame4]
                                            [label string])))
;;display with
;;(send frame4 show #t)
;;add text with
;;(make-text-line "Hello World!")
;;This works for not but there are a few problems
;;first of all the window starts really small and doesn't restrict
;;resizing. Second it is always in the middle of the frame
;;Third, once text is on screen there is no way to get it off
;;But we can do better
(define frame5 (new frame%
                   [label "Example5"]
                   [width 300]
                   [height 300]))
(define canvas5 (new canvas% [parent frame5]
             [paint-callback
              (lambda (canvas dc)
                (send dc set-scale 3 3)
                (send dc set-text-foreground "blue")
                (send dc draw-text "Don't Panic!" 0 0))]))
;;above is the example code to write some simple text, however
;;we can apply this to what we learned above to make something abit
;;more
(define frame6 (new frame%
                    [label "Example6"]
                    [width 600]
                    [height 700]))
(define (make-color-text string color)
  (begin (new canvas%
              [parent frame6]
              [paint-callback
               (lambda (canvas dc)
                 (send dc set-text-foreground color)
                 (send dc draw-text string 0 0 #f))])))
;;display with
;;(send frame6 show #t)
;;write text with
;;(make-color-text "Hello World!" "purple")
;;Okay that doesn't exactly work as planned...
;;the problem with this is that each message is it's own canvas now
;;not only that but it means we can only print each line in it's
;;own color. So new plan is to make it so it adds on new strings
;;to one canvas, adding \n as nessessary. Except nevermind since
;;\n doesn't exist in this apparently

;;Lets switch back to text and we can change it later
(define frame7 (new frame%
                    [label "Example7"]
                    [width 600]
                    [height 200]))
(define (make-blank-line i)
  (new message%
       [parent frame7]
       [label "                                                                                "]))
;;80 space characters
;;the i is only there to make the build-list command happy
(define Message-list (build-list 10 make-blank-line))
;;10 make-blank-lines
;;that build-list command is super usefull for something like this
(define (move-down-list list)
  (if (eq? '() (cdr list))
      '()
      (begin
        (move-down-list (cdr list))
        (send (car (cdr list)) set-label (send (car list) get-label)))))
(define (send-word string)
  (begin
    (move-down-list Message-list)
    (send (car Message-list) set-label string)))
;;display with
;;(send frame7 show #t)
;;add text with
;;(send-word "Hello World")
;;Now using the send-word command I can make each word appear on the
;;screen in the place where it used to be. Starting at the top of the
;;screen and working it's way down the more text is added.
;;on the bottom line, after adding 10 lines of text, it will remove the bottom
;;most line