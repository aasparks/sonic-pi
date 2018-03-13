#lang racket/gui
(require drracket/tool
         racket/class
         racket/gui/base
         racket/unit
         mrlib/switchable-button
         "scsynth/start-scsynth.rkt")

(provide tool@)

(define tool@
  (unit
    (import drracket:tool^)
    (export drracket:tool-exports^)

    (define sonic-pi-mixin
      (mixin (drracket:unit:frame<%>) ()
        (super-new)
        (inherit get-button-panel
                 get-interactions-text
                 get-definitions-text)
        (inherit register-toolbar-button
		 register-toolbar-buttons)
        ;; receives info log messages on current-logger with topic "lsonic"
        (define logger (make-logger 'lsonic
                                    (current-logger)))

        (let [(play-btn
               (new switchable-button%
                    (label "Play")
                    (callback (λ (button)
                                (update-user-score (get-definitions-text)
                                                   logger)))
                    (parent (get-button-panel))
                    (bitmap icon-play)))
              (stop-btn
               (new switchable-button%
                    (label "Stop")
                    (callback (λ (button)
                                (send-stop logger)))
                    (parent (get-button-panel))
                    (bitmap icon-stop)))]
	  (register-toolbar-buttons (list play-btn stop-btn))
          (send (get-button-panel) change-children
                (λ (l)
                  (cons stop-btn (remq stop-btn l))))
          (send (get-button-panel) change-children
                (λ (l)
                  (cons play-btn (remq play-btn l)))))))

    (define icon-play
      (let* ((bmp (make-bitmap 16 16))
             (bdc (make-object bitmap-dc% bmp)))
        (send bdc erase)
        (send bdc set-smoothing 'smoothed)
        (send bdc draw-text "►" 0 0)
        (send bdc set-bitmap #f)
        bmp))
    (define icon-stop
      (let* ((bmp (make-bitmap 16 16))
             (bdc (make-object bitmap-dc% bmp)))
        (send bdc erase)
        (send bdc set-smoothing 'smoothed)
        (send bdc draw-text "█" 0 0)
        (send bdc set-bitmap #f)
        bmp))

    ;; logs the new user score to be run
    (define (update-user-score text logger)
      (define uscore (string-append "(list "
                                    (filter-definitions (send text get-text))
                                    ")"))
      (log-message logger
                   'info
                   'lsonic
                   "new-score"
                   uscore))
    
    ;; logs the stop message
    (define (send-stop logger)
      (log-message logger
                   'info
                   'lsonic
                   "stop"
                   'stop))

    (define (phase1) (void))
    (define (phase2) (void))

    (drracket:get/extend:extend-unit-frame sonic-pi-mixin)))

;; removes the lang line from the definitions text
;; note: could filter out comments here. was going to but the
;;       eval call takes care of it. the lang line is the only
;;       issue.
(define (filter-definitions text)
  (regexp-replace #rx"(?m:#lang.+$)\n"
                  text
                  ""))

(module+ test
  (require rackunit)
  (check-equal? (filter-definitions "#lang racket\n(run-main-method)")
                "(run-main-method)")
  (check-equal? (filter-definitions "#lang racket\n;;This is my program\n(run-main)")
                ";;This is my program\n(run-main)")
  )
