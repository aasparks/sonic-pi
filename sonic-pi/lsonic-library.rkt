#lang racket

(require "scsynth/scsynth-abstraction.rkt"
         "scsynth/sample-loader.rkt"
         "data-structures/common.rkt"
         "data-structures/note.rkt"
         "data-structures/fx.rkt"
         "data-structures/sample.rkt"
         "data-structures/loop.rkt"
         "rand.rkt"
         "allocator.rkt"
         "thread-communication.rkt")

(provide play-note
         play-sample
         load-fx
         shutdown-scsynth)

;; play a note n at vtime given a job context
(define (play-note job-ctxt n vtime)
  (play-synth job-ctxt
              (note-name n)
              vtime
              (note-params n)))

;; load and play a sample at vtime
(define (play-sample job-ctxt sample vtime)
  (define loaded (sample-loaded? (sample-path sample)))
  (define b-info (if loaded
                     loaded
                     (load-sample job-ctxt (sample-path sample))))
  (define s
    (resolve-specific-sampler
     (control-sample
      sample
      "buf"
      (first b-info))
     b-info))
  (play-synth job-ctxt
              (sample-name s)
              vtime
              (sample-params s)))

;; load an fx with all appropriate information
(define (load-fx job-ctxt effect time inbus outbus)
  (define f (set-fx-busses effect
                           inbus
                           outbus)) 
  (play-synth job-ctxt
              (fx-name f)
              time
              (fx-params f)))
