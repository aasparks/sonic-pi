#lang typed/racket/base

;; for now this is just a file for functions that
;; are used by multiple modules

(provide complete-field-list
         group-params
         root-dir
         Score
         Score?
         Score-name
         Param
         Param?
         Param-name
         Param-value
         param->osc
         psleep
         (rename-out [Psleep? psleep?]
                     [Psleep-duration psleep-duration]))

(require racket/match
         racket/list)
(require/typed setup/dirs
               [find-user-pkgs-dir (-> Path)])

;; A parameter is a parameter name and a value
;; A Param is (param Byte Real)
(struct Param ([name : Bytes] [value : Real]) #:transparent)

;; convert param structure to osc-compatible list
;; of bytes and real
(: param->osc (Param -> (Listof (U Bytes Real))))
(define (param->osc p)
  (list (Param-name p)
        (Param-value p)))

;; a Score is any element of music
;;  - psleep
;;  - note
;;  - fx
;;  - sample
;;  - loop/live_loop
(struct Score ([name : Bytes]) #:transparent)

;; a psleep is a number representing time in ms to sleep
;; psleep inherits from Score for type-checking purposes
;;  but does not need the name
(struct Psleep Score ([duration : Real]) #:transparent)

;; creates a psleep structure with no name
(: psleep (Real -> Psleep))
(define (psleep duration)
  (Psleep #"" duration))

;; root directory for sonic-pi located in [pkgs]/sonic-pi/sonic-pi
(: root-dir (-> Path))
(define (root-dir)
  (build-path (find-user-pkgs-dir)
              "sonic-pi"
              "sonic-pi"))

;; groups parameters into their correct structure
(: group-params ((Listof (U String Real)) -> (Listof Param)))
(define (group-params param-parts)
  (match param-parts
    [(cons (? string? name) (cons val rst))
     (cons (Param (string->bytes/utf-8 name)
                  (if (real? val)
                      val
                      (error 'group-params "expected real number value, got ~e" val)))
           (group-params rst))]
    ['() '()]
    ;; the type checker handles this
    #;[(cons non-string (cons val rst))
     (error 'group-params "expected field name (string), got ~e" non-string)]
    [(cons leftover '())
     (error 'group-params "leftover value in params: ~e" leftover)]))

;; given the grouped parameters and the list of default values
;; completes the full list of params
(: complete-field-list ((Listof Param) (Listof Param) -> (Listof Param)))
(define (complete-field-list other-params default-params)
  (for/list ([param (in-list default-params)])
    (match (search-params param other-params)
      [(Param _ new-val) (Param (Param-name param) new-val)]
      [#f param])))

;; searchs the given list for a parameter
(: search-params (Param (Listof Param) -> (U Param Boolean)))
(define (search-params p pList)
  (cond
    [(empty? pList) #f]
    [(bytes=? (Param-name p) (Param-name (first pList))) (first pList)]
    [else (search-params p (rest pList))]))

(module+ test
  (require typed/rackunit)

  (check-equal? (complete-field-list (list (Param #"amp" 2)
                                           (Param #"amp_slide" 2))
                                     (list (Param #"amp" 1)
                                           (Param #"amp_slide" 0)
                                           (Param #"foo" 1)))
                (list (Param #"amp" 2)
                      (Param #"amp_slide" 2)
                      (Param #"foo" 1)))

  (check-equal? (group-params (list "amp" 2 "foo" 5 "bar" 12))
                (list (Param #"amp" 2)
                      (Param #"foo" 5)
                      (Param #"bar" 12)))

  (check-exn exn:fail?
             (λ () (group-params (list "amp" "foo"))))
  (check-exn exn:fail?
             (λ () (group-params (list "amp" 2 "foo"))))
  (check-equal? (param->osc (Param #"amp" 1))
                (list #"amp" 1)))