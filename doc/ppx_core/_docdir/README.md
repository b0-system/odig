ppx_core - a PPX standard library
=================================

Ppx\_core is a standard library for OCaml AST transformers. It
contains:

- various auto-generated AST traversal using an open recursion scheme
- helpers for building AST fragments
- helpers for matching AST fragments
- a framework for dealing with attributes and extension points

When used in combination with
[ppx\_driver](http://github.com/janestreet/ppx_driver), it features:

- spellchecking and other hints on misspelled/misplaced attributes and
  extension points
- checks for unused attributes (they are otherwise silently dropped by
  the compiler)

Ast version
-----------

Ppx\_core uses the specific version of the OCaml Abstract Syntax Tree
as defined by [Ppx\_ast](https://github.com/janestreet/ppx_ast).

Compatibility
-------------

If you want to write code that works with several versions of
Ppx\_core using different AST versions, you can use the versionned
alternatives for `Ast_builder` and `Ast_pattern`. For instance:

```ocaml
open Ppx_core
module Ast_builder = Ast_builder_403
module Ast_pattern = Ast_pattern_403
```
