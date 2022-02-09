qrc — QR code encoder for OCaml
===============================
v0.1.0

Qrc encodes your data into QR codes. It has built-in QR matrix
renderers for SVG, ANSI terminal and text.

Qrc is distributed under the ISC license. It has no dependencies.

Homepage: https://erratique.ch/software/qrc

# Installation

qrc can be installed with `opam`:

    opam install qrc

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

# Documentation

The documentation can be consulted [online][doc] or via `odig doc
qrc`.

Questions are welcome but better asked on the [OCaml forum][ocaml-forum] 
than on the issue tracker.

[doc]: https://erratique.ch/software/qrc/doc
[ocaml-forum]: https://discuss.ocaml.org/

# Sample programs

The [`qrtrip`](test/qrtrip.ml) tool generates QR codes from the
command line.  It renders QR matrices to SVG, ANSI terminals and
US-ASCII or UTF-8 text.
