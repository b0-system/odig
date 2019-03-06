## Clarity - functional programming library for OCaml
### Description

The goal of this project is to make pure functional programming idioms as useful as possible given OCaml's absence of higher-kinded types and typeclasses.

### Main features are:

* Standard "classes" like Functor-Applicative-Monad
* Concrete instances like Reader-Writer-State
* Useful data types like Either, These or Vector

### Design notes

* All concrete datatypes also have its constructors defined as values where name is prefixed with underscore. Sometimes it's more convenient to use "curried", first-class version of a constructor, e.g. following two are equivalent:
```ocaml
let long  = List.map (fun x -> Some x) a
let short = List.map _Some x
```
* Applicative operator `ap` and its infix version `(<~>)` are "lazy" by its second argument. This allows for an applicative to "fail-fast" and don't compute unneeded values. "Strict" versions are called `ap'` and `(<*>)` respectively. "Laziness" here is just (unit -> 'a) closure, so you can use function combinators from Fn module for convenience:
```ocaml
open Clarity
open Option

(*
val (<*>) : ('a -> 'b) t -> 'a t -> 'b t
val (<~>) : ('a -> 'b) t -> (unit -> 'a t) -> 'b t

val serialize : int -> int -> string -> string
val idx : int option
val long_computation : int -> int option
val title : string option
*)

open Fn

let res : string Option.t =
  map serialize idx
    <~> defer long_computation 1024
    <*> title
```
* Right folds are also "lazy" by "accumulator" argument of a folding function. Strict right fold is called `foldr'`. This allows for shortcut when function no more needs data. For example, here is `any` function from Foldable module that checks if at least one element of a Foldable satisfies given predicate:
```ocaml
let any p = foldr (fun x a -> p x || a ()) (const false)
```

### Documentation

You can find ocamldoc [here](https://indiscriminatecoding.github.io/clarity-docs/).

### Manual installation

    $ make && make install

