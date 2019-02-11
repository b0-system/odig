---
title: ppx_type_conv - Support Library for type-driven code generators
parent: ../README.md
---

What is `type_conv`?
--------------------

The `type_conv` library factors out functionality needed by different
preprocessors that generate code from type specifications.  Example
libraries currently depending on `type_conv`:

  * `ppx_bin_prot`
  * `ppx_compare`
  * `ppx_fields_conv`
  * `ppx_sexp_conv`
  * `ppx_variants_conv`

`type_conv` for users of [ppx_deriving](https://github.com/whitequark/ppx_deriving)
-----------------------------------------------------------------------------------

`type_conv` based code generators are meant to be used with
[ppx_driver://github.com/janestreet/ppx_driver). However
`type_conv` allows to export a compatible `ppx_deriving` plugin.
By default, when not linked as part of a driver, packages using
`type_conv` will just use ppx_deriving.

So for instance this will work as expected using `ppx_deriving`:

    ocamlfind ocamlc -c -package ppx_sexp_conv foo.ml

For end users, the main advantage of using `type_conv` based
generators with ppx_driver is that it will catch typos and attributes
misplacement. For instance:

```ocaml
# type t = int [@@derivin sexp]
Error: Attribute `derivin' was not used
Hint: Did you mean deriving?
# type t = int [@@deriving sxp]
Error: ppx_type_conv: 'sxp' is not a supported type type-conv generator
Hint: Did you mean sexp?
# type t = int [@deriving sexp]
Error: Attribute `deriving' was not used
Hint: `deriving' is available for type declarations, type extensions
and extension constructors but is used here in the context of a core type.
Did you put it at the wrong level?"
```

For instruction on how to use `ppx_driver`, refer to the
[ppx\_driver's documentation](https://github.com/janestreet/ppx_driver).

Syntax
------

This part is only relevant if you are using `ppx_driver`. If you are
using `ppx_deriving` the syntax is the one of `ppx_deriving`.

`type_conv` interprets the `[@@deriving ...]` attributes on type
declarations, exception declarations and extension constructor
declarations:

```ocaml
type t = A | B [@@deriving sexp, bin_io]
```

`sexp` and `bin_io` are called generators. They are functions that
generate code given the declaration. These functions are implemented
by external libraries such as `ppx_sexp_conv` or
`ppx_bin_prot`. `type_conv` itself provides no generator, it does only
the dispatch.

Generators can take arguments. This is done using the following syntax:

```ocaml
type t = A | B [@@deriving foo ~arg:42]
```

For arguments that are just switches, it is common to use the
following syntax:

```ocaml
type t = A | B [@@deriving foo ~bar]
```

Plugin as findlib libraries
---------------------------

You must essentially follow the same rule for ppx\_type\_conv plugins
as for ppx\_driver ones when writing the META file.

Contact Information and Contributing
------------------------------------

In the case of bugs, feature requests, contributions and similar, please
contact the maintainers:

  * Jane Street Capital, LLC <opensource@janestreet.com>

Up-to-date information should be available at <https://github.com/janestreet/type_conv>.
