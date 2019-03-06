LIBSVM-OCaml - LIBSVM Bindings for OCaml
========================================

---------------------------------------------------------------------------

LIBSVM-OCaml is an [OCaml](http://www.ocaml.org) library with bindings to the
[LIBSVM](http://www.csie.ntu.edu.tw/~cjlin/libsvm/) library, which is a library
for Support Vector Machines. Support Vector Machines are used to create
supervised learning models for classification and regression problems in
machine learning.

Installation
------------

From [OPAM](http://opam.ocaml.org)

    $ opam install libsvm

From Source

    $ make
    $ make install

Usage
-----

### Documentation

The API-documentation of this distribution can be built with `make doc`.
It can also be found [online](http://ogu.bitbucket.io/libsvm-ocaml/api/).

### Examples

This simple program solves the famous XOR-problem:

    :::ocaml
    open Lacaml.D
    open Libsvm

    let () =
      let x = Mat.of_array
        [|
          [| 0.; 0. |];
          [| 0.; 1. |];
          [| 1.; 0. |];
          [| 1.; 1. |];
        |]
      in
      let targets = Vec.of_array [| 0.; 1.; 1.; 0. |] in
      let problem = Svm.Problem.create ~x ~y:targets in
      let model = Svm.train ~kernel:`RBF problem in
      let y = Svm.predict model ~x in
      for i = 1 to 4 do
        Printf.printf "(%1.0f, %1.0f) -> %1.0f\n" x.{i,1} x.{i,2} y.{i}
      done

For more examples please refer to the `examples`- or `test`-directory of this
distribution.

Credits
-------

  * Dominik Brugger wrote the initial release (0.1) of this library.

Contact Information
-------------------

In case of bugs, feature requests and similar, please contact:

  * Oliver Gu <gu.oliver@yahoo.com>
