[![Build Status](https://travis-ci.org/cryptosense/records.svg)](https://travis-ci.org/cryptosense/records)

Dynamic records
===============

This library enables you to define and manipulate dynamic records in OCaml.

## Example

Let us define a "point" record with three integer fields: x, y and z.

First, declare a new record layout.

```ocaml
module Point = (val Record.Safe.declare "point")
```

Second, define the fields. They have the type `(int, Point.s) field`
(`Point.s` is a phantom type that guarantees type safety).

```ocaml
let x = Point.field "x" Record.Type.int
let y = Point.field "y" Record.Type.int
let z = Point.field "z" Record.Type.int
```

Third, "seal" this record structure. This prevents it from being further modified.
Structures must be sealed before they can be used.

```ocaml
let () = Point.seal ()
```

At this point, you have a working record structure. The next step is to create
actual records. They have the type `Point.s Record.t` and are created using
`Point.make`. Initially their fields have no value.

```ocaml
let _ =
  let p = Point.make () in
  Record.set p x 3;
  Record.set p y 4;
  Record.set p z 5;
  Record.format Format.std_formatter p
```

The last line outputs:

```json
{"x":3,"y":4,"z":5}
```

## Licensing

This library is available under the 2-clause BSD license.
See `COPYING` for more information.
