2036
((3) 0 () 6 ((q lib "sonic-pi/lsonic.rkt") (q lib "sonic-pi/scsynth/scsynth-abstraction.rkt") (q lib "sonic-pi/data-structures/fx.rkt") (q lib "sonic-pi/data-structures/note.rkt") (q lib "sonic-pi/data-structures/sample.rkt") (q lib "sonic-pi/data-structures/loop.rkt")) () (h ! (equal) ((c def c (c (? . 3) q control-note)) q (999 . 4)) ((c def c (c (? . 0) q sample)) q (2699 . 4)) ((c def c (c (? . 1) q play-synth)) q (213 . 6)) ((c def c (c (? . 4) q control-sample)) q (1305 . 4)) ((c def c (c (? . 2) q set-block)) q (1922 . 4)) ((c def c (c (? . 0) q choose-list)) q (3550 . 3)) ((c def c (c (? . 0) q control)) q (3335 . 4)) ((c def c (c (? . 1) q startup)) q (0 . 2)) ((c def c (c (? . 0) q loop/infinite)) q (3254 . 3)) ((c def c (c (? . 1) q shutdown-scsynth)) q (173 . 2)) ((c def c (c (? . 2) q fx)) q (1495 . 5)) ((c def c (c (? . 3) q note?)) q (1117 . 3)) ((c def c (c (? . 0) q block)) q (2830 . 3)) ((c def c (c (? . 2) q set-fx-busses)) q (1802 . 5)) ((c def c (c (? . 0) q rrand)) q (3628 . 4)) ((c def c (c (? . 4) q sample?)) q (1432 . 3)) ((c def c (c (? . 3) q note)) q (678 . 5)) ((c def c (c (? . 0) q choose)) q (3490 . 3)) ((c def c (c (? . 1) q end-job)) q (102 . 3)) ((c def c (c (? . 3) q score?)) q (622 . 3)) ((c def c (c (? . 2) q fx?)) q (1751 . 3)) ((c def c (c (? . 2) q control-fx)) q (1645 . 4)) ((c def c (c (? . 0) q thread_s)) q (3074 . 3)) ((c def c (c (? . 5) q loop)) q (2014 . 4)) ((c def c (c (? . 3) q chord)) q (844 . 5)) ((c def c (c (? . 0) q loop)) q (3154 . 4)) ((c def c (c (? . 0) q rrand_i)) q (3703 . 4)) ((c def c (c (? . 1) q wait-for-nodes)) q (544 . 3)) ((c def c (c (? . 0) q note)) q (2298 . 5)) ((c def c (c (? . 4) q sample)) q (1174 . 4)) ((c def c (c (? . 0) q psleep)) q (2634 . 3)) ((c def c (c (? . 5) q live_loop)) q (2191 . 4)) ((c def c (c (? . 0) q fx)) q (2922 . 5)) ((c def c (c (? . 1) q load-fx)) q (380 . 6)) ((c def c (c (? . 5) q loop/infinite)) q (2112 . 3)) ((c def c (c (? . 0) q chord)) q (2479 . 5)) ((c def c (c (? . 1) q start-job)) q (34 . 3))))
procedure
(startup) -> context?
procedure
(start-job ctxt) -> job-context?
  ctxt : context?
procedure
(end-job job-ctxt) -> void?
  job-ctxt : job-context?
procedure
(shutdown-scsynth) -> void?
procedure
(play-synth job-ctxt name time param ...) -> void?
  job-ctxt : job-context?
  name : string?
  time : inexact-real?
  param : Param?
procedure
(load-fx job-ctxt name time param ...) -> void?
  job-ctxt : job-context?
  name : string?
  time : inexact-real?
  param : Param?
procedure
(wait-for-nodes job-ctxt) -> void?
  job-ctxt : job-context?
procedure
(score? scr) -> boolean?
  scr : any/c
procedure
(note synth-name pitch param-part ...) -> note?
  synth-name : symbol?
  pitch : (or string? real?)
  param-part : (or string? real?)
procedure
(chord synth-name pitch interval) -> (listof note?)
  synth-name : string?
  pitch : (or string? real?)
  interval : string?
procedure
(control-note note param-part ...) -> note?
  note : note?
  param-part : (or string? real?)
procedure
(note? note) -> boolean?
  note : any/c
procedure
(sample name param-part ...) -> sample?
  name : (or symbol? string?)
  param-part : (or string? real?)
procedure
(control-sample sample param-part ...) -> sample?
  sample : samle?
  param-part : (or string? real?)
procedure
(sample? sample) -> boolean?
  sample : any/c
procedure
(fx name block param-part ...) -> fx?
  name : symbol?
  block : (-> (list score?))
  param-part : (or string? real?)
procedure
(control-fx f param-part ...) -> fx?
  f : fx?
  param-part : (or string? real?)
procedure
(fx? fx) -> boolean?
  fx : any/c
procedure
(set-fx-busses fx in-bus out-bus) -> fx?
  fx : fx?
  in-bus : integer?
  out-bus : integer?
procedure
(set-block fx block) -> fx?
  fx : fx?
  block : (-> (list score?))
procedure
(loop reps block) -> loop?
  reps : integer?
  block : (-> (list score?))
procedure
(loop/infinite block) -> loop?
  block : (-> (list score?))
procedure
(live_loop name block) -> live_loop?
  name : string?
  block : (-> (list score?))
procedure
(note synth-name pitch param-part ...) -> note?
  synth-name : (or symbol? string?)
  pitch : (or string? real?)
  param-part : (or string? real?)
procedure
(chord synth-name pitch interval) -> (listof note?)
  synth-name : string?
  pitch : (or string? real?)
  interval : string?
procedure
(psleep time) -> psleep?
  time : inexact-real?
procedure
(sample name param-part ...) -> sample?
  name : (or symbol? string?)
  param-part : (or string? real?)
procedure
(block sounds) -> (-> (listof score?))
  sounds : (-> (listof score?))
procedure
(fx name block param-part ...) -> fx?
  name : string?
  block : (-> (listof score?))
  param-part : (or string? real?)
procedure
(thread_s block) -> thread_s?
  block : (-> (listof score?))
procedure
(loop reps block) -> loop?
  reps : integer?
  block : (-> (listof score?))
procedure
(loop/infinite block) -> loop?
  block : (-> (listof score?))
procedure
(control synth param-part ...) -> (or note? sample? fx?)
  synth : (or note? sample? fx?)
  param-part : (or string? real?)
procedure
(choose elem ...) -> any/c
  elem : any/c
procedure
(choose-list elements) -> any/c
  elements : (listof any/c)
procedure
(rrand min max) -> real?
  min : real?
  max : real?
procedure
(rrand_i min max) -> integer?
  min : integer?
  max : integer?
procedure
(live_loop name block) -> live_loop?
  name : string?
  block : (-> (listof score?))
