omod — Lookup and load installed OCaml modules
-------------------------------------------------------------------------------
v0.0.2

Omod is a library and command line tool to lookup and load installed OCaml
modules. It provides a mecanism to load modules and their dependencies
in the OCaml toplevel system (REPL).

omod is distributed under the ISC license.

Homepage: http://erratique.ch/software/omod  

## Installation

omod can be installed with `opam`:

    opam install omod

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Usage

    rlwrap ocaml
    # #use "omod.top"
    # Omod.load "Unix"
    # Omod.status ()

## Documentation

The documentation and API reference is generated from the source
interfaces. It can be consulted [online][doc] or via `odig doc omod`.

[doc]: http://erratique.ch/software/omod/doc

