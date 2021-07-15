# Encore

## serializer / deserializer

The goal of `encore` is to provide a way to express a _format_. From it, the user
is able to make an [angstrom][angstrom]'s parser or a `lavoisier`'s encoder. It wants to
ensure _isomorphism_:

```ocaml
type v

let t : v Encore.t = ...
let decoder = Encore.to_angstrom t
let encoder = Encore.to_lavoisier t

let assert random_v =
  let str = Encore.Lavoisier.emit_string random_v encoder in
  let v'  = Angstrom.parse_string decoder str in
  assert (v = v')
```

## How to install?

`encore` requires OCaml 4.07 and it is available with OPAM:
```sh
$ opam install encore
```

It can be compiled with `js_of_ocaml`.

## Documentation

A documentation is available [here][documentation] to explain how to properly
use `encore`. Some examples of `encore` exists into [ocaml-git][ocaml-git].

## Inspirations

This project is inspired by the [finale][finale] project which is focused on a
pretty-printer at the end. Encore is close to provide a low-level encoder like
[faraday][faraday] than a generator of a pretty-printer.

[documentation]: https://mirage.github.io/encore/encore/Encore/index.html
[faraday]: https://github.com/inhabitedtype/faraday.git
[angstrom]: https://github.com/inhabitedtype/angstrom.git
[ocaml-git]: https://github.com/mirage/ocaml-git.git
[finale]: https://github.com/takahisa/finale.git
