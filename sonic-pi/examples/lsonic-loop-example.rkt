#lang s-exp sonic-pi/lsonic

(loop 4
      (block
       (sample 'bd_tek)
       (psleep 0.25)))

(loop 8
      (block
       (sample 'bd_ada)
       (sleep 0.25)
       (note 'beep 60)
       (sleep 0.25)))

(loop/infinite
 (block
  (sample 'elec_plip)
  (psleep 0.25)))