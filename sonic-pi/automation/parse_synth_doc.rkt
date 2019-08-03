#lang racket 

(require json)

(define-struct synth (key description arguments))

(define (synth->json s)
  (hasheq 'key (synth-key s)
          'description (synth-description s)
          'arguments (synth-arguments s)))

;; parses an entire md file 
(define (parse-md file)
  (map parse-section
       (string-split (file->string file)
                     "## "
                     #:trim? false
                     #:repeat? true)))

;; parses one section of md file (aka one synth)
(define (parse-section str)
  (if (string-prefix? str "#")
      (void)
      (parse-synth str)))

(define (parse-synth str)
  (display str)
  (define parts (string-split str "# " #:trim? false))
  (display parts)
  (define key (string-trim (first parts) "Key:\n"))
  (define description (string-trim (second parts) "Doc:\n"))
  (define arguments
    (map (λ (opt)
           "")
         (string-split (third parts) "* ")))
  (display key)
  (display description)
  (synth->json (synth key description arguments)))

(parse-md (build-path "." "synths.md"))