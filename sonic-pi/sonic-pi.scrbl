#lang scribble/manual

@title{Sonic Pi: WORK IN PROGRESS}


@author[(author+email "John Clements" "clements@racket-lang.org")
        (author+email "Austin Sparks" "aasparks93@gmail.com")]

@(require (for-label racket))

This package is a collection of functions and a very primitive language
level that follows the lead of Sonic Pi. Specifically, (like Sonic Pi)
it uses scsynth as its sound generation engine, and creates the same
network of units that Sonic Pi does.

This is very much a work in progress. I'm releasing it as a project
so that others can try it out and steal parts of it.

Want to try it out? Install the package, then open one of the examples
in @filepath{examples/}
in DrRacket and click Run.

Tell me what happens!

@section{Prerequisites}
For Linux users, SuperCollider and jackd must be installed on the system. Due to issues with SuperCollider,
this will not work at all on a virtual machine.

@section{An Imperative Interface}

@subsection{SuperCollider Abstraction}
@defmodule[sonic-pi/scsynth/scsynth-abstraction]{
 One thing that I don't like that much about Sonic Pi is its unabashedly
 imperative interface.

 However, underneath what I hope will be a nice clean language (lsonic),
 I'm also going to publish the lower-level imperative interface. For one
 thing, it's pretty obvious what it'll look like: it'll look like Sonic
 Pi. That means less design work. Here are some functions:

 @defproc[(startup) context?]{
  Starts an scsynth, returns a context that can be used to ... well, to
  create a job context.
 }

 @defproc[(start-job [ctxt context?]) job-context?]{
  Given a context, starts a job, and return a handle for that job. A job
  corresponds to a ``piece of music.'' 
 }

 @defproc[(end-job [job-ctxt job-context?]) void?]{
  Ends a job: fades out the job and cancels all scheduled notes associated
  with the job.
 }

  @defproc[(shutdown-scsynth) void?]{
  Terminates the SuperCollider (and jackd on Linux) process.
 }

 @defproc[(play-synth [job-ctxt job-context?] [name string?] [time inexact-real?] [param Param?] ...) void?]{
  Play @racket[note] or @racket[sample] with @racket[job-ctxt], at time @racket[time], specified
  in inexact milliseconds since the epoch. If the @racket[time] value is less than
  the current number of milliseconds since the epoch, the note will be played
  immediately. (Note that this means that you can always specify @racket[0.0] to
  play a note immediately.)
 }

 @defproc[(load-fx [job-ctxt job-context?] [name string?] [time inexact-real?] [param Param?] ...) void?]{
  Create an @racket[fx] node associated with @racket[job-ctxt], at time @racket[time], specified
  in inexact milliseconds since the epoch. 
 }

 @defproc[(wait-for-nodes [job-ctxt job-context?]) void?]{
   Blocks until all synth nodes associated with @racket[job-ctxt] have ended.
 }
 
}

@subsection{Data Structures}

@defmodule[sonic-pi/data-structures/common]{
  @defproc[(score? [scr any/c]) boolean?]{
  Returns true for any of the following:
    @racket[note],
    @racket[psleep],
    @racket[loop],
    @racket[sample],
    @racket[fx],
    @racket[live_loop],
    @racket[thread_s]
}
}

@defmodule[sonic-pi/data-structures/note]{

 @defproc[(note [synth-name symbol?] [pitch (or string? real?)] [param-part (or string? real?)] ...) note?]{
  Creates a note. In addition to the @racket[synth-name] and @racket[pitch], users may specify non-default values for one of many other parameters using and
  interleaved parameter-name / value style. For instance:

  @racketblock[(note 'saw 78 "attack" 0.5 "amp" 0.5)]

  The pitch may be specified as a MIDI note number, or in musical notation. Musical notation may include
  the note, accidental, or octave in that order :

  @racketblock[(note 'zawa 39)
               (note 'pretty_bell "A")
               (note 'pulse "C2")
               (note 'beep "af3")]

 }

 @defproc[(chord [synth-name string?] [pitch (or string? real?)] [interval string?]) (listof note?)]{
  creates a list of notes in the specified chord. For example:
  @racketblock[(chord 'saw "a" "minor")]

  Here is a list of all supported intervals:
  @racketblock['("major" "minor" "major7" "dom7" "minor7" "aug" "dim" "dim7")]
 }

 @defproc[(control-note [note note?] [param-part (or string? real?)] ...) note?]{
  Reassigns the optional paramaters to the specified paramaters, using the note's
  original values as the default.
 }

 @defproc[(note? [note any/c]) boolean?]{
  returns true for notes.
 }

}

@subsection{Sample}
@defmodule[sonic-pi/data-structures/sample]{

 @defproc[(sample [name (or symbol? string?)] [param-part (or string? real?)] ...) sample?]{
  Create a sample with a given @racket[name] as either an absolute file path or a symbol naming one of
  the samples provided in @filepath{sonic-pi/samples}. The samples are taken directly from
  the original Sonic Pi repo. The full list can be found at @filepath{sonic-pi/samples/README.md}.

  @racketblock[(sample 'loop_garzul "amp" 5)
               (sample "/home/users/jane/documents/samples/screaming_goat.wav")
               (sample "C:\\Users\\Bob\\Documents\\Samples\\screaming_goat.wav")]
 }

 @defproc[(control-sample [sample samle?] [param-part (or string? real?)] ...) sample?]{
  Reassigns the optional parameters to the specified ones, using the sample's original
  values as the defaults.
 }

 @defproc[(sample? [sample any/c]) boolean?]{
  returns true for samples.
 }

}

@subsection{Fx}
@defmodule[sonic-pi/data-structures/fx]{

 @defproc[(fx [name symbol?] [block (-> (list score?))] [param-part (or string? real?)] ...) fx?]{
  Creates a sound effect to be applied to other sounds. @racket[name] may be
  one of the predefined sound effects provided by the original Sonic Pi. Unlike with notes,
  all paramaters provided are passed to SuperCollider, not just the defaults. The last param-part is expected to be
  a @racket[block], containing a set of sounds to be played with this sound effect. For instance:

  @racketblock[(fx 'bitcrusher
                   (block (synth "beep" 60))
                   "bits" 4)]
 }

 @defproc[(control-fx [f fx?] [param-part (or string? real?)] ...) fx?]{
  Reassigns a sound effect with new parameters. For instance:
  @racketblock[(define my-fx (fx 'bitcrusher
                                 (block (synth "beep" 60))
                                 "bits" 8))
               (control-fx my-fx "bits" 16)]
 }

 @defproc[(fx? [fx any/c]) boolean?]{
  returns true for fx's.
 }

 @defproc[(set-fx-busses [fx fx?] [in-bus integer?] [out-bus integer?]) fx?]{
  Sets the @racket[in-bus] and @racket[out-bus] parameters for a sound effect.
 }

 @defproc[(set-block [fx fx?] [block (-> (list score?))]) fx?]{
  Sets the block of music to be played for a sound effect.
 }
}

@subsection{Loops}
@defmodule[sonic-pi/data-structures/loop]{
 @defproc[(loop [reps integer?] [block (-> (list score?))]) loop?]{
  Creates a loop to played @racket[reps] times}

 @defproc[(loop/infinite [block (-> (list score?))]) loop?] {
  Creates a loop with -1 @racket[reps], intended to run infinitely}

 @defproc[(live_loop [name string?] [block (-> (list score?))]) live_loop?]{
  Creates a live_loop structure to play continuous notes. Live loops must
  be named uniquely. 
 }
}

@section{A Live Coding Environment}
This package provides a primitive language similar to Sonic Pi
with a simple live coding environment within DrRacket.
The provided @racket[play] and @racket[stop] buttons will
update the playing music in real time and stop the music and
shutdown SuperCollider, respectively.

@subsection{Sounds}
@defmodulelang[sonic-pi/lsonic]{

 @defproc[(note [synth-name (or symbol? string?)] [pitch (or string? real?)] [param-part (or string? real?)] ...) note?]{
  Plays a note of the given @racket[pitch] using the given @racket[synth-name]. This is unlike
  Sonic Pi, which does not require you to input a synth each time.
  Users may specify non-default values for one of many other parameters using and
  interleaved parameter-name / value style. For instance:

  @racketblock[(note 'saw 78 "attack" 0.5 "amp" 0.5)]

  The pitch may be specified as a MIDI note number, or in musical notation. Musical notation may include
  the note, accidental, and octave :

  @racketblock[(note 'zawa 39)
               (note 'pretty_bell "A")
               (note 'pulse "C2")
               (note 'beep "af3")]

 }

 @defproc[(chord [synth-name string?] [pitch (or string? real?)] [interval string?]) (listof note?)]{
  Play a chord. For example:
  @racketblock[(chord 'saw "a" "minor")]

  Here is a list of all supported @racket[interval]s:
  @racketblock['("major" "minor" "major7" "dom7" "minor7" "aug" "dim" "dim7")]
 }

 @defproc[(psleep [time inexact-real?]) psleep?]{
  Sleep for @racket[time] seconds before playing more.
  The following two beeps will happen at the same time
  @racketblock[(note 'beep 60)
               (note 'beep 62)]
  Whereas the next two will happen one after the other, with a 1 second gap
  @racketblock[(note 'beep 60)
               (psleep 1)
               (note 'beep 62)]
 }

 @defproc[(sample [name (or symbol? string?)] [param-part (or string? real?)] ...) sample?]{
  Play a sample. These are the same samples provided by Sonic Pi.
  To sample a local file, set the @racket[name] to the full file path of the sample
  as a @racket[string]. To use a built in sample, provide the @racket[name] as a
  @racket[symbol]. For instance:

  @racketblock[(sample 'bd_tek)
               (sample "/home/users/jane/documents/samples/screaming_goat.wav")]
 }

 @defproc[(block [sounds (-> (listof score?))]) (-> (listof score?))]{
  Creates a @racket[block] of sound(s) similar to the @elem["do ... end" #:style "hspace"] blocks of Sonic Pi.
  This is accomplished by wrapping the set of events in a closure. Thus
  @racketblock[(block (note 'pretty_bell 60))]
  is equivalent to
  @racketblock[(λ () (list (note 'pretty_bell 60)))]
  @racket[block]s are used when applying fx, looping, or threading. For example:
  @racketblock[(live_loop "foo"
                          (block (sample 'bd_boom)
                                 (psleep 2)))]
 }

 @defproc[(fx [name string?] [block (-> (listof score?))] [param-part (or string? real?)] ...) fx?]{
  Play @racket[block] of sounds using the specified sound effect.
  The effects provided are the same as Sonic Pi. Each fx has a different set of
  parameters for it, so the defaults are determined by the synth definition. All params given will be passed
  and any that don't apply to the fx will be ignored.
  For example:
  @racketblock[(fx 'reverb
                   (block (note 'saw "bf"))
                   "room" 2)]
 }

 @defproc[(thread_s [block (-> (listof score?))]) thread_s?]{
  Plays the @racket[block] in a separate thread from the rest of the music, allowing
  for simultaneous music scores.
  @racketblock[(thread_s
                (block
                 (fx 'reverb
                     (block
                      (loop/infinite
                       (block
                        (sample 'ambi_choir
                                "rate" (choose 0.5
                                               (/ 1.0 3)
                                               (/ 3.0 5))
                                "pan" (rrand -1 1))
                        (psleep 0.5)))))))

               (fx 'wobble
                   (block
                    (fx 'echo
                        (block
                         (loop/infinite
                          (block
                           (sample 'drum_heavy_kick)
                           (sample 'bass_hit_c "rate" 0.8 "amp" 0.4)
                           (psleep 1))))
                        "mix" 0.6))
                   "phase" 2)]
 }

 @defproc[(loop [reps integer?] [block (-> (listof score?))]) loop?]{
  Loop the @racket[block reps] times. 
 }

 @defproc[(loop/infinite [block (-> (listof score?))]) loop?]{
  Loop a @racket[block] forever. Loops are blocking, so put them in a
  @racket[thread_s] to play something else at the same time.
 }

 @defproc[(control [synth (or note? sample? fx?)] [param-part (or string? real?)] ...) (or note? sample? fx?)]{
  Set the arguments to a @racket[synth] to new params and play the sound. For example, the following
  code will choose a note from a chord in A Minor, set the arguments, and play the note.
  @racketblock[(control (choose (chord 'pretty_bell "a" "minor"))
                        "release" 0.5
                        "amp" 0.8)]
 }

 @defproc[(choose [elem any/c] ...) any/c]{
  Randomly pick one element from the ones provided. If any element passed to it is a list, it
  will behave like @racket[choose-list].
  For example:
  @racketblock[(choose (sample 'bd_haus)
                       (sample 'bd_boom)
                       (sample 'elec_plip))]}

 @defproc[(choose-list [elements (listof any/c)]) any/c]{
  Same as @racket[choose] but for elements specifically in a list, though @racket[choose] will
  accept lists as well.
  @racketblock[(choose-list (chord "beep" "a" "minor"))]}
 

 @defproc[(rrand [min real?] [max real?]) real?]{
  Generates a random number between @racket[min] and @racket[max].}

 @defproc[(rrand_i [min integer?] [max integer?]) integer?]{
  Generates a random integer from @racket[min] to @racket[max], inclusive.}
}

@subsection{Live Coding}
Live coding is implemented in a very simple fashion for use with DrRacket.
There are two buttons provided with this package: @racket[stop] and @racket[play].

When using the live coding environment, first press the DrRacket run button. This will
start up SuperCollider and begin playing your music. If your music score is finite
(no infinite loops), SuperCollider will be shut down when the music is done playing.

If there is an infinite loop, that is not a live loop, you must press the @racket[stop]
button to stop the music and close SuperCollider.

If there is a live loop, you can make changes to the source and press the @racket[play] button
to update the music on the next iteration. You must press the DrRacket run button first. It
may take two iterations of the loop to update. When you wish to end the music that is playing,
press the @racket[stop] button. This will also shut down SuperCollider,
so you will need to re-run the program to start it back up.

@defproc[(live_loop [name string?] [block (-> (listof score?))]) live_loop?]{
 Play a @racket[block] of music in an infinite loop with the ability to update.
 Live loops are executed in their own threads so they must have unique names and they are non-blocking.
 The following example comes from the Sonic Pi tutorial:
 
 @racketblock[
 (live_loop "boom"
            (block
             (fx 'reverb 
                 (block (sample 'bd_boom
                                "amp" 10
                                "rate" 1)
                        (sample 'elec_blip
                                "amp" 10
                                "rate" 1)
                        (psleep 8))
                 "room" 1)))
 (live_loop "guit"
            (block
             (fx 'echo
                 (block (sample 'guit_em9 "rate" 0.5)
                        (sample 'guit_e_fifths  "rate" 0.5)
                        (psleep 8))
                 "mix" 0.3 "phase" 0.25)))]
 After running, comment out a sample from each loop, and press the play button to hear it change.
 It may take a few loops for the changes to take effect.
}

@subsection{Examples}
Shown below are the examples from the @filepath{examples} folder included with this package.
Most examples come from Sonic Pi's examples in the tutorial and on the home page. Be sure
to include the lang line as
@racketblock{#lang s-exp sonic-pi/lsonic}

@subsubsection{synth and sleep}

This block of code plays a simple set of notes in succession. The first two synths are
scheduled to start at the same time. The rest will start 0.5s later with each call to @racket[psleep].
@racketblock[(note 'beep 60  "release" 0.5)
             (note 'prophet 72 "attack" 4 "release" 2 "amp" 0.5)
             (psleep 0.5)
             (note 'prophet 74 "attack" 4 "release" 2 "amp" 0.5)
             (psleep 0.5)
             (note 'prophet 79 "attack" 4 "release" 2 "amp" 0.5)
             (psleep 0.5)
             (note 'prophet 77 "attack" 4 "release" 2 "amp" 0.5)
             (psleep 0.5)
             (note 'prophet 73 "attack" 4 "release" 2 "amp" 0.5)
             (psleep 0.5)
             (note 'prophet 69 "attack" 4 "release" 2 "amp" 0.5)
             (psleep 0.5)
             (note 'prophet 80 "attack" 4 "release" 2 "amp" 0.5)]

@subsubsection{sample and fx}
This example plays a succession of synths and samples with various sound effects
applied to them.
@racketblock[(synth 'pretty_bell 60)
             (psleep 0.5)
             (sample 'elec_plip)
             (psleep 0.5)
             (synth 'pretty_bell 50)
             (psleep 2)

             (fx 'reverb
                 (block
                  (note 'pretty_bell 60)
                  (psleep 0.5)
                  (sample 'elec_plip)
                  (psleep 0.5)
                  (note 'pretty_bell 50)))

             (psleep 2)

             ;; nested fx works too!
             (fx 'echo
                 (block
                  (fx 'reverb
                      (block
                       (note 'pretty_bell 60)
                       (psleep 0.5)
                       (sample 'elec_plip)
                       (psleep 0.5)
                       (note 'pretty_bell 50)))))

             (psleep 4)
             (note 'pretty_bell 60)
             (psleep 0.5)
             (sample 'elec_plip)
             (psleep 0.5)
             (note 'pretty_bell 50)]

@subsubsection{loops and threads}
Loops are blocking so they must be put in a thread to be played with other loops.
@racketblock[(thread_s
              (block
               (loop/infinite
                     (block
                      (fx 'reverb
                          (block
                           (sample 'ambi_choir
                                   "pan" (rrand -1 1)
                                   "rate" (choose 0.5 (/ 1.0 3) (/ 3.0 5)))
                           (psleep 0.5)))))))
             (loop/infinite
                   (block
                    (fx 'wobble 
                        (block
                         (fx 'echo
                             (block
                              (sample 'drum_heavy_kick)
                              (sample 'bass_hit_c "rate" 0.8 "amp" 0.4)
                              (psleep 1))
                             "mix" 0.6))
                        "phase" 2)))]

@subsubsection{randomness}
Randomness can be used in a number of ways to create all sorts of cool sounds. It is seeded at
start up so consecutive runs should sound the same. The following example simulates
ocean sounds.
@racketblock[(fx 'reverb
                 (block
                  (live_loop "ocean"
                             (block
                              (note (choose 'bnoise 'cnoise 'gnoise)
                                     40
                                     "amp" (rrand 0.5 1.5)
                                     "attack" (rrand 0 4)
                                     "sustain" (rrand 0 2)
                                     "release" (rrand 1 3)
                                     "pan" (rrand -1 1)
                                     "pan_slide" (rrand 0 1))
                              (psleep (rrand 2 3)))))
                 "mix" 0.5)]

@subsubsection{control}
Control allows you to set arguments to pre-defined synths.
@racketblock[(loop
              4
              (block
               (fx 'slicer 
                   (block
                    (fx 'reverb
                        (block
                         (control
                          (choose (chord 'dsaw
                                         (choose "b1" "b2" "e1" "e2" "b3" "e3")
                                         "minor"))
                          "release" 8
                          "note_slide" 4
                          "cutoff" 30
                          "cutoff_slide" 4
                          "detune" (rrand 0 0.2)
                          "pan" (rrand -1 0))
                         (control
                          (choose (chord 'dsaw
                                         (choose "b1" "b2" "e1" "e2" "b3" "e3")
                                         "minor"))
                          "release" 8
                          "note_slide" 4
                          "cutoff" (rrand 80 120)
                          "cutoff_slide" 4
                          "detune" (rrand 0 0.2)
                          "pan" (rrand 0 1))
                         (psleep 8))
                        "room" 0.5 "mix" 0.3))
                   "phase" 0.25)))]


@section{Bugs}
There are bound to be plenty of bugs, so report!

Here is a list of known bugs:
@itemize[
 @item{Loops may fall out of sync or skip an iteration due to timing delays}
 @item{If SuperCollider (or jackd on Linux) does not have realtime privileges, timing can get messed up easily.}
 @item{SuperCollider does not work in virtual environments. Sorry vm users!}
 ]


