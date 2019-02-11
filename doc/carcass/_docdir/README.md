Carcass — Define and generate file and directory carcasses 
-------------------------------------------------------------------------------
fc46137

> *carcass* /ˈkɑːkəs/ the structural framework of a building, ship, or piece
> of furniture — [*Oxford Dictionary of English*][def]

Carcass is a command line tool and OCaml library to define and generate
file and directory structures. 

The primary aim of Carcass is to help programmers to quickly setup new
software projects and deal with source and licensing boilerplate
during program development. Carcass is agnostic to content.

Carcass is distributed under the ISC license.

Home page: http://erratique.ch/software/carcass  
Contact: Daniel Bünzli `<daniel.buenzl i@erratique.ch>`

[def]: http://www.oxforddictionaries.com/definition/english/carcass

## Installation

Carcass can be installed with `opam`:

    opam install carcass

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

Once you have installed Carcass setup your personal information by running:
```
carcass setup
```

## Documentation

Carcass is extensively documented in man pages available through it's help
system. Type:

```
carcass help basics # to get started
carcass help        # for more help
```

The library documentation and API reference is automatically generated
by `ocamldoc` from the interfacdes. It can be consulted [online][doc]
and there is a generated version in the `doc` directory of the
distribution.

[doc]: http://erratique.ch/software/carcass/doc




