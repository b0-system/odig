# Gen

Iterators for OCaml, both restartable and consumable. The implementation
keeps a good balance between simplicity and performance.

The library is extensively tested using `qtest`. If you find a bug,
please report!

The documentation can be found [here](http://cedeela.fr/~simon/software/gen);
the main module is [Gen](http://cedeela.fr/~simon/software/gen/Gen.html)
and should suffice for 95% of use cases.

## Install

    $ opam install gen

or, manually, by building the library and running `make install`. Opam is
recommended, for it keeps the library up-to-date.

## Use

You can either build and install the library (see "Build"), or just copy
files to your own project. The last solution has the benefits that you
don't have additional dependencies nor build complications (and it may enable
more inlining).

If you have comments, requests, or bugfixes, please share them! :-)

## Build

There are no dependencies. This should work with OCaml>=3.12.

    $ make

To build and run tests (requires `oUnit` and `qtest`):

    $ opam install oUnit qtest
    $ ./configure --enable-tests
    $ make test

## License

This code is free, under the BSD license.
