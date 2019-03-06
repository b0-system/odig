[![Build Status](https://travis-ci.org/Chris00/root1d.svg?branch=master)](https://travis-ci.org/Chris00/root1d)
[![Build status](https://ci.appveyor.com/api/projects/status/0y4lccfjpm8s5bgg?svg=true)](https://ci.appveyor.com/project/Chris00/root1d)

Root1D — Find roots of 1D functions
===================================

The module `Root1D` provides a collection of functions to seek roots
of functions `float → float`.


Installation
------------

The easier way of installing this package is by using [opam][]:

```shell
opam install root1d
```

To compile by hand, install [dune][] and do `dune build @install`.


[opam]: https://opam.ocaml.org/
[dune]: https://github.com/ocaml/dune

Documentation
-------------

See the [signature of `Root1D`](src/Root1D.mli).  It can also be
consulted rendered to [HTML](https://chris00.github.io/root1d/doc/).
