OCaml-safepass
==============

[![Build Status](https://travis-ci.org/darioteixeira/ocaml-safepass.svg?branch=master)](https://travis-ci.org/darioteixeira/ocaml-safepass)


Overview
--------

OCaml-safepass is a library offering facilities for the safe storage of
user passwords.  By "safe" we mean that passwords are salted and hashed
using the [Bcrypt][] algorithm.  Salting prevents [rainbow-table based
attacks][RT], whereas hashing by a very time-consuming algorithm such as
Bcrypt renders brute-force password cracking impractical.

OCaml-safepass's obvious usage domain are web applications, though it does not
depend on any particular framework.  Internally, OCaml-safepass binds to the C
routines from Openwall's [Crypt_blowfish][Crypt].  However, it would be
incorrect to describe OCaml-safepass as an OCaml binding to Crypt_blowfish,
because the API it exposes is higher-level and more compact than that offered
by Crypt_blowfish.  Moreover, OCaml-safepass's API takes advantage of OCaml's
type-system to make usage mistakes nearly impossible.


Dependencies
------------

OCaml-safepass has no external dependencies.  Note that it bundles
the Public Domain licensed `crypt_blowfish.h` and `crypt_blowfish.c`
C modules from Openwall's Crypt_blowfish.


Building and installing
-----------------------

OCaml-safepass is available in [OPAM][], which is the recommended installation
method.  If you wish to compile it yourself manually, note that the build system
uses [Dune][].  You can use the customary `make` to build OCaml-safepass, and
`make doc` to generate the API documentation.


License
-------

OCaml-safepass is distributed under the terms of the GNU LGPL version 2.1 with
the usual OCaml linking exception.  See LICENSE file for full license text.


[Bcrypt]: https://en.wikipedia.org/wiki/Bcrypt
[RT]: https://en.wikipedia.org/wiki/Rainbow_table
[Crypt]: http://www.openwall.com/crypt/
[OPAM]: https://opam.ocaml.org/
[Dune]: https://github.com/ocaml/dune
