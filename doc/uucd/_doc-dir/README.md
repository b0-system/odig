Uucd — Unicode character database decoder for OCaml
-------------------------------------------------------------------------------
v13.0.0 — Unicode version 13.0.0

Uucd is an OCaml module to decode the data of the [Unicode character 
database][1] from its XML [representation][2]. It provides high-level 
(but not necessarily efficient) access to the data so that efficient 
representations can be extracted.

Uucd is made of a single module, depends on [Xmlm][xmlm] and is distributed
under the ISC license.

[1]: http://www.unicode.org/reports/tr44/
[2]: http://www.unicode.org/reports/tr42/
[xmlm]: http://erratique.ch/software/xmlm 

Home page: http://erratique.ch/software/uucd  

## Installation

Uucd can be installed with `opam`:

    opam install uucd

If you don't use `opam` consult the [`opam`](opam) file for build
instructions and a complete specification of the dependencies.


## Documentation

The documentation and API reference can be consulted [online][doc]
or via `odig doc uucd`.

[doc]: http://erratique.ch/software/uucd/doc/Uucd
