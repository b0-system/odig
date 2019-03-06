[![Build Status](https://travis-ci.org/Chris00/ocaml-odepack.svg?branch=master)](https://travis-ci.org/Chris00/ocaml-odepack)

ODEPACK
=======

This is a binding to [ODEPACK](http://computation.llnl.gov/casc/odepack/), 
a library to solve Cauchy problems, that is ordinary differential
equations (ODE) of the form ∂ₜy(t) = f(t,y(t)) with initial conditions
y(t₀) = y₀.

Installation
------------

The easier way of installing this library is to use
[opam](http://opam.ocaml.org/):

    opam install odepack

Documentation
-------------

Please consult the [interface](src/odepack.mli) or the
[HTML version](http://chris00.github.io/ocaml-odepack/doc/odepack/Odepack/).
