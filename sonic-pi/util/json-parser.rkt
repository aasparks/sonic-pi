#lang typed/racket/base

(require tjson
         "synth-info.rkt")

(provide read-json)

(define (json-synth->synth s)
  (make-synth-info ))


;; json object containing all synths and their info
(define synths
  (jsattribute parsed-json 'synths))

;; convert all json synths to synth objects





(define parsed-json
  (read-json (open-input-file "synths.json")))

(: -> (Listof (Struct synth-info)))
(define (get-all-synths)
  (map json-synth->synth synths))