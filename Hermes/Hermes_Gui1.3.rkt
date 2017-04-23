#lang racket
(require racket/gui/base)
;Author:Douglas Richardson
;Notes:Our GUI mostly deals with lists of a list of 3 strings and a number
;although the number is always delt with locally
;When using user-message you need to give it a list of 3 things
;The name of the user as a string, what they said as a string,
;and the color as a string

;Object stuff

(provide make-gui)

(define (make-gui)
  (begin
    (displayln "Makin...");;eat this note
    ;;Create the frame
    (define main-frame (new frame%
                            [label "Hermes"]
                            [width 500]
                            [height 700]
                            ))
    ;;Editing canvas
    (define (do-stuff-paint paint-canvas paint-dc)
      (do-more-stuff-paint listy paint-canvas paint-dc))

    (define (do-more-stuff-paint paint-listy paint-canvas paint-dc)
      (if (null? paint-listy)
          '()
          (begin
            (re-draw-message (get-username-from-list (car paint-listy))
                             (get-message-from-list (car paint-listy))
                             (get-color-from-list (car paint-listy))
                             (get-height-from-list (car paint-listy)))
            (do-more-stuff-paint (cdr paint-listy) paint-canvas paint-dc))))

    (define read-canvas (new canvas%
                             [parent main-frame]
                             [paint-callback do-stuff-paint]
                             [style '(hscroll vscroll)]
                             ))

    (send read-canvas init-auto-scrollbars #f #f 0 0);Start with no scrollbars
    ;;text-field stuff
    (define (text-feild-callback callback-type other-thing)
      (if (equal? 'text-field-enter (send other-thing get-event-type))
          (button-do-stuff 'irrelevant 'not-used)
          '()))
    
    (define input (new text-field%
                       [parent main-frame]
                       [label "Username:"]
                       [callback text-feild-callback]
                       ))
    ;;button stuff
    (define (button-do-stuff b e);b and e do nothing :/
      (begin
        (define given-input (send input get-value))
        (if (string? given-input)
            (if (color-change-request? given-input)
                (set! my-color (get-color-from-input given-input))
                (if (quit-request? given-input)
                    (write "quit" the-output-port)
                    (if (< 0 (string-length-safe given-input))
                        (send-message (send input get-value) my-color);;
                        '())))
        '())
        (send input set-value "")))
    
    (define send-button (new button%
                             [parent main-frame]
                             [label "Send"]
                             [callback button-do-stuff]))
    ;;I forget what these do but don't move them
    (define dc (send read-canvas get-dc))
    (send dc set-scale 1 1)
    (send dc set-text-foreground "black")
    ;;messaging stuff

    (define (user-message-parse string start)
      (define (helper str index)
        (if (string? string)
            (if (>= (+ start index) (string-length-safe string))
                (display string);;Something went wrong
                (if (eq? (string-ref str (+ start index)) #\~)
                    (substring-s str start (+ start index))
                    (helper str (+ index 1))))
            '()))
      (helper string start))
      
    (define (user-message onetrueinput)
      (display "Godit!");;eat this note
      (displayln onetrueinput);;eat this note
      (if (not (string=? onetrueinput ""))
          (let();;This is kind of stupid but whatever it works.
            (define username (user-message-parse onetrueinput 0))
            (define user-input (user-message-parse onetrueinput  (+ 1(string-length-safe username))))
            (define color (substring-s onetrueinput (+ 2 (string-length-safe username) (string-length-safe user-input)) (string-length-safe onetrueinput)))
            (send dc set-text-foreground color)
            (send dc draw-text (string-append username ":" user-input) 0 height)
            (set! listy (appendlist listy (list username user-input color height)))
            (set! height (+ height 15))
            (set! min-v-size (+ min-v-size 15))
            (if (> (* 20 (string-length-safe user-input)) min-h-size)
                (set! min-h-size (* 20 (string-length-safe user-input)))
                '())
            (send read-canvas init-auto-scrollbars min-h-size min-v-size 0 1))
          '()))
    ;;Add a function that parces input from a string and extracts elements

    (define the-output-port (open-output-string))
    
    ;;This probably won't change...
    (define (send-message input color)
      (write (string-append name "~" input "~" color) the-output-port))
    ;;Although re-draw is kind of misleading, it is just print the whole
    ;;list of strings to the screen
    (define (re-draw-message username input color in-height)
      (begin
        (displayln "Fixy!");eat this note
        (send dc set-text-foreground color)
        (send dc draw-text (string-append username ":" input) 0 in-height)
        ))

    (define (update given-list)
      (begin (set! listy '())
             (set! height 0)
             (update-helper given-list)))

    (define (update-helper given-list)
      (if (null? given-list)
          '()
          (if (null? (car given-list))
              '()
              (begin (user-message
                      (get-username-from-list (car given-list))
                      (get-message-from-list (car given-list))
                      (get-color-from-list (car given-list)))
                     (update-helper (cdr given-list))))))
    
    ;;Variables go below functions
    (define name "Me")
    (define min-h-size 80)
    (define min-v-size 30)
    (define listy (list (list "Server" "Connected" "Red" 0)))
    (define my-color "black")
    (define height 15)
    ;;dispatch goes below that
    (define (dispatch command)
      (cond ((eq? command 'show) (send main-frame show #t))
            ((eq? command 'close)(send main-frame show #f))
            ((eq? command 'send) send-message)
            ((eq? command 'set-name) (lambda (newname) (if (string? newname)
                                                  (set! name newname)
                                                  (print "Thats not good"))))
            ((eq? command 'recieve-message) user-message)
            ;((eq? command 'get-list) listy)
            ;((eq? command 'set-list) update)
            ((eq? command 'get-output-port) the-output-port)
            ;;Something up with that
            (else (error "Invalid Request" command))
            ))
    ;;dispatch goes below that
    dispatch))


;This one displays information




;Initilize scrolling

;Then we need to find out if we need them or not.

;Listy is going to be a list of lists of strings
;each element in listy will contain three strings
;the username the message they said and the color they used
;The the height the message should display at


(define (appendlist listoflist add-to-end)
  (if (null? listoflist)
      (cons add-to-end '())
      (cons (car listoflist) (appendlist (cdr listoflist) add-to-end))))

(define (get-username-from-list in-list)
  (car in-list))

(define (get-message-from-list in-list)
  (car (cdr in-list)))

(define (get-color-from-list in-list)
  (car (cdr (cdr in-list))))

(define (get-height-from-list in-list)
  (car (cdr (cdr (cdr in-list)))))

(define (get-color-from-input input)
  (substring-s input 6 (string-length-safe input)))



;this one is a crap version of justpressing the enter key
(define (color-change-request? given-string)
  (if (> (string-length-safe given-string) 7)
      (if (equal? (substring-s given-string 0 6) "/color")
          #t
          #f)
      #f))


(define (quit-request? given-string)
  (if (>= (string-length-safe given-string) 5)
      (if (equal? (substring-s given-string 0 5) "/quit")
          #t
          #f)
      #f))

(define (string-length-safe string)
  (if (string? string)
      (string-length string)
      0))

(define (substring-s string start end)
  (if (<= start end)
      (if (<= end (string-length-safe string))
          (substring string start end)
          "")
      ""))
;(define thing1 (make-gui))
;(define thing2 (make-gui))

