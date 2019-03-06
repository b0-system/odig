[![Build Status](https://travis-ci.org/Chris00/ocaml-benchmark.svg?branch=master)](https://travis-ci.org/Chris00/ocaml-benchmark)
[![Build status](https://ci.appveyor.com/api/projects/status/jeyp56227sniv3vo?svg=true)](https://ci.appveyor.com/project/Chris00/ocaml-benchmark)

Benchmark — measure/compare run-time of OCaml functions
=======================================================

Benchmark provides functions to measure and compare the run-time of
functions.  It is inspired by the Perl module of the same name.


Installation
------------

The easier way to install it is by using opam:

    opam install benchmark

If you use the development version of this project, install [Dune][]
and issue

    make
    make install

[Dune]: https://github.com/ocaml/dune


Documentation
-------------

See the [interface of `Benchmark`](src/benchmark.mli).  It can also be
read in [HTML](https://chris00.github.io/ocaml-benchmark/doc/).




Copyright 2004-present, Christophe Troestler  
Copyright 2002-2003, Doug Bagley


