#lang s-exp sonic-pi/lsonic

;; example using fx, samples, notes, and sleeps
(sample 'bass_drop_c "amp" 4 "release" 3)
(psleep 3)
(sample 'loop_breakbeat "amp" 3 "rate" 0.75)
(psleep 3)
(sample 'loop_breakbeat "amp" 3 "rate" 0.75)