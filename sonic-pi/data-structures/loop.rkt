#lang typed/racket/base

(require "common.rkt")

(provide sub1loop
         loop
         loop/infinite
         live_loop
         (rename-out [Loop? loop?]
                     [Loop-block loop-block]
                     [Loop-reps loop-reps]
                     [Live_Loop? live_loop?]
                     [Live_Loop-block live_loop-block]))

;; a loop is a number representing the number of reps and
;; a block, which is a closure over a user score
;; NB: they aren't named, like with psleep, but they still
;; need to come from Score for type-checking purposes
(struct Loop Score ([reps : Integer] [block : (-> (Listof Score))]) #:transparent)
;; a live_loop is a name and a block containing a user score
(struct Live_Loop Score ([block : (-> (Listof Score))]) #:transparent)

;; create a loop structure, given a number of reps and a block
(: loop (Positive-Integer (-> (Listof Score)) -> Loop))
(define (loop reps block)
  (Loop #"" reps block))

;; let's call an infinite loop one with -1 reps
(: loop/infinite ((-> (Listof Score)) -> Loop))
(define (loop/infinite block)
  (Loop #"" -1 block))

;; create new loop where the number of reps is one less than the one supplied
(: sub1loop (Loop -> Loop))
(define (sub1loop lp)
  (Loop
   #""
   (sub1 (Loop-reps lp))
   (Loop-block lp)))

;; create a live_loop structure with a name
(: live_loop (String (-> (Listof Score)) -> Live_Loop))
(define (live_loop name block)
  (Live_Loop (string->bytes/utf-8 name) block))


(module+ test
  (require typed/rackunit)
  (require "note.rkt")
  (define bogus (λ () (list (note 'zawa 40))))
  (check-equal? (sub1loop (loop 4 bogus))
                (Loop #"" 3 bogus))
  (check-equal? (live_loop "foo" bogus)
                (Live_Loop #"foo" bogus))


  )