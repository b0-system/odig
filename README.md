odig — Mine installed OCaml packages
-------------------------------------------------------------------------------
%%VERSION%%

odig is a library and command line tool to mine installed OCaml
packages. It supports package lookups for distribution documentation,
metadata and generates cross-referenced API documentation.

odig is distributed under the ISC license.

Homepage: http://erratique.ch/software/odig  

## Installation

odig can be installed with `opam`:

    opam install odoc ocaml-manual odig

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Usage

    odig doc
    odig changes PKG
    odig readme PKG

## Documentation & tutorial

The documentation, tutorial and API reference is generated from the source
interfaces. It can be consulted [online][doc] or via `odig doc odig`.

[doc]: http://erratique.ch/software/odig/doc
