#lang racket/gui
(require drracket/tool
         racket/class
         racket/gui/base
         racket/unit
         mrlib/switchable-button
         "lsonic.rkt")

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
        (define ch (make-channel))

        (let [(play-btn
               (new switchable-button%
                    (label "Play")
                    (callback (λ (button)
                                (if (pressed?)
                                    (update-score (get-definitions-text)
                                                  ch)
                                    (begin
                                      (set-pressed)
                                      (run-scsynth (get-definitions-text)
                                                   ch)))))
                    (parent (get-button-panel))
                    (bitmap icon-play)))
              (stop-btn
               (new switchable-button%
                    (label "Stop")
                    (callback (λ (button)
                                (set-box! pressed #f)))
                    (parent (get-button-panel))
                    (bitmap icon-stop)))]
	  (register-toolbar-buttons (list play-btn stop-btn))
          (send (get-button-panel) change-children
                (λ (l)
                  (cons play-btn (remq play-btn l))))
          (send (get-button-panel) change-children
                (λ (l)
                  (cons stop-btn (remq stop-btn l)))))))

    ;; let's define a box to keep track of whether the button was pressed once already
    (define pressed (box #f))
    (define (pressed?) (unbox pressed))
    (define (set-pressed) (set-box! pressed #t))

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

    (define (run-scsynth text ch)
      #;(begin (random-seed 52)
             (current-output-port (open-output-file (build-path "."
                                                                "soniclog.txt")
                                                    #:exists 'replace))
             (define ctxt (startup))
             (define job-ctxt (start-job ctxt))

             (with-handlers
                 ([exn:fail? (lambda (exn)
                               (printf "ending job due to error...\n")
                               (end-job job-ctxt)
                               (raise exn))])
               #;(string-split (send text get-text) "\n")
               (thread
                (λ ()
                  (play/live job-ctxt ch (l-eval (string-append
                                                  "(list"
                                                  (string-append* (rest (string-split (send text get-text) "\n")))
                                                  ")")))))
               #;(play job-ctxt (l-eval (string-append
                                       "(list"
                                       (string-append* (rest (string-split (send text get-text) "\n")))
                                       ")")))
               (sleep 15)
               (end-job job-ctxt)))
         0
      )
    (define (update-score text ch)
      #;(channel-put ch (l-eval (string-append
                                       "(list"
                                       (string-append* (rest (string-split (send text get-text) "\n")))
                                       ")")))
      0)

    (define (phase1) (void))
    (define (phase2) (void))

    (drracket:get/extend:extend-unit-frame sonic-pi-mixin)))