#lang typed/racket/base

(require racket/match
         racket/list
         "synth-info.rkt"
         "common.rkt")

(provide note
         (rename-out [Note? note?]
                     ;[Score-name note-name]
                     [Note-params note-params])
         chord
         control-note)

;; a note has a distinguished synth name,
;; followed by parameters
;; A Note is (note Bytes (listof ParamAssoc))
(struct Note Score ([params : (Listof Param)]) #:transparent)

;; create a note given a synth name, pitch number, and optional
;; parameters
(: note (Symbol (U String Real) (U String Real) * -> Note))
(define (note synth midi-pitch . param-parts)
  (define other-params (group-params param-parts))
  (Note (bytes-append #"sonic-pi-"
                      (string->bytes/utf-8 (symbol->string synth)))
        (cons (Param #"note" (get-pitch midi-pitch))
              (complete-field-list other-params (get-synth-args synth)))))

;; convert a given note in musical notation to a midi-pitch
;; if not already given
(: get-pitch ((U String Real) -> Real))
(define (get-pitch midi-pitch)
  (if (real? midi-pitch)
      midi-pitch
      (note->midi midi-pitch)))

;; convert a note in musical notation to a midi-pitch
;; I'm going off the table found at
;;   http://www.midimountain.com/midi/midi_note_numbers.html
(: note->midi (String -> Real))
(define (note->midi n)
  (let ([n2 (regexp-match #rx"[a-gA-G][sSbBfF]?[0-9]?"
                          n)])
    (+ (note-offset n)
       (accidental n)
       (* 12 (octave n)))))

;; converts the note string to it's offset in the midi table
(: note-offset (String -> Real))
(define (note-offset n)
  (let ([note (regexp-match #rx"[a-gA-G]" n)])
      (if note
          (match (string-downcase (car note))
            ["a" 9]
            ["b" 11]
            ["c" 0]
            ["d" 2]
            ["e" 4]
            ["f" 5]
            ["g" 7])
          (error 'note "invalid note representation"))))

;; finds the offset in the table when sharp or flat
;; is specified
(: accidental (String -> Real))
(define (accidental n)
  (let ([acc (regexp-match #rx"[sSbBfF]"
                           ;; need to ignore first
                           ;; letter because notes
                           ;; can be b or f
                           (substring n 1 (string-length n)))])
    (if acc
        (match (string-downcase (car acc))
          ["s" 1]
          ["b" -1]
          ["f" -1])
        ;; we could still get a bad acc here
        (if (regexp-match #rx"[a-zA-Z]"
                          (substring n 1 (string-length n)))
            (error "bad accidental")
            0))))

;; gets the octave for a note. the default is 4
(: octave (String -> Real))
(define (octave n)
  (let ([num (regexp-match #rx"[0-9]" n)])
    (if num
        (cast (string->number (car num)) Real)
        4)))

;; change a note's parameters to specified new ones
(: control-note (Note (U String Real) * -> Note))
(define (control-note n . param-parts)
  (Note (Score-name n)
        (complete-field-list (group-params param-parts) (Note-params n))))

;; hash table representing the intervals for different chords
(: types (HashTable String (Listof Real)))
(define types #hash(("major" . (0 4 7))
                    ("minor" . (0 3 7))
                    ("major7" . (0 4 7 11))
                    ("dom7" . (0 4 7 10))
                    ("minor7" . (0 3 7 10))
                    ("aug" . (0 4 8))
                    ("dim" . (0 3 6))
                    ("dim7" . (0 3 6 9))))

;; create a musical chord given the synth, pitch and chord type
;; i.e. "beep" "e2" "minor"
(: chord (Symbol (U String Real) String -> (Listof Note)))
(define (chord synth pitch type) ;; what is a better name for type?
  (map (λ ([p : Real]) (note synth p))
       (map (λ ([i : Real]) (+ (get-pitch pitch)
                               i))
        (hash-ref types type))))

(module+ test
  (require typed/rackunit)

  (check-equal? (group-params (list "note_slide" 1 "pan" 2))
               (list (Param #"note_slide" 1)
                     (Param #"pan" 2)))
  (check-exn
   exn:fail?
   (λ ()
     (group-params (list 1 2 "pan" 2))))
  (check-exn
   exn:fail?
   (λ ()
     (group-params (list "note_slide" 1 "pan" 2 "bad"))))

  (check-equal? (note->midi "C") 48)
  (check-equal? (note->midi "C0") 0)
  (check-equal? (note->midi "Fs") 54)
  (check-equal? (note->midi "gb") 54)
  (check-equal? (note->midi "bb3") 46)
  (check-equal? (note->midi "df") 49)
  (check-equal? (note->midi "A9") 117)
  (check-equal? (note->midi "es6") 77)
  (check-exn exn:fail? (λ () (note->midi "hs")))
  (check-exn exn:fail? (λ () (note->midi "ar")))

  (check-equal? (note 'zawa 39)
                (Note #"sonic-pi-zawa"
                      (list
                       (Param #"note" 39)
                       (Param #"note_slide" 0)
                       (Param #"note_slide_shape" 1)
                       (Param #"note_slide_curve" 0)
                       (Param #"amp" 1)
                       (Param #"amp_slide" 0)
                       (Param #"amp_slide_shape" 1)
                       (Param #"amp_slide_curve" 0)
                       (Param #"pan" 0)
                       (Param #"pan_slide" 0)
                       (Param #"pan_slide_shape" 1)
                       (Param #"pan_slide_curve" 0)
                       (Param #"attack" 0)
                       (Param #"decay" 0)
                       (Param #"sustain" 0)
                       (Param #"release" 1)
                       (Param #"attack_level" 1)
                       (Param #"decay_level" -1)
                       (Param #"sustain_level" 1)
                       (Param #"env_curve" 1)
                       (Param #"out_bus" 10)
                       (Param #"cutoff" 100)
                       (Param #"cutoff_slide" 0)
                       (Param #"cutoff_slide_shape" 1)
                       (Param #"cutoff_slide_curve" 0)
                       (Param #"res" 0.9)
                       (Param #"res_slide" 0)
                       (Param #"res_slide_shape" 1)
                       (Param #"res_slide_curve" 0)
                       (Param #"phase" 1)
                       (Param #"phase_slide" 0)
                       (Param #"phase_slide_shape" 1)
                       (Param #"phase_slide_curve" 0)
                       (Param #"phase_offset" 0)
                       (Param #"wave" 3)
                       (Param #"disable_wave" 0)
                       (Param #"invert_wave" 0)
                       (Param #"pulse_width" 0.5)
                       (Param #"pulse_width_slide" 0)
                       (Param #"pulse_width_slide_shape" 1)
                       (Param #"pulse_width_slide_curve" 0)
                       (Param #"range" 24)
                       (Param #"range_slide" 0)
                       (Param #"range_slide_shape" 1)
                       (Param #"range_slide_curve" 0))))

  (check-equal? (note 'zawa 39 "decay" 0.9)
                (Note #"sonic-pi-zawa"
                      (list
                       (Param #"note" 39)
                       (Param #"note_slide" 0)
                       (Param #"note_slide_shape" 1)
                       (Param #"note_slide_curve" 0)
                       (Param #"amp" 1)
                       (Param #"amp_slide" 0)
                       (Param #"amp_slide_shape" 1)
                       (Param #"amp_slide_curve" 0)
                       (Param #"pan" 0)
                       (Param #"pan_slide" 0)
                       (Param #"pan_slide_shape" 1)
                       (Param #"pan_slide_curve" 0)
                       (Param #"attack" 0)
                       (Param #"decay" 0.9)
                       (Param #"sustain" 0)
                       (Param #"release" 1)
                       (Param #"attack_level" 1)
                       (Param #"decay_level" -1)
                       (Param #"sustain_level" 1)
                       (Param #"env_curve" 1)
                       (Param #"out_bus" 10)
                       (Param #"cutoff" 100)
                       (Param #"cutoff_slide" 0)
                       (Param #"cutoff_slide_shape" 1)
                       (Param #"cutoff_slide_curve" 0)
                       (Param #"res" 0.9)
                       (Param #"res_slide" 0)
                       (Param #"res_slide_shape" 1)
                       (Param #"res_slide_curve" 0)
                       (Param #"phase" 1)
                       (Param #"phase_slide" 0)
                       (Param #"phase_slide_shape" 1)
                       (Param #"phase_slide_curve" 0)
                       (Param #"phase_offset" 0)
                       (Param #"wave" 3)
                       (Param #"disable_wave" 0)
                       (Param #"invert_wave" 0)
                       (Param #"pulse_width" 0.5)
                       (Param #"pulse_width_slide" 0)
                       (Param #"pulse_width_slide_shape" 1)
                       (Param #"pulse_width_slide_curve" 0)
                       (Param #"range" 24)
                       (Param #"range_slide" 0)
                       (Param #"range_slide_shape" 1)
                       (Param #"range_slide_curve" 0))))

  (check-equal? (note 'zawa "C2" "decay" 0.9)
                (Note #"sonic-pi-zawa"
                      (list
                       (Param #"note" 24)
                       (Param #"note_slide" 0)
                       (Param #"note_slide_shape" 1)
                       (Param #"note_slide_curve" 0)
                       (Param #"amp" 1)
                       (Param #"amp_slide" 0)
                       (Param #"amp_slide_shape" 1)
                       (Param #"amp_slide_curve" 0)
                       (Param #"pan" 0)
                       (Param #"pan_slide" 0)
                       (Param #"pan_slide_shape" 1)
                       (Param #"pan_slide_curve" 0)
                       (Param #"attack" 0)
                       (Param #"decay" 0.9)
                       (Param #"sustain" 0)
                       (Param #"release" 1)
                       (Param #"attack_level" 1)
                       (Param #"decay_level" -1)
                       (Param #"sustain_level" 1)
                       (Param #"env_curve" 1)
                       (Param #"out_bus" 10)
                       (Param #"cutoff" 100)
                       (Param #"cutoff_slide" 0)
                       (Param #"cutoff_slide_shape" 1)
                       (Param #"cutoff_slide_curve" 0)
                       (Param #"res" 0.9)
                       (Param #"res_slide" 0)
                       (Param #"res_slide_shape" 1)
                       (Param #"res_slide_curve" 0)
                       (Param #"phase" 1)
                       (Param #"phase_slide" 0)
                       (Param #"phase_slide_shape" 1)
                       (Param #"phase_slide_curve" 0)
                       (Param #"phase_offset" 0)
                       (Param #"wave" 3)
                       (Param #"disable_wave" 0)
                       (Param #"invert_wave" 0)
                       (Param #"pulse_width" 0.5)
                       (Param #"pulse_width_slide" 0)
                       (Param #"pulse_width_slide_shape" 1)
                       (Param #"pulse_width_slide_curve" 0)
                       (Param #"range" 24)
                       (Param #"range_slide" 0)
                       (Param #"range_slide_shape" 1)
                       (Param #"range_slide_curve" 0))))

  (check-equal? (control-note (note 'zawa "AF3" "decay" 2) "decay" 0.9)
                (Note #"sonic-pi-zawa"
                      (list
                       (Param #"note" 44)
                       (Param #"note_slide" 0)
                       (Param #"note_slide_shape" 1)
                       (Param #"note_slide_curve" 0)
                       (Param #"amp" 1)
                       (Param #"amp_slide" 0)
                       (Param #"amp_slide_shape" 1)
                       (Param #"amp_slide_curve" 0)
                       (Param #"pan" 0)
                       (Param #"pan_slide" 0)
                       (Param #"pan_slide_shape" 1)
                       (Param #"pan_slide_curve" 0)
                       (Param #"attack" 0)
                       (Param #"decay" 0.9)
                       (Param #"sustain" 0)
                       (Param #"release" 1)
                       (Param #"attack_level" 1)
                       (Param #"decay_level" -1)
                       (Param #"sustain_level" 1)
                       (Param #"env_curve" 1)
                       (Param #"out_bus" 10)
                       (Param #"cutoff" 100)
                       (Param #"cutoff_slide" 0)
                       (Param #"cutoff_slide_shape" 1)
                       (Param #"cutoff_slide_curve" 0)
                       (Param #"res" 0.9)
                       (Param #"res_slide" 0)
                       (Param #"res_slide_shape" 1)
                       (Param #"res_slide_curve" 0)
                       (Param #"phase" 1)
                       (Param #"phase_slide" 0)
                       (Param #"phase_slide_shape" 1)
                       (Param #"phase_slide_curve" 0)
                       (Param #"phase_offset" 0)
                       (Param #"wave" 3)
                       (Param #"disable_wave" 0)
                       (Param #"invert_wave" 0)
                       (Param #"pulse_width" 0.5)
                       (Param #"pulse_width_slide" 0)
                       (Param #"pulse_width_slide_shape" 1)
                       (Param #"pulse_width_slide_curve" 0)
                       (Param #"range" 24)
                       (Param #"range_slide" 0)
                       (Param #"range_slide_shape" 1)
                       (Param #"range_slide_curve" 0))))
  (check-equal? (chord 'beep "e2" "minor")
                (list (note 'beep 28)
                      (note 'beep 31)
                      (note 'beep 35)))

  )