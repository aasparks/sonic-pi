#lang racket

;; Copyright 2015-2016 John Clements (clements@racket-lang.org)
;; released under Mozilla Public License 2.0

(provide (except-out (all-from-out racket) sleep #%module-begin)
         (rename-out [my-module-begin #%module-begin]
                     [psleep sleep])
         note
         psleep)

(require "data-structures/common.rkt"
         "data-structures/note.rkt"
         "data-structures/sample.rkt"
         "data-structures/fx.rkt"
         "data-structures/loop.rkt"
         "data-structures/thread.rkt"
         "thread-communication.rkt"
         "scsynth/sample-loader.rkt"
         "scsynth/scsynth-abstraction.rkt"
         "allocator.rkt"
         "rand.rkt"
         (for-syntax syntax/parse))

(provide
 startup
 start-job
 end-job
 shutdown-scsynth
 (except-out (all-from-out racket) sleep #%module-begin)
 (rename-out [my-module-begin #%module-begin])
 play
 note
 chord
 control
 sample
 fx
 loop
 loop/infinite
 live_loop
 thread_s
 block
 psleep
 choose
 choose-list
 rrand
 rrand_i
 )

;; give time to startup
(define START-MSEC-GAP 500)
;; don't want to busy-wait... don't sleep less than this many msec:
(define MIN-SLEEP-MSEC 10)
;; ideal lead time
(define QUEUE-LEAD 200)
(define EXPECTED-MAX-SLEEP-LAG 80)
;; lead time in milliseconds. Don't queue a note more than this
;; far in advance:
(define MAX-QUEUE-LEAD 1000)
(define MSEC-PER-SEC 1000)

;; an Event is a
;;   - Score representing the piece of music to play
;;   - vtime representing the start time of the event
(struct Event (score vtime) #:transparent)

;; a block is a closure around a block of user score
;; this is a nasty macro. is there a better way?
;; the only alternative I see right now is to require
;; the user to say (fx 'reverb (λ () (list ..)))
;; this way they can just say (fx 'reverb (block ...))
(define-syntax block
  (syntax-rules ()
    [(_ a ...) (λ () (list a ...))]))

;; parse the input
(define-syntax (my-module-begin stx)
  (syntax-parse stx
    [(_ e:expr ...)
     #'(#%module-begin
        (random-seed 52) ;; totally arbitrary
        (with-handlers
            ([exn:fail? (lambda (exn)
                          (printf "ending job due to error...\n")
                          (shutdown-scsynth)
                          (raise exn))])
          (define ctxt (startup))
          (define job-ctxt (start-job ctxt))
          (save-thread
           "sonic-pi-main-thread"
           (thread
            (λ ()
              (play job-ctxt (list e ...) START-MSEC-GAP))))
          ;; when play terminates, we have either finished
          ;; playing a finite score, or we have sent off all
          ;; threads to run as they please. Now we must listen
          ;; for an update message, or wait for all threads to
          ;; die.
          (wait-or-terminate job-ctxt (make-log-receiver
                                       (current-logger)
                                       'info
                                       'lsonic))))]))

;; waits for all threads to terminate or listens
;; for a message from the tool.
(define (wait-or-terminate job-ctxt log-receiver)
  ;; if all sub-threads are dead, we know this was a finite
  ;; score, so go ahead and terminate the program
  (if (all-threads-dead?)
      (begin
        (wait-for-nodes job-ctxt)
        (end-job job-ctxt))
      ;; wait an arbitrary 1 sec to receive an update message.
      ;; messages may be
      ;;   - a new score to run
      ;;   - 'stop
      (match (sync/timeout 1 log-receiver)
        [(vector info msg value lsonic)
         (if (equal? value 'stop)
             (begin
               (kill-all-threads)
               (end-job job-ctxt))
             (begin (play job-ctxt (l-eval value))
                    (wait-or-terminate job-ctxt log-receiver)))]
        [#f (wait-or-terminate job-ctxt log-receiver)])))

;; play the entire user score
(define (play job-ctxt uscore [time 0])
  (queue-events
   job-ctxt
   uscore
   (+ (current-inexact-milliseconds) time)))

;; queue all user events
(define (queue-events job-ctxt event-list start-time [outbus 12])
  (if (empty? event-list)
      start-time
      (queue-events
       job-ctxt
       (rest event-list)
       (queue-event job-ctxt (first event-list) start-time outbus)
       outbus)))

;; waits until ready then queues a specific event, returing
;; the end-time of the event. In the case of single sound elements,
;; this is just the start time, allowing multiple events at the same
;; time. For blocks of code, such as fx, this returns the time at which
;; the block is done, allowing the next bit to execute without overlap
(define (queue-event job-ctxt event start-time outbus)
  (define sleep-msec (wait? (current-lead start-time)))
  (if sleep-msec
      (begin
        (sleep (/ sleep-msec MSEC-PER-SEC))
        (queue-event job-ctxt event start-time outbus))
      (begin
        ;(print-event event)
        (cond
          ;; psleep just returns the time with which to start
          ;; the next sound
          [(psleep? event)
           (+
            (* MSEC-PER-SEC
               (psleep-duration event))
            start-time)]
          ;; play note, return the same time
          [(note? event)
           (play-note
            job-ctxt
            (control-note event "out_bus" outbus)
            start-time)
           start-time]
          ;; same as play note
          [(sample? event)
           (play-sample
            job-ctxt
            (control-sample event "out_bus" outbus)
            start-time)
           start-time]
          ;; very similar to play note
          [(fx? event)
           (play-fx
            job-ctxt
            event
            start-time
            (fresh-bus-id)
            outbus)]
          ;; play the loop, either forever or for reps reps.
          ;; returns the time the loop finished
          [(loop? event)
           (play-loop
            job-ctxt
            event
            start-time
            outbus)]
          ;; create a new named thread and play the score
          ;; while continuing this thread's score.
          [(thread? event)
           (save-thread
            (string-append "lsonic-thread-" (number->string (fresh-thread-id)))
            (thread (λ () (queue-events job-ctxt ((thread-block event)) start-time outbus))))
           start-time]
          ;; live_loop is the trickiest.
          ;;If a live_loop already exists, then we should send the thread a message to update the score.
          ;; If it does not, then we create the thread, which should listen for messages
          ;; after each loop iteration.
          [(live_loop? event)
           (run-live-loop job-ctxt event start-time outbus)
           start-time]
          [else (error 'queue-event "unknown event ~v\n" event)]))))


;; how long until the event is supposed to happen?
(define (current-lead time)
  (- time (current-inexact-milliseconds)))

;; determine how long to wait if at all
(define (wait? dt)
  (if (< dt MAX-QUEUE-LEAD)
      #false
      (max MIN-SLEEP-MSEC
           (- dt EXPECTED-MAX-SLEEP-LAG QUEUE-LEAD))))


;; play a note n at vtime given a job context
(define (play-note job-ctxt n vtime)
  ;(printf "~v\n" n)
  (play-synth job-ctxt
              (Score-name n)
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
  ;(printf "~v\n" s)
  (play-synth job-ctxt
              (sample-name s)
              vtime
              (sample-params s)))

;; load an fx with all appropriate information
(define (play-fx job-ctxt effect time inbus outbus)
  (define f (set-fx-busses effect
                           inbus
                           outbus))
  ;(printf "~v\n" f)
  (load-fx job-ctxt
              (Score-name f)
              time
              (fx-params f))
  (queue-events job-ctxt ((fx-block f)) time inbus))

;; plays a loop, possibly forever
(define (play-loop job-ctxt lp time outbus)
  (cond
    ;; infinite loop
    [(< (loop-reps lp) 0)
     (play-loop
      job-ctxt
      lp
      (queue-events
       job-ctxt
       ((loop-block lp))
       time
       outbus)
      outbus)]
    ;; done with finite loop
    [(zero? (loop-reps lp)) time]
    ;; still looping
    [else (play-loop
           job-ctxt
           (sub1loop lp)
           (queue-events
            job-ctxt
            ((loop-block lp))
            time
            outbus)
           outbus)]))

;; runs or updates a live-loop
(define (run-live-loop job-ctxt event time outbus)
  (if (thread-exists? (Score-name event))
      (thread-send (get-thread-by-name (Score-name event))
                   event)
      (save-thread (Score-name event)
                   (thread (λ ()
                             (play-live-loop job-ctxt event time outbus))))))

;; a plays a live-loop. At the end of each iteration, check
;; for messages that change the loop
(define (play-live-loop job-ctxt event time outbus)
  (define new-start (queue-events job-ctxt ((live_loop-block event)) time outbus))
  (define new-event (thread-try-receive))
  (if new-event
      (play-live-loop job-ctxt new-event new-start outbus)
      (play-live-loop job-ctxt event new-start outbus)))

;; prints out an event
(define (print-event event)
  (cond
    [(note? event) (printf "note: ~v\n" (Score-name event))]
    [(sample? event) (printf "sample: ~v\n" (sample-path event))]
    [(psleep? event) (printf "sleep: ~v\n" (psleep-duration event))]
    [(fx? event) (printf "fx: ~v\n" (Score-name event))]
    [(loop? event) (printf "looping ~v times\n" (loop-reps event))]
    [else (void)]))

;; control note or sample
;; control a note, sample, or fx
(define (control s . args)
  (cond [(note? s) (apply control-note
                          (flatten (list s args)))]
        [(sample? s) (apply control-sample (flatten (list s args)))]
        [(fx? s) (apply control-fx (flatten (list s args)))]
        [else (error 'control "not a note, sample, or fx")]))

;; let's provide a function to evaluate
;; the definitions-text the button gets.
;; borrowed from
;;  http://stackoverflow.com/questions/10399315/how-to-eval-strings-in-racket
;; is there a better way to pass new code?
(define-namespace-anchor anc)
(define ns (namespace-anchor->namespace anc))
(define (l-eval text)
  (eval (read (open-input-string text)) ns))

;; the removal of uscore->score has made this file
;; pretty much untestable. instead there are
;; system tests located in the "test" folder.
;; was this a bad decision?
;(module+ test)