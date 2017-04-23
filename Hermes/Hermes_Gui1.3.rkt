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
    ;;Create the frame/window with title "Example5", width 500 and height 700
    (define main-frame (new frame%
                            [label "Example5"]
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

    ; canvas for displaying messages with horizontal and vertical scrollbar.
    ; on an event it calls do-stuff-paint to redraw things on the screen 
    ; properly
    (define read-canvas (new canvas%
                             [parent main-frame]
                             [paint-callback do-stuff-paint]
                             [style '(hscroll vscroll)]
                             ))

    ; "send" is rackets way of doing object-oriented programming. It calls an
    ; objects functions in this case "read-canvas" object's init-auto-scrollbars
    (send read-canvas init-auto-scrollbars #f #f 0 0);Start with no scrollbars

    ; editing area callback. Gets called when enter is pressed.
    (define (text-field-callback callback-type other-thing)
      (if (equal? 'text-field-enter (send other-thing get-event-type))
          (button-do-stuff 'irrelevant 'not-used)
          '()))
    
    ; creates the editing area as part of the parent "main-frame" define above.
    ; initially labelled "Username:" 
    ; TODO make label setable
    (define input (new text-field%
                       [parent main-frame]
                       [label "Username:"]
                       [callback text-field-callback]
                       ))

    ; It's a callback function activated when the send button is pressed in the
    ; GUI. It is also called manually when textfield receives an enter key
    (define (button-do-stuff b e);b and e do nothing :/
        (if (color-change-request? (send input get-value))
            (set! my-color (get-color-from-input (send input get-value)))
            (if (< 0 (string-length (send input get-value)))
                (send-message (send input get-value) my-color);;
                '()))
        (send input set-value "")
        )

    ; creates the send button 
    (define send-button (new button%
                             [parent main-frame]
                             [label "Send"]
                             [callback button-do-stuff]))

    ; get-dc retrieves the canvas' device context. From racket docs. A dc object
    ; is a drawing context for drawing graphics and text. It represents output 
    ; devices in a generic way.
    ; Specifically the line below retrieves our canvas device context object.
    (define dc (send read-canvas get-dc))
    (send dc set-scale 1 1) ; set scaling config of output display to 1 to 1
                            ; no scalling
    (send dc set-text-foreground "black") ; color of text that gets drawn on the
                                          ; canvas with "draw-text"
    ; (send dc set-smoothing 'aligned)
    ;;messaging stuff

    ; could convert below to regexes
    (define (user-message-parse string-i start)
        (define (helper str index)
          (if (eq? (string-ref str (+ start index)) #\~) ; regexes would allow us
                                                         ; to avoid this #\~
              (substring str start (+ start index))
              (helper str (+ index 1))))
        (helper string-i 0))
    
    ;; draws a user input to the screen
    (define (user-message user-input)
        (define username (user-message-parse user-input 0))
        (define input (user-message-parse user-input  (+ 1 (string-length username))))
        (define color (substring user-input (+ 2 (string-length username) (string-length input))))
        (send dc set-text-foreground color) ; set dc's text color to user
                                            ; provided
        (send dc draw-text (string-append username ":" input) 0 height)
        (set! listy (appendlist listy (list username input color height)))
        (set! height (+ height 15))
        ; redraw overly long text on gui
        (set! min-v-size (+ min-v-size 15))
        (if (> (* 20 (string-length input)) min-h-size)
            (set! min-h-size (* 20 (string-length input)))
            '())
        (send read-canvas init-auto-scrollbars min-h-size min-v-size 0 1)
        )
    ;;Add a function that parces input from a string-i and extracts elements

    ; actually gets called to send input to the screen. user-message is in effect
    ; its helper. It uses "~" to delimit the different components of message
    (define (send-message input color)
      (user-message (string-append name "~" input "~" color)))
    
    ;; draws messages to the screen canvas as text
    (define (re-draw-message username input color in-height)
      (begin
        (send dc set-text-foreground color)
        (send dc draw-text (string-append username ":" input) 0 in-height)
        ))

    ; used when redrawing the screen along with its helper.
    (define (update given-list)
      (set! listy '())
      (set! height 0)
      (update-helper given-list))

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
    (define listy (list (list "Server" "Connected" "Red" 0))) ; initializes
      ; listy with first message to be drawn on screen
    (define my-color "black") ; default color of the text messages if none
                              ; specified
    (define height 15) ; height between messages drawn on the screen

    ;;dispatch goes below that
    (define (dispatch command)
      (cond ((eq? command 'show) (send main-frame show #t))
            ((eq? command 'send) send-message)
            ((eq? command 'set-name) (lambda (newname) (if (string? newname)
                                                  (set! name newname)
                                                  (print "Thats not good"))))
            ((eq? command 'recieve-message) user-message)
            ((eq? command 'get-list) listy)
            ((eq? command 'set-list) update)
            ;;Something up with that
            (else (error "Invalid Request" command))
            ))
    ;;dispatch goes below that
    dispatch)


;This one displays information




;Initilize scrolling

;Then we need to find out if we need them or not.

;Listy is going to be a list of lists of strings
;each element in listy will contain three strings
;the username the message they said and the color they used
;The the height the message should display at

; listoflist is listy here, and add-to-end is what gets appended to the end
; really expensive operation but its important for Doug to showcase some opl
; concepts
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



; did user request for color change /
(define (color-change-request? given-string)
  (if (> (string-length given-string) 7)
      (if (equal? (substring given-string 0 6) "/color")
          #t
          #f)
      #f))

; we should use regexes for this.
(define (get-color-from-input given-string)
  (substring given-string 7))
;(define thing1 (make-gui))
;(define thing2 (make-gui))

