nlp — Natural Language Processing tools for OCaml
-------------------------------------------------------------------------------
v0.0.1

nlp provides functions to make it easy to perform simple natural language processing
tasks in Ocaml

nlp is distributed under the ISC license.

Homepage: https://github.com/dave-tucker/nlp  

## Installation

nlp can be installed with `opam`:

    opam install nlp

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Documentation

The documentation and API reference is generated from the source
interfaces. It can be consulted [online][doc] or via `odig doc
nlp`.

[doc]: https://dtucker.co.uk/nlp/doc

## Sample programs

If you installed nlp with `opam` sample programs are located in
the directory `opam var nlp:doc`.

In the distribution sample programs and tests are located in the
[`test`](test) directory of the distribution. They can be built and run
with:

    topkg build --tests true && topkg test 
