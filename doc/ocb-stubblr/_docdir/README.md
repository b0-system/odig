ocb-stubblr — OCamlbuild plugin for C stubs
-------------------------------------------------------------------------------
v0.1.1

Do you get excited by C stubs? Do they sometimes make you swoon, and even faint,
and in the end no `cmxa`s get properly linked -- not to mention correct
multi-lib support?

Do you wish that the things that excite you the most, would excite you just a
little less? Then ocb-stubblr is just the library for you.

ocb-stubblr is about ten lines of code that you need to repeat over, over, over
and over again if you are using `ocamlbuild` to build OCaml projects that
contain C stubs -- now with 100% more lib!

It does what everyone wants to do with `.clib` files in their project
directories. It can also clone the `.clib` and arrange for multiple compilations
with different sets of discovered `cflags`.

ocb-stubblr is distributed under the ISC license.

## Set it up

`pkg/pkg.ml`:

    #require "ocb-stubblr.topkg"
    open Ocb_stubblr_topkg

    let () =
      Pkg.describe ~build:(Pkg.build ~cmd ()) ...

`myocamlbuild.ml`:

    open Ocamlbuild_plugin

    let () = dispatch Ocb_stubblr.init

`opam`:

    depends: [
      "ocamlfind"   {build}
      "ocamlbuild"  {build}
      "topkg"       {build}
      "ocb-stubblr" {build}
      ...
    ]

## Documentation

Interfaces are documented. [Online][doc] too.

[doc]: https://pqwy.github.io/ocb-stubblr/doc

## Development

Feel free to pitch in with ideas, especially if you have work-flows that are
not, but could *almost* be supported.

[![Build Status](https://travis-ci.org/pqwy/ocb-stubblr.svg?branch=master)](https://travis-ci.org/pqwy/ocb-stubblr)
