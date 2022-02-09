Otfm — OpenType font decoder for OCaml
-------------------------------------------------------------------------------
Release v0.3.0

Otfm is an in-memory decoder for the OpenType font data format. It
provides low-level access to font tables and functions to decode some
of them.

Otfm is made of a single module and depends on [Uutf][1]. It is distributed 
under the ISC license.

[1]: http://erratique.ch/software/uutf
     
Home page: http://erratique.ch/software/otfm  
Contact: Daniel Bünzli `<daniel.buenzl i@erratique.ch>

## Installation

Otfm can be installed with `opam`:

    opam install otfm

If you don't use `opam` consult the [`opam`](opam) file for build
instructions and a complete specification of the dependencies. 

## Documentation 

The documentation and API reference is automatically generated 
by `ocamldoc` from `otfm.mli`. It can be consulted [online][1] and
there is a generated version in the `doc` directory of the
distribution. 

[1]: http://erratique.ch/software/otfm/doc/Otfm

## Sample programs 

Sample programs are located in the `test` directory of the
distribution. They can be built with:

    ocamlbuild tests.otarget 
    
The resulting binaries are in `_build/test`:

- `test.byte` tests the library, nothing should fail.
- `otftrip.native`, among other things, reads an OpenType file and
  prints a human readable representation on `stdout`. Invoke with
  `-help` for more information.
