#lang racket

(require sonic-pi/lsonic
         2htdp/universe
         2htdp/image
         lang/posn)

; image constants
(define TITLE (text "Piano Emulator" 42 "blue"))
(define KEY (rectangle 10 50 "outline" "black"))
(define KEY-HIGH (rectangle 10 50 "solid" "blue"))
(define KEYSHARP (rectangle 8 35 "solid" "black"))
(define KEYSHARP-HIGH (rectangle 8 35 "solid" "blue"))
(define OCTAVE-HIGHLIGHT (rectangle 70 50 "outline" "purple"))
(define EMPTY-SCENE (empty-scene 720 560))

; size constants
(define START-Y 150)
(define START-X 64)

(define key-hash
  (make-hash (list
              (cons "q" "C")
              (cons "w" "D")
              (cons "e" "E")
              (cons "r" "F")
              (cons "t" "G")
              (cons "y" "A")
              (cons "u" "B")
              (cons "2" "Cs")
              (cons "3" "Ds")
              (cons "5" "Fs")
              (cons "6" "Gs")
              (cons "7" "As"))))


; a world is (make-world (list octave) number job-ctxt)
;; world is a list of 7 octaves, a currently active octave,
;; and a job context
(define-struct world (octaves active-octave job-ctxt) #:transparent)

; a octave is (make-octave (list image) (list posn))
;; an octave is a list of 12 keys and their respective positions
(define-struct octave (keys posns) #:transparent)

; build-octave : number -> (list (list image) (list posn))
; Builds a single octave 1-7
(define (build-octave oct)
  (define x (+ (* 84 oct) 64))
  (define y START-Y)
  (list (append (build-list 7 (λ (num) KEY))
                (build-list 5 (λ (num) KEYSHARP)))
        (append (build-list 7 (λ (num) (make-posn (+ (* num 10) x) y)))
                (list (make-posn (+ x 5) (- y 7))
                      (make-posn (+ x 15) (- y 7))
                      (make-posn (+ x 35) (- y 7))
                      (make-posn (+ x 45) (- y 7))
                      (make-posn (+ x 55) (- y 7))))))

; initial world is in 1st octave with no key pressed
(define initial-world
  (make-world
   (build-list 7
               (λ (num)
                 (apply make-octave (build-octave num))))
   0
   (start-job (startup))))

; draw : world -> image
; draws the whole world
(define (draw world)
  (overlay/align
   'center 'top
   TITLE
   (place-image
   OCTAVE-HIGHLIGHT
   (+ (* 84 (world-active-octave world)) 94)
   START-Y
   (place-images
    (flatten
     (map (λ (oct)
            (octave-keys oct))
          (world-octaves world)))
    (flatten
     (map (λ (oct)
            (octave-posns oct))
          (world-octaves world)))
    EMPTY-SCENE))))

; keh : world key -> world
; handle key presses, by highlighting the appropriate key
(define (keh world key)
  (cond
    [(key=? key "right") (next-octave world)]
    [(key=? key "left")  (prev-octave world)]
    ;; playable key. play the sound and highlight the key
    [(member key (hash-keys key-hash))
     (play
      (world-job-ctxt world)
      (list
       (note 'piano (string-append
                     (hash-ref key-hash key)
                     (number->string
                      (add1 (world-active-octave world)))))))
     (make-world (highlight-key-in-octave world key)
                 (world-active-octave world)
                 (world-job-ctxt world))]
    [else world]))

; next-octave : world -> world
; determines the next octave up
(define (next-octave world)
  (make-world
   (world-octaves world)
   (if (= 6 (world-active-octave world))
       0
       (add1 (world-active-octave world)))
   (world-job-ctxt world)))

; prev-octave : world -> world
; determines the previous octave
(define (prev-octave world)
  (make-world
   (world-octaves world)
   (if (= 0 (world-active-octave world))
       6
       (sub1 (world-active-octave world)))
   (world-job-ctxt world)))

; highlight-key-in-octave : world key -> (list octave)
(define (highlight-key-in-octave world key)
  (define idx (world-active-octave world))
  (append (take (world-octaves world) idx)
          (list
           (make-octave (highlight-key (octave-keys (list-ref (world-octaves world) idx)) key)
                        (octave-posns (list-ref (world-octaves world) idx))))
          (my-drop (world-octaves world) (add1 idx))))

; highlight-key : (list image) key -> (list octave)
; sets the correct key to have a solid background
(define (highlight-key keys k)
  (define idx (key->index k))
  (append (take keys idx)
          (list (if (> idx 6)
                    KEYSHARP-HIGH
                    KEY-HIGH))
          (my-drop keys (add1 idx))))

; highlight-key-in-octave : world key -> (list octave)
(define (unhighlight-key-in-octave world key)
  (define idx (world-active-octave world))
  (append (take (world-octaves world) idx)
          (list
           (make-octave
            (unhighlight-key (octave-keys (list-ref (world-octaves world) idx)) key)
            (octave-posns (list-ref (world-octaves world) idx))))
          (my-drop (world-octaves world) (add1 idx))))

; unhighlight-key : (list image) key -> (list image)
; sets the correct key back to normal
(define (unhighlight-key keys k)
  (define idx (key->index k))
  (append (take keys idx)
          (list (if (> idx 6)
                    KEYSHARP
                    KEY))
          (my-drop keys (add1 idx))))

; key->index : key -> number
; gets the index in the list keys for the right keypress
(define (key->index key)
  (cond
    [(key=? key "q") 0]
    [(key=? key "w") 1]
    [(key=? key "e") 2]
    [(key=? key "r") 3]
    [(key=? key "t") 4]
    [(key=? key "y") 5]
    [(key=? key "u") 6]
    [(key=? key "2") 7]
    [(key=? key "3") 8]
    [(key=? key "5") 9]
    [(key=? key "6") 10]
    [(key=? key "7") 11]))

; krh : world key -> world
; handle key release, by unhighlighting a key
(define (kreh world key)
  (cond
    ;; playable key. play the sound and highlight the key
    [(member key (hash-keys key-hash))
     (make-world (unhighlight-key-in-octave world key)
                 (world-active-octave world)
                 (world-job-ctxt world))]
    [else world]))


(define (my-drop lst idx)
  (if (> idx (length lst))
      empty
      (drop lst idx)))


(big-bang initial-world
          [to-draw draw]
          [on-key keh]
          [on-release kreh]
          [name "Piano Emulator"])

(end-job (world-job-ctxt initial-world))