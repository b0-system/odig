Dicomm — Non-blocking streaming DICOM data element decoder for OCaml
-------------------------------------------------------------------------------
Release v0.0.0-17-g86c7a0c

Dicomm is a non-blocking streaming decoder for [DICOM][1] data elements.

Dicomm depends on bigarrays and is distributed under the ISC license.

[1]: http://medical.nema.org/standard.html

Home page: http://erratique.ch/software/dicomm  
Contact: Daniel Bünzli `<daniel.buenzl i@erratique.ch>`

## Installation

Dicomm can be installed with `opam`:

    opam install dicomm

If you don't use `opam` consult the [`opam`](opam) file for build
instructions and a complete specification of the dependencies. 

## Documentation 

The documentation and API reference is automatically generated 
by `ocamldoc` from `dicomm.mli`. It can be consulted [online][2] and
there is a generated version in the `doc` directory of the
distribution. 

[2]: http://erratique.ch/software/dicomm/doc/Dicomm

## Sample programs 

Sample programs are located in the `test` directory of the
distribution. They can be built with:

    ocamlbuild tests.otarget 
    
The resulting binaries are in `_build/test`:

- `test.byte` tests the library, nothing should fail.
- `dicomtrip.native`, among other things, reads a DICOM file and
  prints a human readable representation on `stdout`. Invoke with
  `-help` for more information.
