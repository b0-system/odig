# ppx_deriving_crowbar

## What is this?

`ppx_deriving_crowbar` is a [ppx_deriving](https://github.com/ocaml-ppx/ppx_deriving) plugin for generating [crowbar](https://github.com/stedolan/crowbar) generators.

## Examples:

```
type number = int [@@deriving crowbar]
```

will result in a function which maps Crowbar's `int` generator primitive to a `t`:

```
let number_to_crowbar : t Crowbar.gen = Crowbar.(map [int] (fun a -> a))
```

You can specify a custom generator to replace the automatically derived one with `[@generator f]`.  (This is useful in large mutually-recursive type definitions, where you want *most* of the automatically derived functions.)  For example:

```
type p = int
and q = p list
and r = q list [@generator Crowbar.const []]
[@@deriving crowbar]
```

to create the following functions:

```
let p_to_crowbar : p Crowbar.gen = Crowbar.(map [int] fun a -> a)
and q_to_crowbar : q Crowbar.gen = Crowbar.list p_to_crowbar
and r_to_crowbar : r Crowbar.gen = Crowbar.const []
```

Note that types named `t` get functions named `to_crowbar`, rather than `t_to_crowbar`, as is the convention for `ppx_deriving` plugins.

## Examples

`ppx_deriving_crowbar` is used in tandem with [`ppx_import`](https://github.com/ocaml-ppx/ppx_import) to automatically generate OCaml ASTs to test `ocaml-migrate-parsetree` in [ocaml-test-omp](https://github.com/yomimono/ocaml-test-omp), and to generate certificates to test `ocaml-x509` in [ocaml-test-x509](https://github.com/yomimono/ocaml-test-x509).
