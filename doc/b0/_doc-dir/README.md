B0 — Software construction and deployment kit
-------------------------------------------------------------------------------

WARNING this package is unstable and work in progress, do not depend on it. 

B0 describes software construction and deployments using modular and
customizable definitions written in OCaml.

B0 describes:

* Build environments.
* Software configuration, build and testing.
* Source and binary deployments.
* Software life-cycle procedures.

B0 also provides the B00 build library which provides abitrary build
abstraction with reliable and efficient incremental rebuilds. The B00
library can be – and has been – used on its own to devise domain
specific build systems.

B0 is distributed under the ISC license. It depends on [cmdliner][cmdliner].

[cmdliner]: https://erratique.ch/software/cmdliner

## Install

b0 can be installed with `opam`:

    opam install b0

If you don't use `opam`, consult [`DEVEL.md`](DEVEL.md) for bootstrap 
instructions.

## Documentation

The documentation can be consulted [online][doc] or via `odig doc b0`.

[doc]: http://erratique.ch/software/b0/doc
