Meta_conv for ppx
==============================

`ppx_meta_conv` is a plugin/wrapper for `ppx_deriving` to provide data conversion between OCaml values and tree formed data structures such as JSON, Sexp, pseudo OCaml value code and so on.

`ppx_meta_conv` is a PPX port of `meta_conv` for CamlP4, which is a generalization of `type_conv`. The first objective of `meta_conv` and `ppx_meta_conv` is to provide an easy way to implement conversions of data formats as possible. If you get performance problems probably you should check other ppx based data converters specific to one data format. 

Typical usage of `ppx_meta_conv` is like `type ty = ... [@@deriving conv{target}]`.
`ppx_meta_conv` creates conversion functions between `ty` and `target`, namely
`target_of_ty`, `ty_of_target` and `ty_of_target_exn`.
`ppx_meta_conv` itself knows nothing about the data type `target` except its name,
and generate code which composes primitives defined in module `Target_conv`.
The primitives of `Target_conv` must be given externally.  As conversions, currently
`ppx_meta_conv_ocaml`, `ppx_meta_conv_tiny_json` and `ppx_meta_conv_sexp` packages are provided.

Basic
==========

```
type 'a t = <definition> [@@deriving conv{name}]
```

Multiple targets
==================

```
type t = <definition> [@@deriving conv{target_1; ..; target_n}]
```

Only one direction
==================

```
(* Only defines ocaml_of_t. t_of_ocaml is skipped *)
type t = <definition> [@@deriving conv{ocaml_of}]
```

Inlined
==================

```
[%ocaml_of: type] (* type to Ocaml.t *)
```

```
[%of_ocaml: type] (* Ocaml.t to type. Failure is reported as `Error *)
```

```
[%of_ocaml_exn: type] (* Ocaml.t to type. Failure is reported as an exception *)
```

Using special name
=====================

Normally tag names of the external data structure (such as JSON) are as same as
the names of variant constructors and record fields.  You can override them
by `[@conv.as xxx]` attribute:

```
type 'a t =
  | Zee                          (* The default name "Zee" is used *)
  | Foo [@conv.as foo]           (* "foo", instead of "Foo" *)
  | Bar [@conv.as "bar"]         (* "bar", instead of "Bar" *)
  | Boo [@conv.as {json="boo"}] (* "boo", instead of "Boo" only for "json" converter *)
  [@@deriving conv{ocaml, json}]
```

```
type t =
  { x : int [@conv.as X];           (* "X" is used, instead of "x" *) 
    y : float [@conv.as {json="Y"}] (* "Y" is used instead of "y" only for "json" converter *) 
  } 
  [@@deriving conv{ocaml; json}]
```

Field for Leftovers
======================

External data structure may contain unexpected fields for OCaml programs,
we can keep those leftovers as they are using a special type named `mc_leftovers`. 

```
type 'a mc_leftovers = (string * 'a) list
type t =
  { x : int;
    y : float;
    rest : Tiny_json.t mc_leftovers;
  [@@deriving conv{json}]
```

With the above definition, `json_of_t` can handle JSON records which contain
at least `x` and `y` fields.  The other fields than `x` and `y` are stored in `rest`.

Ignore unknown fields
===========================

By default, `ty_of_target` and `ty_of_target_exn` functions fail if the input data
contains unknown fields to these functions.  Attribute `[@conv.ignore_unknown_fields]`
makes these functions ignore such unknown fields:

```
type t = {
    foo: int;
    bar: float;
  } [@conv.ignore_unknown_fields] (* t_of_ocaml does not fail even if the source contains fields other than foo and bar *)
    [@@deriving conv{ocaml}]
```

Optional field 
============================

Type `mc_option` is equivalent with `option` but has a special meaning in `ppx_meta_conv`.  Record fields with this type may not exist in the target data structure:

```
type t = { x : int;
           y : float mc_option  (* the source may have a field y of type float,
                                   or may not have it at all. *)
         } 
         [@@deriving conv{name}]
```
