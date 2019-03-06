[![Build Status](https://travis-ci.org/Chris00/ocaml-interval.svg?branch=master)](https://travis-ci.org/Chris00/ocaml-interval)
[![Build status](https://ci.appveyor.com/api/projects/status/s144ehk5tls6imiu?svg=true)](https://ci.appveyor.com/project/Chris00/ocaml-interval)

Interval
========

This is an [interval arithmetic][] library for OCaml.

This library uses assembly code to compute all operations with proper
rounding, and currently **ONLY** works on Intel processors.
The package has been developed for Linux systems but
works on Windows when compiled with GCC.

To build the library, install jbuilder/[dune][] and type `jbuilder
build` in the main directory.  You can compile the examples with
`jbuilder build @examples`; the programs will be in
`_build/default/EXAMPLES/`.  To execute the tests, issue `jbuilder
runtest`).

To documentation is build using `jbuilder build @doc` and will be in
`_build/default/_doc/` in HTML format.  You can also consult the
interfaces of [Interval](src/interval.mli) and [Fpu](src/fpu.mli) and
[online](https://chris00.github.io/ocaml-interval/doc/interval/).
It is extremely wise to read the whole documentation, even if you
intend to only use the interval module.

Tests are available in the `TESTS/` directory.  They are mainly for
debugging purpose and quite complicated.  You may run them (`make
tests`) to check that everything is working properly for your machine.
The `test` program runs also a speed test for your particular
architecture.

Examples are available in the `EXAMPLES/` directory.  There is a
`B_AND_B` sub-directory with an example of a branch-and-bound
algorithm that uses interval arithmetics for function optimization
(the example is for the Griewank function, but you can substitute any
function you like).


All bug reports should be sent to  
jean-marc.alliot@irit.fr  
gottelan@recherche.enac.fr

Happy interval programming...

Remark: This library was originally published on Jean-Marc Alliot
[website](http://www.alliot.fr/fbbdet.html.fr) but was moved to Github
with the permission of the authors.


[interval arithmetic]: https://en.wikipedia.org/wiki/Interval_arithmetic
[dune]: https://github.com/ocaml/dune
