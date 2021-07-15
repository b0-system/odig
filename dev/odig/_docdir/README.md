odig — Lookup documentation of installed OCaml packages
-------------------------------------------------------------------------------
44a3d1eb24

odig is a command line tool to lookup documentation of installed OCaml
packages. It shows package metadata, readmes, change logs, licenses,
cross-referenced `odoc` API documentation and manuals.

odig is distributed under the ISC license.

Homepage: https://erratique.ch/software/odig  

## Installation

odig can be installed with `opam`:

    opam install odoc ocaml-manual odig

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Documentation

A few commands to get you started:

    odig doc           # Show API docs and manuals of installed packages
    odig readme odig   # Consult the readme of odig
    odig changes odig  # Consult the changelog of odig
    odig browse issues odig  # Browse odig's issues.

The manual and packaging conventions can be consulted [online][doc] or
via `odig doc odig`.

[doc]: https://b0-system.github.io/odig/doc/odig/

## Sample odoc API documentation and manuals

A sample output of generated API documentation and manuals on a
best-effort maximal set of packages of the OCaml opam repository is
available [here](https://b0-system.github.io/odig/doc/).

The different themes distributed with `odig` can be seen on the sample
at these addresses:

* https://b0-system.github.io/odig/doc@odig.dark/
* https://b0-system.github.io/odig/doc@odig.light/
* https://b0-system.github.io/odig/doc@odig.gruvbox.dark/
* https://b0-system.github.io/odig/doc@odig.gruvbox.light/
* https://b0-system.github.io/odig/doc@odig.solarized.dark/
* https://b0-system.github.io/odig/doc@odig.solarized.light/
* https://b0-system.github.io/odig/doc@odoc.default/

The [Vg](https://b0-system.github.io/odig/doc/vg/Vg/index.html) module
and its sub-modules is a good example to look at, it has a good
mix of documentation cases.
