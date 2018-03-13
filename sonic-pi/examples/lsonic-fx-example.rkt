#lang s-exp sonic-pi/lsonic

(sample 'loop_breakbeat "rate" 0.75)
(psleep 3)
(fx 'krush
    (block
      (sample 'loop_breakbeat "rate" 0.75)
      (psleep 3)))

(sample 'loop_breakbeat "rate" 0.75)
(psleep 3)

(loop 12
      (block
       (fx 'wobble
           (block
            (fx 'echo
                (block
                 (sample 'drum_heavy_kick)
                 (sample 'bass_hit_c "rate" 0.8 "amp" 0.4)
                 (psleep 1)))))))
