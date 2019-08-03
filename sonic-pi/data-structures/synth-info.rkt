#lang racket/base

(require racket/file
         racket/list
         tjson)

(provide synth-info
         param-info
         get-synth-info
         get-synth-params)

;; TODO: put arguments in their own JSON to normalize DB

;; a synth-info object provides information about a synth (shocker)
;; consists of
;;    - name (synth name like 'Pretty Bell')
;;    - key (identifier like 'pretty_bell')
;;    - description
;;    - params (parameter definitions)
(define-struct synth-info (name key description params) #:transparent)

;; a param-info object provides information about a synth's parameters
;; consists of
;;    - name (parameter name like 'amp')
;;    - description
;;    - required (boolean)
;;    - default
;;    - constraints
(define-struct param-info (name description required default constraints) #:transparent)

;; gets the synth-info struct for the given synth
(define (get-synth-info s)
  (hash-ref synths s))

;; gets the list of arguments for the given synth
(define (get-synth-params s)
  (synth-info-params (hash-ref synths s)))

;; convert a param-info json object to a param-info struct
(define (json-param->param p)
  (make-param-info (jsattribute p 'name)
                   (jsattribute p 'description)
                   (jsattribute p 'required)
                   (jsattribute p 'default)
                   (jsattribute p 'constraints)))

;; convert a list of json params to a list of param-info
(define (json-params->param param-list)
  (map json-param->param param-list))

;; convert a synth-info json object to a synth-info struct
(define (json-synth->synth s)
  (make-synth-info (jsattribute s 'name)
              (string->symbol (jsattribute s 'key))
              (jsattribute s 'description)
              (json-params->param (jsattribute s 'arguments))))

;; convert a list of json synths to a list of synth-info
(define (json-synths->synth synth-list)
  (map json-synth->synth synth-list))

;; get the entire list of synths
(define (get-all-synths)
  (json-synths->synth
   (jsattribute
   (read-json (open-input-file "synths.json"))
   'synths)))

;; convert a list to a hash table where the key is
;; the key value of the structure and the value is
;; the structure itself
(define (synth-list->hash l)
  (make-hash
   (map
    cons
    (map (λ (e) (synth-info-key e)) l)
    l)))

;; all the synths as a hash table where the key
;; is the synth identifier
(define synths
  (synth-list->hash (get-all-synths)))

(module+ test
  (require rackunit)

  ;; TODO: write tests
  )