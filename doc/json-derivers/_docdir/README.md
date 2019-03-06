# json-derivers

This library provides comparison, hashing, and sexp conversion functions for the
[Yojson.Safe.t](https://github.com/mjambon/yojson) and
[Ezjsonm.t](https://github.com/mirage/ezjsonm) types with a minimal amount of
dependencies (only https://github.com/janestreet/base):

## `Json_derivers.Yojson`

```ocaml
type t =
  [ `Assoc of (string * t) list
  | `Bool of bool
  | `Float of float
  | `Int of int
  | `Intlit of string
  | `List of t list
  | `Null
  | `String of string
  | `Tuple of t list
  | `Variant of string * t option ]

val sexp_of_t : t -> Base.Sexp.t
val t_of_sexp : Base.Sexp.t -> t
val compare : t -> t -> int
val hash : t -> int
```

## `Json_derivers.Jsonm`

```ocaml
type value =
  [ `Null
  | `Bool of bool
  | `Float of float
  | `String of string
  | `A of value list
  | `O of (string * value) list ]

val sexp_of_value : value -> Base.Sexp.t
val value_of_sexp : Base.Sexp.t -> value
val compare : value -> value -> int
val hash : value -> int

type t =
  [ `A of value list
  | `O of (string * value) list ]

val sexp_of_t : t -> Base.Sexp.t
val t_of_sexp : Base.Sexp.t -> t
val compare : t -> t -> int
val hash : t -> int
```
