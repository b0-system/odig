# Fast pipe ppx [![Build Status](https://travis-ci.org/IwanKaramazow/FastPipe.svg?branch=master)](https://travis-ci.org/IwanKaramazow/FastPipe)

Pipe first as a syntax transform. Transforms expressions containing the `|.` (Ocaml) or `->` (Reason) operator.
Pipes the left side as first argument of the right side.

*Reason*
```reason
/* validateAge(getAge(parseData(person))) */
person
->parseData
->getAge
->validateAge;

/* Some(preprocess(name)); */
name->preprocess->Some;

/* f(a, ~b, ~c) */
a->f(~b, ~c)
```

*Ocaml*
```ocaml
(* validateAge (getAge (parseData person)) *)
person
|. parseData
|. getAge
|. validateAge

(* Some(preprocess name) *)
name |. preprocess |. Some;

(*f a ~b ~c *)
a |. f ~b ~c
```

## Usage with Dune
`dune` file
```
(executable
  (name hello_world)
  (preprocess  (pps fast_pipe_ppx))
```

Reason: implementation of the `hello_world.re` file
```reason
let () =
  1000
  ->string_of_int
  ->print_endline;
```

Ocaml: implementation of the `hello_world.ml` file
```ocaml
let () =
  1000
  |. string_of_int
  |. print_endline
```

## Developing:

```
npm install -g esy
git clone <this-repo>
esy install
esy build
```

## Running Tests:

```
esy test
```
