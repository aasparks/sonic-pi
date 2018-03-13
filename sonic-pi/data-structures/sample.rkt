#lang typed/racket/base

(require racket/match         
         racket/path         
         racket/list
         "common.rkt")

(provide sample
         (rename-out [Sample? sample?]
                     [Score-name sample-name]
                     [Sample-path sample-path]
                     [Sample-params sample-params])
         control-sample
         resolve-specific-sampler)

;; A sample has a distinguished name,
;; an absolute path, then other params
(struct Sample Score ([path : Bytes] [params : (Listof Param)]) #:transparent)

;; default sample arguments
(define default-values
  (list (Param #"buf" 0)
        (Param #"amp" 1)
        (Param #"amp_slide" 0)
        (Param #"amp_slide_shape" 1)
        (Param #"amp_slide_curve" 0)
        (Param #"attack" 0.0)
        (Param #"decay" 0)
        (Param #"sustain" -1)
        (Param #"release" 0.0)
        (Param #"attack_level" 1)
        (Param #"decay_level" -1)
        (Param #"sustain_level" 1)
        (Param #"env_curve" 1)
        (Param #"pan" 0)
        (Param #"pan_slide" 0)
        (Param #"pan_slide_shape" 1)
        (Param #"pan_slide_curve" 0)
        (Param #"lpf" -1)
        (Param #"lpf_slide" 0)
        (Param #"lpf_slide_shape" 1)
        (Param #"lpf_slide_curve" 0)
        (Param #"hpf" -1)
        (Param #"hpf_slide" 0)
        (Param #"hpf_slide_shape" 1)
        (Param #"hpf_slide_curve" 0)
        (Param #"rate" 1)
        (Param #"out_bus" 12)))

;; create a sample given only the name/path and arguments
;; default to basic_stereo_player but set the correct one
;; once it is loaded
(: sample ((U Symbol String) (U String Real) * -> Sample))
(define (sample name . param-parts)
  (define other-params (group-params param-parts))
  (Sample #"sonic-pi-basic_stereo_player"
          (string->bytes/utf-8 (resolve-path name))
          (complete-field-list other-params default-values)))

;; get the absolute path for a sample if not already given
(: resolve-path ((U Symbol String) -> String))
(define (resolve-path path)
  (cond
    ;; a sample given as a symbol is one that is built in
    [(symbol? path) (path->string
                     (build-path (root-dir)
                                 "samples"
                                 (string-append
                                  (symbol->string path)
                                  ".wav")))]
    
    [(absolute-path? path) path]
    [else
     (error 'sample "expected an absolute path to a sample or a symbol naming a built in sample, got ~e" path)]))

;; resolve the specific sampler that is used
;; interesting note: sonic-pi handles the sampler
;; based on basic or complex arguments but, since
;; we pass all the arguments, I'm going to use
;; the complex sampler for all of them. bad choice?
(: resolve-specific-sampler (Sample (Listof Real) -> Sample))
(define (resolve-specific-sampler s b-info)
  (Sample (num-chans->sampler (third b-info))
          (Sample-path s)
          (Sample-params s)))

;; gets the appropriate mixer for the number of channels
(define (num-chans->sampler num-chans)
  (match num-chans
    [1 #"sonic-pi-mono_player"]
    [2 #"sonic-pi-stereo_player"]))

;; change specific arguments of a given sample to new values
(: control-sample (Sample (U String Real) * -> Sample))
(define (control-sample s . param-parts)
  (Sample (Score-name s)
          (Sample-path s)
          (complete-field-list (group-params param-parts) (Sample-params s))))


(module+ test
  (require typed/rackunit)
  (require racket/runtime-path)
  
  (check-equal? (sample 'ambi_choir)
                (Sample #"sonic-pi-basic_stereo_player"
                        (string->bytes/utf-8
                         (path->string
                          (build-path (root-dir)
                                      "samples"
                                      "ambi_choir.wav")))
                        (list (Param #"buf" 0)
                              (Param #"amp" 1)
                              (Param #"amp_slide" 0)
                              (Param #"amp_slide_shape" 1)
                              (Param #"amp_slide_curve" 0)
                              (Param #"attack" 0.0)
                              (Param #"decay" 0)
                              (Param #"sustain" -1)
                              (Param #"release" 0.0)
                              (Param #"attack_level" 1)
                              (Param #"decay_level" -1)
                              (Param #"sustain_level" 1)
                              (Param #"env_curve" 1)
                              (Param #"pan" 0)
                              (Param #"pan_slide" 0)
                              (Param #"pan_slide_shape" 1)
                              (Param #"pan_slide_curve" 0)
                              (Param #"lpf" -1)
                              (Param #"lpf_slide" 0)
                              (Param #"lpf_slide_shape" 1)
                              (Param #"lpf_slide_curve" 0)
                              (Param #"hpf" -1)
                              (Param #"hpf_slide" 0)
                              (Param #"hpf_slide_shape" 1)
                              (Param #"hpf_slide_curve" 0)
                              (Param #"rate" 1)
                              (Param #"out_bus" 12))))

  (check-equal? (sample 'ambi_choir "attack" 1)
                (Sample #"sonic-pi-basic_stereo_player"
                        (string->bytes/utf-8
                         (path->string
                          (build-path (root-dir)
                                      "samples"
                                      "ambi_choir.wav")))
                        (list (Param #"buf" 0)
                              (Param #"amp" 1)
                              (Param #"amp_slide" 0)
                              (Param #"amp_slide_shape" 1)
                              (Param #"amp_slide_curve" 0)
                              (Param #"attack" 1)
                              (Param #"decay" 0)
                              (Param #"sustain" -1)
                              (Param #"release" 0.0)
                              (Param #"attack_level" 1)
                              (Param #"decay_level" -1)
                              (Param #"sustain_level" 1)
                              (Param #"env_curve" 1)
                              (Param #"pan" 0)
                              (Param #"pan_slide" 0)
                              (Param #"pan_slide_shape" 1)
                              (Param #"pan_slide_curve" 0)
                              (Param #"lpf" -1)
                              (Param #"lpf_slide" 0)
                              (Param #"lpf_slide_shape" 1)
                              (Param #"lpf_slide_curve" 0)
                              (Param #"hpf" -1)
                              (Param #"hpf_slide" 0)
                              (Param #"hpf_slide_shape" 1)
                              (Param #"hpf_slide_curve" 0)
                              (Param #"rate" 1)
                              (Param #"out_bus" 12))))
  (check-equal? (control-sample (sample 'ambi_choir)
                                "buf" 2 "out_bus" 10)
                (Sample #"sonic-pi-basic_stereo_player"
                        (string->bytes/utf-8
                         (path->string
                          (build-path (root-dir)
                                      "samples"
                                      "ambi_choir.wav")))
                        (list (Param #"buf" 2)
                              (Param #"amp" 1)
                              (Param #"amp_slide" 0)
                              (Param #"amp_slide_shape" 1)
                              (Param #"amp_slide_curve" 0)
                              (Param #"attack" 0.0)
                              (Param #"decay" 0)
                              (Param #"sustain" -1)
                              (Param #"release" 0.0)
                              (Param #"attack_level" 1)
                              (Param #"decay_level" -1)
                              (Param #"sustain_level" 1)
                              (Param #"env_curve" 1)
                              (Param #"pan" 0)
                              (Param #"pan_slide" 0)
                              (Param #"pan_slide_shape" 1)
                              (Param #"pan_slide_curve" 0)
                              (Param #"lpf" -1)
                              (Param #"lpf_slide" 0)
                              (Param #"lpf_slide_shape" 1)
                              (Param #"lpf_slide_curve" 0)
                              (Param #"hpf" -1)
                              (Param #"hpf_slide" 0)
                              (Param #"hpf_slide_shape" 1)
                              (Param #"hpf_slide_curve" 0)
                              (Param #"rate" 1)
                              (Param #"out_bus" 10))))
  (define-runtime-path here ".")
  (check-equal? (sample (path->string (build-path here "foo.flac")) "amp" 10)
                (Sample #"sonic-pi-basic_stereo_player"
                        (string->bytes/utf-8
                         (path->string
                          (build-path
                           here
                           "foo.flac")))
                        (list (Param #"buf" 0)
                              (Param #"amp" 10)
                              (Param #"amp_slide" 0)
                              (Param #"amp_slide_shape" 1)
                              (Param #"amp_slide_curve" 0)
                              (Param #"attack" 0.0)
                              (Param #"decay" 0)
                              (Param #"sustain" -1)
                              (Param #"release" 0.0)
                              (Param #"attack_level" 1)
                              (Param #"decay_level" -1)
                              (Param #"sustain_level" 1)
                              (Param #"env_curve" 1)
                              (Param #"pan" 0)
                              (Param #"pan_slide" 0)
                              (Param #"pan_slide_shape" 1)
                              (Param #"pan_slide_curve" 0)
                              (Param #"lpf" -1)
                              (Param #"lpf_slide" 0)
                              (Param #"lpf_slide_shape" 1)
                              (Param #"lpf_slide_curve" 0)
                              (Param #"hpf" -1)
                              (Param #"hpf_slide" 0)
                              (Param #"hpf_slide_shape" 1)
                              (Param #"hpf_slide_curve" 0)
                              (Param #"rate" 1)
                              (Param #"out_bus" 12))))
  (check-equal? (resolve-specific-sampler
                 (sample 'ambi_choir)
                 (list 0 0 1 0))
                (Sample #"sonic-pi-mono_player"
                        (string->bytes/utf-8
                         (path->string
                          (build-path (root-dir)
                                      "samples"
                                      "ambi_choir.wav")))
                        (list (Param #"buf" 0)
                              (Param #"amp" 1)
                              (Param #"amp_slide" 0)
                              (Param #"amp_slide_shape" 1)
                              (Param #"amp_slide_curve" 0)
                              (Param #"attack" 0.0)
                              (Param #"decay" 0)
                              (Param #"sustain" -1)
                              (Param #"release" 0.0)
                              (Param #"attack_level" 1)
                              (Param #"decay_level" -1)
                              (Param #"sustain_level" 1)
                              (Param #"env_curve" 1)
                              (Param #"pan" 0)
                              (Param #"pan_slide" 0)
                              (Param #"pan_slide_shape" 1)
                              (Param #"pan_slide_curve" 0)
                              (Param #"lpf" -1)
                              (Param #"lpf_slide" 0)
                              (Param #"lpf_slide_shape" 1)
                              (Param #"lpf_slide_curve" 0)
                              (Param #"hpf" -1)
                              (Param #"hpf_slide" 0)
                              (Param #"hpf_slide_shape" 1)
                              (Param #"hpf_slide_curve" 0)
                              (Param #"rate" 1)
                              (Param #"out_bus" 12))))
  (check-equal? (resolve-specific-sampler
                 (sample 'ambi_choir)
                 (list 0 0 2 0))
                (Sample #"sonic-pi-stereo_player"
                        (string->bytes/utf-8
                         (path->string
                          (build-path (root-dir)
                                      "samples"
                                      "ambi_choir.wav")))
                        (list (Param #"buf" 0)
                              (Param #"amp" 1)
                              (Param #"amp_slide" 0)
                              (Param #"amp_slide_shape" 1)
                              (Param #"amp_slide_curve" 0)
                              (Param #"attack" 0.0)
                              (Param #"decay" 0)
                              (Param #"sustain" -1)
                              (Param #"release" 0.0)
                              (Param #"attack_level" 1)
                              (Param #"decay_level" -1)
                              (Param #"sustain_level" 1)
                              (Param #"env_curve" 1)
                              (Param #"pan" 0)
                              (Param #"pan_slide" 0)
                              (Param #"pan_slide_shape" 1)
                              (Param #"pan_slide_curve" 0)
                              (Param #"lpf" -1)
                              (Param #"lpf_slide" 0)
                              (Param #"lpf_slide_shape" 1)
                              (Param #"lpf_slide_curve" 0)
                              (Param #"hpf" -1)
                              (Param #"hpf_slide" 0)
                              (Param #"hpf_slide_shape" 1)
                              (Param #"hpf_slide_curve" 0)
                              (Param #"rate" 1)
                              (Param #"out_bus" 12)))))