# OC4.5

This project aims to provide a pure OCaml implementation of C4.5
([Wikipedia](https://en.wikipedia.org/wiki/C4.5_algorithm)). This algorithm is
used to generate a decision tree from a dataset and a criteria set, and is
usually found in machine learning.

The algorithm description can be found in eg. "Efficient C4.5" by S. Ruggieri
in IEEE transactions on knowledge and data engineering, vol. 14, no. 2,
march/april 2002.

## Compiling

If you do not have [opam](https://opam.ocaml.org/), install it.

If you do not have [obuild](https://github.com/ocaml-obuild/obuild), install
it: `opam install obuild`.

Then, compile and install (locally to your user) the project with
```bash
    obuild configure
    obuild build
    obuild install
```

## Documentation

You can generate the project's documentation using `ocamldoc`.

If, for some reason, you do not want to generate the documentation, you can use
the precompiled, but **not necessarily up-to-date** online version
[here](https://tobast.fr/doc/OC4.5/).

## Related projects

This project was primarily made to be used with
[ORandForest](https://github.com/tobast/ORandForest). Check its `README` and
documentation for a more elaborate usage example and reference.
