# Sonic Pi

Imitation is the sincerest form of flattery. I'm absolutely in love with
Sonic Pi's ease of use and great sound, and I'm duplicating parts of its
functionality... even down to the name.

This code is most easily installed using racket's package manager, `raco`:

```
raco pkg install sonic-pi
```

Let me make it absolutely clear, just in case: this package is NOT a
version of Sonic Pi; it's a bunch of code that uses scsynth in just the
same way that sonic pi does.

To see what it can currently do, try installing the package and then
running the file(s) in the `examples` subdirectory.


### Changelog

#### 2018-03-12

* Note, sample, and fx names are now symbols.
* Threads are actually threads instead of pretending to be.
* ```uscore->score``` no longer exists
* Fx and synth now know their specific defaults, rather than a single default list
* Lsonic can now detect when all sounds are finished playing and shutdown on its own
* The tool no longer sends messages via ```thread-send```; it logs messages and leaves it up to the main thread to read the logger.
* Fx now takes the block before the params
* synth has been renamed to note
* Lsonic now provides extra functions like startup, shutdown, and play for library usage.
* Added an example using the lsonic library.
* SuperCollider no longer needs to be pre-installed on Windows.
* New synth definitions courtesy of Sonic Pi
* May no longer work on Mac (not sure).

#### 2019-07-19

* Added the compiled synthdefs (how did they get lost?)
* Realized I never commited some important things and now they're gone (kill me)

