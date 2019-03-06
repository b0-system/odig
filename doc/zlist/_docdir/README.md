# zlist: Lazy lists for OCaml

v0.1.2

`zlist` consists of the definition of a lazy list type and a number of useful functions for manipulating and constructing lazy lists.

## About

[![build status](https://gitlab.com/jhaberku/Zlist/badges/master/build.svg)](https://gitlab.com/jhaberku/Zlist/commits/master)

Development is hosted at [GitLab](https://gitlab.com/jhaberku/Zlist).

API documentation can be found [online](http://jhaberku.gitlab.io/Zlist/Zlist.html).

## Inspiration

This implementation is heavily inspired by "Functional Programming in Scala", by Chiusano and Bjarnason (2014).

## Installing

The easiest way to install `zlist` is through the `opam` repository:

```bash
$ opam install zlist
```

## Building

Alternatively, you can build and install `zlist` from its sources. This is easiest with the `topkg-care` package installed.

First, pin the sources using `opam`:

```bash
$ opam pin add zlist <TOP-LEVEL SOURCE DIRECTORY>
```

then build the package:

```bash
$ topkg build
```

After the package is built, `zlist`'s test suite is run by invoking

```bash
$ topkg test
```

## Lazy lists

The type of a lazy list is

```ocaml
type 'a t =
  | Nil
  | Cons of 'a Lazy.t * 'a t Lazy.t
```

That is, unlike a normal list, both the head and tail of a cons cell is lazily-evaluated. This lazy structure allows us to generate infinite lists and to apply arbitrary transformations to the list without constructing new instances in memory.

### Examples

Assume this following code has been evaluated in the OCaml top-level:

```ocaml
#require "zlist" ;;
open Zlist ;;
```

We can generate an infinite list of even integers:

```ocaml
let evens = Lazy_list.(enum_from 0 |> map (fun x -> 2 * x)) ;;
```

and observe the first 10:

```ocaml
Lazy_list.(take 10 evens |> to_list) ;;

- : int list = [0; 2; 4; 6; 8; 10; 12; 14; 16; 18]
```

The fibonacci numbers can be generated via `Lazy_list.unfold`:

```ocaml
let fibs = Lazy_list.unfold (0, 1) (fun (a, b) -> Some ((b, a + b), a)) ;;
fibs |> Lazy_list.(take 10 |> to_list) ;;

- : int list = [0; 1; 1; 2; 3; 5; 8; 13; 21; 34]
```

## License

`zlist` is copyright 2016 by Jesse Haber-Kucharsky.

`zlist` is released under the terms of the Apache license, version 2.0. See
`/LICENSE` for more information.
