Rope
====

Ropes are a scalable string implementation: they are designed for
efficient operation that involve the string as a whole such as
concatenation and substring. This library implements ropes for OCaml
(it is rich enough to replace strings).

Version 0.6.1

Installation
------------

The easier way to install this library is to use [opam][]:

    opam install rope

To compile the development version, you will need to install [jbuilder][]
and then issue

    jbuilder build @install

Install with:

    jbuilder install

To run the tests, install the module [Benchmark][] and do

    jbuilder runtest


[opam]: http://opam.ocaml.org/
[jbuilder]: https://github.com/janestreet/jbuilder
[benchmark]: https://github.com/Chris00/ocaml-benchmark

Documentation
-------------

You can read the interface `rope.mli` [in this repository](src/rope.mli) or
[as HTML](http://chris00.github.io/ocaml-rope/doc/rope/Rope/).
