ppx_bigarray
============

[![Build Status](https://travis-ci.org/akabe/ppx_bigarray.svg?branch=master)](https://travis-ci.org/akabe/ppx_bigarray)

This PPX extension provides
[big array](http://caml.inria.fr/pub/docs/manual-ocaml/libref/Bigarray.html)
literals in [OCaml](http://ocaml.org).

Install
-------

```
opam install ppx_bigarray
```

Development version:

```
opam pin add ppx_deriving https://github.com/akabe/ppx_bigarray.git
```

Usage
-----

### Compiling

```
ocamlfind ocamlc -package bigarray,ppx_bigarray -linkpkg foo.ml
```

`ppx_bigarray` outputs code that depends on the runtime library `ppx_bigarray.runtime` (`Ppx_bigarray_runtime` module).

If you use [Dune](https://github.com/ocaml/dune) (jbuilder), `dune` file is like

``` lisp
  (libraries  ppx_bigarray.runtime)
  (preprocess (pps ppx_bigarray))
```

### Example

`x` is a two-dimensional big array that has size 3-by-4, kind `Bigarray.int`,
and layout `Bigarray.c_layout`.

```OCaml
let x = [%bigarray2.int.c
          [
            [11; 12; 13; 14];
            [21; 22; 23; 24];
            [31; 32; 33; 34];
          ]
        ] in
print_int x.{1,2} (* print "23" *)
```

In this code, elements of a big array are given as a list of lists, but
you can use an array of arrays:

```OCaml
let x = [%bigarray2.int.c
          [|
            [|11; 12; 13; 14|];
            [|21; 22; 23; 24|];
            [|31; 32; 33; 34|];
          |]
        ] in
print_int x.{1,2} (* print "23" *)
```

`[%bigarray2.int.c ELEMENTS]` is a syntax of big array literals. `ELEMENTS`
must have a syntax of a list literal (`[...]`) or an array literal (`[|...|]`).
You cannot give an expression that returns a list or an array (such as
`let x = [...] in [%bigarray2.int.c x]`) since `[%bigarray2.int.c ...]` is NOT
the function that converts a list or an array into a big array.

### Basic syntax

- `[%bigarray1.KIND.LAYOUT ELEMENTS]` is a one-dimensional big array
  (that has type `Bigarray.Array1.t`). `ELEMENTS` is a list or an array.
- `[%bigarray2.KIND.LAYOUT ELEMENTS]` is a two-dimensional big array
  (that has type `Bigarray.Array2.t`). `ELEMENTS` is a list of lists or
  an array of arrays.
- `[%bigarray3.KIND.LAYOUT ELEMENTS]` is a three-dimensional big array
  (that has type `Bigarray.Array3.t`). `ELEMENTS` is a list of lists of lists or
  an array of arrays of arrays.
- `[%bigarray.KIND.LAYOUT ELEMENTS]` is a multi-dimensional big array
  (that has type `Bigarray.Genarray.t`). `ELEMENTS` is a nested list or
  a nested array.

You can specify the following identifiers as `KIND` and `LAYOUT`:

| `KIND`                       | Corresponding big array kind                            |
|------------------------------|---------------------------------------------------------|
| `int8_signed` or `sint8`     | `Bigarray.int8_signed`                                  |
| `int8_unsigned` or `uint8`   | `Bigarray.int8_unsigned`                                |
| `int16_signed` or `sint16`   | `Bigarray.int16_signed`                                 |
| `int16_unsigned` or `uint16` | `Bigarray.int16_unsigned`                               |
| `int32`                      | `Bigarray.int32`                                        |
| `int64`                      | `Bigarray.int64`                                        |
| `int`                        | `Bigarray.int`                                          |
| `nativeint`                  | `Bigarray.nativeint`                                    |
| `float32`                    | `Bigarray.float32`                                      |
| `float64`                    | `Bigarray.float64`                                      |
| `complex32`                  | `Bigarray.complex32`                                    |
| `complex64`                  | `Bigarray.complex64`                                    |
| `char`                       | `Bigarray.char`                                         |
| otherwise                    | (to refer the variable that has a given name as a kind) |

| `LAYOUT`                      | Corresponding big array layout                            |
|-------------------------------|-----------------------------------------------------------|
| `c` or `c_layout`             | `Bigarray.c_layout`                                       |
| `fortran` or `fortran_layout` | `Bigarray.fortran_layout`                                 |
| otherwise                     | (to refer the variable that has a given name as a layout) |

"otherwise" in the above tables means that users can specify user-defined names of kinds and
layouts in addition to built-in names, like the following code:

```OCaml
let f32 = Bigarray.float32
let f = Bigarray.fortran_layout
let x = [%bigarray1.f32.f [1.0; 2.0; 3.0]] (* Use `f32' and `f' instead of
                                              float32 and fortran_layout, respectively. *)
```

### Padding

Big arrays of two or more dimensions need to be rectangular.
If you write a non-rectangular big array literal, by default, `ppx_bigarray` warns
it in compile time (Warning 22), and lacked elements are uninitialized.
You can explicitly specify padding, a value of lacked elements by
`[@bigarray.padding EXPRESSION]`:

```OCaml
let x = [%bigarray2.int.c
          [
            [11; 12; 13; 14];
            [21; 22; 23];
            [31; 32];
          ] [@bigarray.padding 0]
        ]
```

In this case, lacked elements are initialized by `0`, i.e., the above code
is the same as

```OCaml
let x = [%bigarray2.int.c
          [
            [11; 12; 13; 14];
            [21; 22; 23;  0];
            [31; 32;  0;  0];
          ]
        ]
```

`[@bigarray.padding]` inhibits the warnings for non-rectangular big array literals.

### Alias

`[%bigarray.KIND.LAYOUT ...]` is slightly verbose syntax because
we usually use a few combinations of big array kinds and layouts.
You can define aliases of pairs of a kind and a layout that
you frequently use as follows:

```OCaml
(* `z' is an alias of complex64.fortran_layout. *)
let ppx_bigarray__z = Ppx_bigarray_runtime.({
    kind = Bigarray.complex64;
    layout = Bigarray.fortran_layout;
  })

(* %bigarray1.z is the same as %bigarray1.complex64.fortran_layout. *)
let x = [%bigarray1.z [...]]
```

`[%bigarray.ALIAS ...]` refers `ppx_bigarray__ALIAS.Ppx_bigarray_runtime.kind`
as a kind, and `ppx_bigarray__ALIAS.Ppx_bigarray_runtime.layout` as a layout.
