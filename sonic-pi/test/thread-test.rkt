#lang s-exp sonic-pi/lsonic

;; this is as close to the 'acid walk' from sonic-pi.net
;; as i can get
(thread_s
 (block
  (psleep 2)
  (loop/infinite
   (block
    (loop 28
          (block
           (sample 'drum_bass_hard "amp" 0.8)
           (psleep 0.25)
           (note 'fm "e2" "release" 0.2)
           (sample 'elec_cymbal "rate" 12 "amp" 0.6)
           (psleep 0.25)))
    (psleep 4)))))

(loop/infinite
 (block
  (fx 'reverb
      (block
       (fx 'slicer
           (block
            (thread_s
             (block
              (loop/infinite
               (block
                (sample 'ambi_lunar_land
                        "sustain" 0
                        "release" 8
                        "amp" 2)
                (psleep 8)))))
            (loop 64
                  (block
                   (control
                    (choose
                     (chord 'tb303 "e3" "minor"))
                    "release" (rrand 0.05 0.3)
                    "cutoff" (rrand 50 90)
                    "amp" 0.5)
                   (psleep 0.125)))
            (loop 32
                  (block
                   (psleep 0.125)
                   (control
                    (choose
                     (chord 'prophet "a3" "minor7"))
                    "release" (rrand 0.1 0.2)
                    "cutoff" (rrand 40 130)
                    "amp" 0.7)))
            (loop 32
                  (block
                   (control
                    (choose
                     (chord 'prophet "a3" "minor7"))
                    "release" (rrand 0 0.6)
                    "cutoff" (rrand 110 130)
                    "amp" 0.4)
                   (psleep 0.125)))
            (fx 'echo
                (block
                 (loop 16
                       (block
                        (control
                         (choose
                          (chord
                           'prophet
                           (choose "e2" "e3" "e4")
                           "minor7"))
                         "release" 0.05
                         "cutoff" (rrand 50 129)
                         "amp" 0.5)
                        (psleep 0.125))))
                "phase" 0.25
                "decay" 8))
           "phase" 0.125))
      "mix" 0.2)))