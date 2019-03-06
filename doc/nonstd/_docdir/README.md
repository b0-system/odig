Non-standard Mini-Library
=========================

> In the presence of a [good](http://opam.ocaml.org/) package manager; standard
> libraries are an obsolete concept.

Core-style (labels, exceptionless) pure-OCaml super-light library
providing basic modules: List, Option, Int. and Float.

This library is an extremely minimalistic library to `open`:

- `val (|>)` (for compatibility with older versions of OCaml),
- `include` [`Printf`](http://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html),
- A more complete `List` module
  (a subset of Base's [one](https://github.com/janestreet/base/blob/master/src/list.mli)),
- `Array` is [`ArrayLabels`](http://caml.inria.fr/pub/docs/manual-ocaml/libref/ArrayLabels.html),
- Minimalistic `Option` module,
- Basic `Int` and `Float` modules.

and that's all, no dependencies, no C, nothing you don't use.

