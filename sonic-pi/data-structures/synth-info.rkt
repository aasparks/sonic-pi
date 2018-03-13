#lang typed/racket/base

(require "common.rkt")
(provide get-synth-args
         get-fx-args
         )
#|
 This file is part of Sonic Pi: http://sonic-pi.net
 Full project source: https://github.com/samaaron/sonic-pi
 License: https://github.com/samaaron/sonic-pi/blob/master/LICENSE.md

 Copyright 2013, 2014, 2015, 2016 by Sam Aaron (http://sam.aaron.name).
 All rights reserved.

 Permission is granted for use, copying, modification, and
 distribution of modified versions of this work as long as this
 notice is included.

 This file has been translated from Ruby to Racket by Austin Sparks
 for use on this project.
|#


;; Technically, I could just send the arguments passed to a synth
;; because the backend will already know all these things.
;; For now, I'll send everything.
;; TODO: don't send all args. error check passed in args and only send those.



;; As it turns out, some synths have default values that are specific
;; to them, especially fx. There is far too much data in here to
;; store in memory. It seems to me that classes are too complicated
;; for this. A hash table with everything is going to take up WAY
;; too much memory. This may be a really stupid approach but I think
;; I will make a series of functions that create the defaults for each
;; synth. This way I can (hopefully) reduce the memory usage here.
(: get-synth-args (Symbol -> (U (Listof Param) Null)))
(define (get-synth-args name)
  ((hash-ref synth-thunks name
             (λ () (error 'synth "synth not found: ~e" name)))))
(: get-fx-args (Symbol -> (U (Listof Param) Null)))
(define (get-fx-args name)
  ((hash-ref fx-thunks name
             (λ () (error 'fx "fx not found: ~e" name)))))


;; this is needed frequently. takes a name and value
;; and adds all the _slide* args after it so I don't
;; have to repeat it so much
;; TODO: go back and use this function
(: make-slide (Bytes Real -> (Listof Param)))
(define (make-slide name val)
  (list (Param name val)
        (Param (bytes-append name #"_slide") 0)
        (Param (bytes-append name #"_slide_shape") 1)
        (Param (bytes-append name #"_slide_curve") 0)))

;; Interestingly enough, I spent two days debugging this
;; file because the default synths as stated in "synthinfo.rb"
;; do not actually seem to match those in the synth definition
;; files, found in etc/synthdefs/definitions. Reading through
;; these files, I see lots of differences in the default.
;; It seems that each synth going to need more attention.
(: sonic-pi-synth (-> (Listof Param)))
(define (sonic-pi-synth)
  (append
   (list (Param #"note_slide" 0)
         (Param #"note_slide_shape" 1)
         (Param #"note_slide_curve" 0))
   (make-slide #"amp" 1)
   (make-slide #"pan" 0)
   (adsr 0 0 0 1)
   (adsr-level 1 -1 1)
   (list (Param #"env_curve" 1)
         (Param #"out_bus" 10))))

;; most variation happens in ADSR
;; and ADSR_level so let's write a function that
;; accepts values
(: adsr (Real Real Real Real -> (Listof Param)))
(define (adsr a d s r)
  (list
   (Param #"attack" a)
   (Param #"decay" d)
   (Param #"sustain" s)
   (Param #"release" r)))

(: adsr-level (Real Real Real -> (Listof Param)))
(define (adsr-level a d s)
  (list
   (Param #"attack_level" a)
   (Param #"decay_level" d)
   (Param #"sustain_level" s)))

(: cutoff-adsr (Real Real Real Real -> (Listof Param)))
(define (cutoff-adsr a d s r)
  (list
   (Param #"cutoff_attack" a)
   (Param #"cutoff_decay" d)
   (Param #"cutoff_sustain" s)
   (Param #"cutoff_release" r)))

(: cutoff-adsr-level (Real Real Real -> (Listof Param)))
(define (cutoff-adsr-level a d s)
  (list
   (Param #"cutoff_attack_level" a)
   (Param #"cutoff_decay_level" d)
   (Param #"cutoff_sustain_level" s)))


;; The following functions provide the collection of
;; the above groups to create the correct synth info.
;; Many will just be renaming a single group
(define dull_bell sonic-pi-synth)

(define pretty_bell sonic-pi-synth)

(define beep sonic-pi-synth)

(define (saw)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)))

(define square saw)

(define (pulse)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)
          (make-slide #"pulse_width" 0.5)))

(define (subpulse)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)
          (make-slide #"pulse_width" 0.5)
          (make-slide #"sub_amp" 1)
          (make-slide #"sub_detune" -12)))

(define (tri)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)))

(define (dsaw)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)
          (make-slide #"detune" 0.1)))

(define dtri dsaw)

(define (dpulse)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)
          (make-slide #"detune" 0.1)
          (make-slide #"pulse_width" 0.5)
          (list (Param #"dpulse_width" -1)
                (Param #"dpulse_width_slide" -1)
                (Param #"dpulse_width_slide_shape" -1)
                (Param #"dpulse_width_slide_curve" -1))))

(define (fm)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)
          (make-slide #"divisor" 2.0)
          (make-slide #"depth" 1.0)))

(define (mod_fm)
  (append (fm)
          (make-slide #"mod_phase" 0.25)
          (make-slide #"mod_range" 5)
          (make-slide #"mod_pulse_width" 0.5)
          (list (Param #"mod_phase_offset" 0)
                (Param #"mod_wave" 1)
                (Param #"mod_invert_wave" 0))))

(define (mod_saw)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)
          (make-slide #"mod_phase" 0.25)
          (make-slide #"mod_range" 5)
          (make-slide #"mod_pulse_width" 0.5)
          (list (Param #"mod_phase_offset" 0)
                (Param #"mod_wave" 1)
                (Param #"mod_invert_wave" 0))))

(define (mod_dsaw)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)
          (make-slide #"mod_phase" 0.25)
          (make-slide #"mod_range" 5)
          (make-slide #"mod_pulse_width" 0.5)
          (make-slide #"detune" 0.1)
          (list (Param #"mod_phase_offset" 0)
                (Param #"mod_wave" 1)
                (Param #"mod_invert_wave" 0))))

(define mod_sine mod_saw)

(define mod_tri mod_sine)

(define (mod_pulse)
  (append (mod_saw)
          (make-slide #"pulse_width" 0.5)))

(define (tb303)
  (append (list (Param #"note_slide" 0)
                (Param #"note_slide_shape" 1)
                (Param #"note_slide_curve" 0)
                (Param #"env_curve" 2)
                (Param #"out_bus" 10))
          (make-slide #"amp" 1)
          (make-slide #"pan" 0)
          (adsr 0.01 0 0 1)
          (adsr-level 1 -1 1)
          (make-slide #"cutoff" 120)
          (cutoff-adsr -1 -1 -1 -1)
          (make-slide #"cutoff_min" 30)
          (cutoff-adsr-level 1 -1 1)
          (list (Param #"cutoff_env_curve" 2))
          (make-slide #"res" 0.9)
          (list (Param #"wave" 0))
          (make-slide #"pulse_width" 0.5)))

(define (supersaw)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 130)
          (make-slide #"res" 0.7)))

(define (hoover)
  (append (list (Param #"note_slide" 0)
                (Param #"note_slide_shape" 1)
                (Param #"note_slide_curve" 0)
                (Param #"env_curve" 1)
                (Param #"out_bus" 10))
          (make-slide #"amp" 1)
          (make-slide #"pan" 0)
          (adsr 0.05 0.0 0.0 1)
          (adsr-level 1 -1 1)
          (make-slide #"cutoff" 130)
          (make-slide #"res" 0.1)
          (list (Param #"pre_amp" 10)
                (Param #"amp-fudge" 2.5))))

(define (synth_violin)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)
          (make-slide #"vibrato_rate" 6)
          (make-slide #"vibrato_depth" 0.15)
          (list (Param #"vibrato_delay" 0.5)
                (Param #"vibrato_onset" 0.1))))

(define (pluck)
  (append (sonic-pi-synth)
          (list (Param #"noise_amp" 0.8)
                (Param #"max_delay_time" 0.125)
                (Param #"pluck_decay" 30)
                (Param #"coef" 0.3))))

(define (piano)
  (append (sonic-pi-synth)
          (list (Param #"vel" 0.2)
                (Param #"hard" 0.5)
                (Param #"velcurve" 0.8)
                (Param #"stereo_width" 0))))

(define (growl)
  (append (list (Param #"note_slide" 0)
                (Param #"note_slide_shape" 1)
                (Param #"note_slide_curve" 0)
                (Param #"env_curve" 1)
                (Param #"out_bus" 10))
          (make-slide #"amp" 1)
          (make-slide #"pan" 0)
          (adsr 0.1 0.0 0.0 1)
          (adsr-level 1 -1 1)
          (make-slide #"cutoff" 130)
          (make-slide #"res" 0.7)))

(define (dark_ambience)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 110)
          (make-slide #"res" 0.7)
          (make-slide #"detune1" 12)
          (make-slide #"detune2" 24)
          (list (Param #"noise" 0)
                (Param #"ring" 0.2)
                (Param #"room" 70)
                (Param #"reverb_time" 100))))

(define (hollow)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 90)
          (make-slide #"res" 0.99)
          (list (Param #"noise" 1)
                (Param #"norm" 0))))

(define (zawa)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 100)
          (make-slide #"res" 0.9)
          (make-slide #"phase" 1)
          (list (Param #"phase_offset" 0)
                (Param #"wave" 3)
                (Param #"disable_wave" 0)
                (Param #"invert_wave" 0))
          (make-slide #"pulse_width" 0.5)
          (make-slide #"range" 24)))

(define (prophet)
  (append
   (list (Param #"note_slide" 0)
         (Param #"note_slide_shape" 1)
         (Param #"note_slide_curve" 0)
         (Param #"env_curve" 1)
         (Param #"out_bus" 10))
   (make-slide #"amp" 1)
   (make-slide #"pan" 0)
   (adsr 0.01 0 0 1)
   (adsr-level 1 -1 1)
   (make-slide #"cutoff" 110)
   (make-slide #"res" 0.7)))

(define (chiplead)
  (append (sonic-pi-synth)
          (list (Param #"width" 0)
                (Param #"note_resolution" 0.1))))
(define (chipbass)
  (append (sonic-pi-synth)
          (list (Param #"note_resolution" 0))))

(define (noise)
  (append (make-slide #"amp" 1)
          (make-slide #"pan" 0)
          (adsr 0 0 0 1)
          (adsr-level 1 -1 1)
          (make-slide #"cutoff" 110)
          (make-slide #"res" 0)))

(define gnoise noise)
(define bnoise noise)
(define pnoise noise)
(define cnoise noise)

(define (chipnoise)
  (append (sonic-pi-synth)
          (make-slide #"freq_band" 0)))

(define (tech_saws)
  (append (sonic-pi-synth)
          (make-slide #"cutoff" 130)
          (make-slide #"res" 0.7)))

;; NB: How can I use reflection to avoid using all
;;     of this? I've created a function named
;;     identically to their symbol name so that
;;     I can do it once I figure it out.
;;     eval doesn't seem to be doing the trick
;;     but maybe I'm just dumb.
(: synth-thunks (HashTable Symbol (-> (Listof Param))))
(define synth-thunks (make-hash))
(hash-set! synth-thunks 'dull_bell dull_bell)
(hash-set! synth-thunks 'pretty_bell pretty_bell)
(hash-set! synth-thunks 'beep beep)
(hash-set! synth-thunks 'saw saw)
(hash-set! synth-thunks 'square square)
(hash-set! synth-thunks 'pulse pulse)
(hash-set! synth-thunks 'subpulse subpulse)
(hash-set! synth-thunks 'tri tri)
(hash-set! synth-thunks 'dsaw dsaw)
(hash-set! synth-thunks 'dtri dtri)
(hash-set! synth-thunks 'dpulse dpulse)
(hash-set! synth-thunks 'fm fm)
(hash-set! synth-thunks 'mod_fm mod_fm)
(hash-set! synth-thunks 'mod_saw mod_saw)
(hash-set! synth-thunks 'mod_dsaw mod_dsaw)
(hash-set! synth-thunks 'mod_sine mod_sine)
(hash-set! synth-thunks 'mod_tri mod_tri)
(hash-set! synth-thunks 'mod_pulse mod_pulse)
(hash-set! synth-thunks 'tb303 tb303)
(hash-set! synth-thunks 'supersaw supersaw)
(hash-set! synth-thunks 'hoover hoover)
(hash-set! synth-thunks 'synth_violin synth_violin)
(hash-set! synth-thunks 'pluck pluck)
(hash-set! synth-thunks 'piano piano)
(hash-set! synth-thunks 'growl growl)
(hash-set! synth-thunks 'dark_ambience dark_ambience)
(hash-set! synth-thunks 'hollow hollow)
(hash-set! synth-thunks 'zawa zawa)
(hash-set! synth-thunks 'prophet prophet)
(hash-set! synth-thunks 'chiplead chiplead)
(hash-set! synth-thunks 'chipbass chipbass)
(hash-set! synth-thunks 'noise noise)
(hash-set! synth-thunks 'gnoise gnoise)
(hash-set! synth-thunks 'bnoise bnoise)
(hash-set! synth-thunks 'pnoise pnoise)
(hash-set! synth-thunks 'cnoise cnoise)
(hash-set! synth-thunks 'chipnoise chipnoise)
(hash-set! synth-thunks 'tech_saws tech_saws)

;; the only fx has in common is in_bus and out_bus
(define (sonic-pi-fx)
  (list (Param #"in_bus" 0)
        (Param #"out_bus" 0)))

;; Now for Fx default values
(define (eq)
  (append
   (sonic-pi-fx)
   (make-slide #"low_shelf" 0)
   (make-slide #"low_shelf_note" 43.349957)
   (make-slide #"low_shelf_slope" 1)
   (make-slide #"low" 0)
   (make-slide #"low_note" 59.2130948)
   (make-slide #"low_q" 0.6)
   (make-slide #"mid" 0)
   (make-slide #"mid_note" 83.2130948)
   (make-slide #"mid_q" 0.6)
   (make-slide #"high" 0)
   (make-slide #"high_note" 104.9013539)
   (make-slide #"high_q" 0.6)
   (make-slide #"high_shelf" 0)
   (make-slide #"high_shelf_note" 114.2326448)
   (make-slide #"high_shelf_slope" 1)))
  
(define (gverb)
  (append
   (sonic-pi-fx)
   (make-slide #"spread" 0.5)
   (make-slide #"damp" 0.5)
   (make-slide #"pre_damp" 0.5)
   (make-slide #"dry" 1)
   (list (Param #"room" 10)
         (Param #"max_room" -1)
         (Param #"release" 3)
         (Param #"ref_level" 0.7)
         (Param #"tail_level" 0.5))))
  
(define (reverb)
  (append
   (sonic-pi-fx)
   (make-slide #"room" 0.6)
   (make-slide #"damp" 0.5)))
  
(define (krush)
  (append
   (sonic-pi-fx)
   (make-slide #"gain" 5)
   (make-slide #"cutoff" 100)
   (make-slide #"res" 0)))
  
(define (bitcrusher)
  (append
   (sonic-pi-fx)
   (make-slide #"sample_rate" 10000)
   (make-slide #"bits" 8)
   (make-slide #"cutoff" 0)))
  
(define level sonic-pi-fx)
  
(define (mono)
  (append
   (sonic-pi-fx)
   (make-slide #"pan" 0)))
  
(define (echo)
  (append
   (sonic-pi-fx)
   (make-slide #"phase" 0.25)
   (make-slide #"decay" 2)
   (list (Param #"max_phase" 2))))
  
(define (slicer)
  (append (sonic-pi-fx)
          (make-slide #"phase" 0.25)
          (make-slide #"amp_min" 0)
          (make-slide #"amp_max" 1)
          (make-slide #"pulse_width" 0.5)
          (list (Param #"wave" 1)
                (Param #"phase_offset" 0)
                (Param #"invert_wave" 0)
                (Param #"seed" 0)
                (Param #"rand_buf" 0))
          (make-slide #"probability" 0)
          (make-slide #"prob_pos" 0)
          (make-slide #"smooth" 0)
          (make-slide #"smooth_up" 0)
          (make-slide #"smooth_down" 0)))
  
(define (wobble)
  (append (sonic-pi-fx)
          (make-slide #"phase" 0.5)
          (make-slide #"cutoff_min" 60)
          (make-slide #"cutoff_max" 120)
          (make-slide #"res" 0.8)
          (list (Param #"wave" 0)
                (Param #"invert_wave" 0)
                (Param #"phase_offset" 0)
                (Param #"filter" 0)
                (Param #"seed" 0)
                (Param #"rand_buf" 0))
          (make-slide #"pulse_width" 0.5)
          (make-slide #"probability" 0)
          (make-slide #"prob_pos" 0)
          (make-slide #"smooth" 0)
          (make-slide #"smooth_up" 0)
          (make-slide #"smooth_down" 0)))
  
(define (panslicer)
  (append (slicer)
          (make-slide #"pan_min" -1)
          (make-slide #"pan_max" 1)))
  
(define (ixi_techno)
  (append (sonic-pi-fx)
          (make-slide #"phase" 4)
          (make-slide #"cutoff_min" 60)
          (make-slide #"cutoff_max" 120)
          (make-slide #"res" 0.8)))
  
(define (whammy)
  (append (sonic-pi-fx)
          (make-slide #"transpose" 12)
          (list (Param #"max_delay_time" 1)
                (Param #"deltime" 0.05)
                (Param #"grainsize" 0.075))))
  
(define (compressor)
  (append (sonic-pi-fx)
          (make-slide #"threshold" 0.2)
          (make-slide #"clamp_time" 0.01)
          (make-slide #"slope_above" 0.5)
          (make-slide #"slope_below" 1)
          (make-slide #"relax_time" 0.01)))
  
(define (vowel)
  (append (sonic-pi-fx)
          (list (Param #"vowel_sound" 1)
                (Param #"voice" 0))))
  
(define (octaver)
  (append (sonic-pi-fx)
          (make-slide #"super_amp" 1)
          (make-slide #"sub_amp" 1)
          (make-slide #"subsub_amp" 1)))
  
(define (chorus)
  (append (sonic-pi-fx)
          (make-slide #"phase" 0.25)
          (make-slide #"decay" 0.00001)
          (list (Param #"max_phase" 1))))
  
(define (ring_mod)
  (append (sonic-pi-fx)
          (make-slide #"freq" 30)
          (make-slide #"mod_amp" 1)))
  
(define (bpf)
  (append (sonic-pi-fx)
          (make-slide #"centre" 100)
          (make-slide #"res" 0.6)))
  
(define (rbpf)
  (append (sonic-pi-fx)
          (make-slide #"centre" 100)
          (make-slide #"res" 0.5)))
  
(define nbpf bpf)
  
(define nrbpf rbpf)
  
(define (lpf)
  (append (sonic-pi-fx)
          (make-slide #"cutoff" 100)))
  
(define (rlpf)
  (append (lpf)
          (make-slide #"res" 0.5)))
  
(define nrlpf rlpf)
  
(define (hpf)
  (append (sonic-pi-fx)
          (make-slide #"cutoff" 100)))
  
(define (rhpf)
  (append (hpf)
          (make-slide #"res" 0.5)))
  
(define nrhpf rhpf)
  
(define (band_eq)
  (append (sonic-pi-fx)
          (make-slide #"freq" 100)
          (make-slide #"res" 0.6)
          (make-slide #"db" 0.6)))
  
(define nlpf lpf)
  
(define nhpf hpf)
  
(define (normaliser)
  (append (sonic-pi-fx)
          (make-slide #"level" 1)))
  
(define (tanh)
  (append (sonic-pi-fx)
          (make-slide #"krunch" 5)))
  
(define (pitch_shift)
  (append (sonic-pi-fx)
          (make-slide #"window_size" 0.2)
          (make-slide #"pitch" 0)
          (make-slide #"pitch_dis" 0.0)
          (make-slide #"time_dis" 0.0)))
  
(define (distortion)
  (append (sonic-pi-fx)
          (make-slide #"distort" 0.5)))
  
(define (pan)
  (append (sonic-pi-fx)
          (make-slide #"pan" 0)))
  
(define (flanger)
  (append (sonic-pi-fx)
          (make-slide #"phase" 4)
          (list (Param #"wave" 4)
                (Param #"invert_wave" 0)
                (Param #"stereo_invert_wave" 0)
                (Param #"max_delay" 20)
                (Param #"invert_flange" 0))
          (make-slide #"delay" 5)
          (make-slide #"depth" 5)
          (make-slide #"decay" 2)
          (make-slide #"feedback" 0)))
  
(define (tremolo)
  (append (sonic-pi-fx)
          (make-slide #"phase" 4)
          (list (Param #"wave" 2)
                (Param #"invert_wave" 0))
          (make-slide #"depth" 0.5)))

(: fx-thunks (HashTable Symbol (-> (Listof Param))))
(define fx-thunks (make-hash))
(hash-set! fx-thunks 'eq eq)
(hash-set! fx-thunks 'gverb gverb)
(hash-set! fx-thunks 'reverb reverb)
(hash-set! fx-thunks 'krush krush)
(hash-set! fx-thunks 'bitcrusher bitcrusher)
(hash-set! fx-thunks 'level level)
(hash-set! fx-thunks 'mono mono)
(hash-set! fx-thunks 'echo echo)
(hash-set! fx-thunks 'slicer slicer)
(hash-set! fx-thunks 'wobble wobble)
(hash-set! fx-thunks 'panslicer panslicer)
(hash-set! fx-thunks 'ixi_techno ixi_techno)
(hash-set! fx-thunks 'whammy whammy)
(hash-set! fx-thunks 'compressor compressor)
(hash-set! fx-thunks 'vowel vowel)
(hash-set! fx-thunks 'octaver octaver)
(hash-set! fx-thunks 'chorus chorus)
(hash-set! fx-thunks 'ring_mod ring_mod)
(hash-set! fx-thunks 'bpf bpf)
(hash-set! fx-thunks 'rbpf rbpf)
(hash-set! fx-thunks 'nbpf nbpf)
(hash-set! fx-thunks 'nrbpf nrbpf)
(hash-set! fx-thunks 'lpf lpf)
(hash-set! fx-thunks 'rlpf rlpf)
(hash-set! fx-thunks 'nrlpf nrlpf)
(hash-set! fx-thunks 'hpf hpf)
(hash-set! fx-thunks 'rhpf rhpf)
(hash-set! fx-thunks 'nrhpf nrhpf)
(hash-set! fx-thunks 'band_eq band_eq)
(hash-set! fx-thunks 'nlpf nlpf)
(hash-set! fx-thunks 'nhpf nhpf)
(hash-set! fx-thunks 'normaliser normaliser)
(hash-set! fx-thunks 'tanh tanh)
(hash-set! fx-thunks 'pitch_shift pitch_shift)
(hash-set! fx-thunks 'distortion distortion)
(hash-set! fx-thunks 'pan pan)
(hash-set! fx-thunks 'flanger flanger)
(hash-set! fx-thunks 'tremolo tremolo)

;; This is a lot of lines but the Sonic Pi one
;; is ~8000 so...