#lang typed/racket
(require "common.rkt")

(provide thread_s
         (rename-out [Thread-block thread-block]
                     [Thread? thread?]))

;; a Thread is as score for typing purposes. It consists
;; of a block of code to be executed just like a regular
;; racket thread. 
(struct Thread Score ([block : (-> (Listof Score))]))

;; create a thread structure
(: thread_s ((-> (Listof Score)) -> Thread))
(define (thread_s block)
  (Thread #"" block))