# `ppx_integer`

`ppx_integer` is a PPX syntax extension to write integer literals with
non standard suffix characters of `[g-zG-Z]`. Using `ppx_integer`,
you can easily write non standard integer literals, such as
like `1234u` for `Uint32`, `0xabcdU` for `Uint64`, etc.

## Desugaring

`ppx_integer` does not touch the integer literals with the standard suffix chars, `L`, `l` and `n`.

A literal with a non standard suffix char is expanded to a variable.
For example, `1234u` is expanded to:

```
integer_1234u
```

`ppx_integer` also builds a definition declaration of the created variable:

```
let integer_1234u = Ppx_integer._u "1234"
```

By default, these bindings are placed at the beginning of the compilation unit.
For example, the following program:

```
let () = prerr_endline @@ Uint32.to_string 1234u
let () = prerr_endline @@ Uint32.add 1234u 2345u
```

is converted to 

```
let integer_1234u = Ppx_integer._u "1234"
let integer_2345u = Ppx_integer._u "2345"
let () = prerr_endline @@ Uint32.to_string integer_1234u
let () = prerr_endline @@ Uint32.add integer_1234u integer_2345u
```

Note that the variable for the same literals is created only once.

## Module `Ppx_integer`

It is the user's responsibility to prepare a module `Ppx_integer`
which provides functions `Ppx_integer._X` where `X` are non standard
integer suffix chars used in the user's code.

## Variable declaration placeholder

Using `[%%ppx_integer]`, you can change the place of the generated 
`integer_...` variable declarations.  This is useful if the module 
`Ppx_integer` is defined in the same compilation unit:

```
module Ppx_integer = struct
  let _u s = Uint32.of_string
end

[%%ppx_integer] (* <- variable declarations come here, not to the top *)

let () = prerr_endline @@ Uint32.to_string 1234u
let () = prerr_endline @@ Uint32.add 1234u 2345u
```

## Why not other chars?

In OCaml, integer literal suffix chars are restricted to `[g-zG-Z]`,
since `[a-fA-F]` are used for hex integers.
