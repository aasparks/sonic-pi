#lang s-exp sonic-pi/lsonic

(fx 'reverb
    (block
     (loop/infinite
      (block
       (note (choose 'bnoise 'cnoise 'gnoise)
              40 ;noise is pitchless, so this has no effect
              "amp" (rrand 0.5 1.5)
              "attack" (rrand 0 4)
              "sustain" (rrand 0 2)
              "release" (rrand 1 3)
              "pan" (rrand -1 1)
              "pan_slide" (rrand 0 1))
       (psleep (rrand 2 3)))))
    "mix" 0.5)