---
title: ppx_compare
parent: ../README.md
---

Generation of fast comparison functions from type expressions and definitions.

Ppx_compare is a ppx rewriter that derives comparison functions from type
representations. The scaffolded functions are usually much faster than ocaml's
`Pervasives.compare`. Scaffolding functions also gives you more flexibility by allowing
you to override them for a specific type and more safety by making sure that you only
compare comparable values.

We use `ppx_deriving`/`ppx_type_conv`, so type definitions are annotated this way:

```ocaml
type s = v * w [@@deriving compare]
```

This will generate `compare_s : s -> s -> int` function that relies on
`compare_v : v -> v -> int` and `compare_w : w -> w -> int`.

Compare is not DWIM (do what I mean): it will scaffold a fast well behaved comparison
(reflexive, transitive, symmetric...) function however it does not try to follow any
"natural ordering". For instance arrays of characters are not sorted lexicographically.

Base types (options,int,array,lists,char,floats...) have the same comparison order than
Pervasives.compare (provided their type parameters also do for the polymorphic ones).

Records fields are compared in the order they are defined (left to right); tuples fields
are compared left to right. When we compare two branches of a sum whichever ones comes
first in the definition is considered lowest. Polymorphic variants use the same ordering
as the ocaml runtime.


Calling `compare` for type `t`s
-------------------------------

In compliance (or conformance) with Janestreet's coding standard we assume that
type named `t` are the main types in a module and

```ocaml
type t = S.t * T.t [@@deriving compare]
```

will call the functions `S.compare` and `T.compare` instead of calling `S.compare_t` and
`T.compare_t`. This will also generate a `compare : t -> t -> int` function.


Signature
---------

`type t [@@deriving compare]` in a module signature will add `val compare : t -> t -> int`
in the signature.


Comparison without a type definition
------------------------------------

Sometimes you just want a comparison without having to create a new type. You can create
such a comparison function using the `[%compare: ..]` extension point:

```ocaml
let gt x y = [%compare: float * int * [`A | `B | `C] ] x y
```

You can also check for equality using `[%compare.equal: ..]`, which produces a function
that returns `true` precisely when `[%compare: ..]` returns `0`.
