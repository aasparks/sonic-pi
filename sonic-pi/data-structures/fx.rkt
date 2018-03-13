#lang typed/racket/base

(require racket/match
         racket/list
         "common.rkt"
         "synth-info.rkt")

(provide fx
         set-fx-busses
         set-fx-block
         control-fx
         (rename-out [Fx-params fx-params]
                    ; [Score-name fx-name]
                     [Fx? fx?]
                     [Fx-block fx-block]))

;; An Fx contains a name, params, and a closure
;; over a user score (Listof (U Note Sample Fx Loop))
(struct Fx Score ([params : (Listof Param)] [block : (-> (Listof Score))]) #:transparent)

;; create sound fx given name, args, and block
;; since this is a variatic function with the variable length
;; args coming before the list, I'm going to include the list
;; of notes/samples/pisleep in the args and it will always be
;; the last thing in the list
;(: fx (String (U String Real (Listof (U sample note pisleep Fx))) * -> Fx))
(: fx (Symbol (-> (Listof Score)) (U String Real) * -> Fx))
(define (fx name thunk . param-parts)
  (define other-params (group-params param-parts))
  (Fx (string->bytes/utf-8 (string-append "sonic-pi-fx_" (symbol->string name)))
      (complete-field-list other-params (get-fx-args name))
      thunk))

;; set the an fx to contain a block
(: set-fx-block (Fx (-> (Listof Score)) -> Fx))
(define (set-fx-block f block)
  (Fx (Score-name f)
      (Fx-params f)
      block))

;; set an fx's in_bus and out_bus
(: set-fx-busses (Fx Real Real -> Fx))
(define (set-fx-busses f in_bus out_bus)
  (Fx (Score-name f)
      (complete-field-list (list (Param #"in_bus" in_bus)
                                 (Param #"out_bus" out_bus))
                           (Fx-params f))
      (Fx-block f)))

;; control a sound fx's arguments
(: control-fx (Fx (U String Real) * -> Fx))
(define (control-fx f . param-parts)
  (Fx (Score-name f)
      (complete-field-list (group-params param-parts) (Fx-params f))
      (Fx-block f)))


(module+ test
  (require typed/rackunit)
  (require "note.rkt")
  (define n (λ () (list (note 'zawa 60)
                        (psleep 2)
                        (note 'zawa 50))))
  (check-equal? (fx 'bitcrusher
                    n
                    "bits" 16)
                (Fx #"sonic-pi-fx_bitcrusher"
                    (list
                     (Param #"in_bus" 0)
                     (Param #"out_bus" 0)
                     (Param #"sample_rate" 10000)
                     (Param #"sample_rate_slide" 0)
                     (Param #"sample_rate_slide_shape" 1)
                     (Param #"sample_rate_slide_curve" 0)
                     (Param #"bits" 16)
                     (Param #"bits_slide" 0)
                     (Param #"bits_slide_shape" 1)
                     (Param #"bits_slide_curve" 0)
                     (Param #"cutoff" 0)
                     (Param #"cutoff_slide" 0)
                     (Param #"cutoff_slide_shape" 1)
                     (Param #"cutoff_slide_curve" 0))
                    n))
  (check-equal? (set-fx-busses
                 (fx 'bitcrusher
                     n
                     "bits" 16)
                 14 16)
                (Fx #"sonic-pi-fx_bitcrusher"
                    (list
                     (Param #"in_bus" 14)
                     (Param #"out_bus" 16)
                     (Param #"sample_rate" 10000)
                     (Param #"sample_rate_slide" 0)
                     (Param #"sample_rate_slide_shape" 1)
                     (Param #"sample_rate_slide_curve" 0)
                     (Param #"bits" 16)
                     (Param #"bits_slide" 0)
                     (Param #"bits_slide_shape" 1)
                     (Param #"bits_slide_curve" 0)
                     (Param #"cutoff" 0)
                     (Param #"cutoff_slide" 0)
                     (Param #"cutoff_slide_shape" 1)
                     (Param #"cutoff_slide_curve" 0))
                    n))
  (check-equal? (set-fx-block (fx 'krush (λ () (list (note 'zawa 60))))
                              n)
                (fx 'krush n))
  (check-equal? (control-fx (fx 'krush n) "krush" 4)
                (fx 'krush n "krush" 4))
  )