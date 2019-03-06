[![Build Status](https://travis-ci.org/Chris00/lpd.svg?branch=master)](https://travis-ci.org/Chris00/lpd)
[![Build status](https://ci.appveyor.com/api/projects/status/3a921xwdqq68d048?svg=true)](https://ci.appveyor.com/project/Chris00/lpd)

LPD
===

`Lpd` is a Line Printer Daemon compliant with RFC 1179 written
entirely in OCaml. It allows to define your own actions for LPD
events.  An example of a spooler that prints jobs on win32 machines
(through [GSPRINT](http://www.cs.wisc.edu/%7Eghost/gsview/gsprint.htm)) is
provided.

For a complete description of the functions, see the interface
[Lpd](lpd.mli) (also available
[in HTML](http://lpd.forge.ocamlcore.org/doc/index.html)).

A small [Socket](socket.mli) module is included that defines
buffered fonctions on sockets that work even on platforms where
`in_channel_of_descr` does not work.  Some examples are also
included in these sources.


Install
-------

The easier way to install this library is by using
[opam](http://opam.ocaml.org/):

    opam install lpd

If you would like to compile the development version, install
[Dune](https://github.com/ocaml/dune).  A `Makefile` is provided for
the developers convenience.

