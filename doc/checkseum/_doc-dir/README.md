Checkseum
=========

Chekseum is a library which implements ADLER-32 and CRC32C Cyclic Redundancy
Check. It provides 2 implementation, the first in C and the second in OCaml. The
library is on top of [`optint`](https://github.com/dinosaure/optint.git) to get
the best representation of the CRC in the OCaml world.

### Linking trick / variant

Then, as [`digestif`](https://github.com/mirage/digestif.git), `checkseum` uses
the linking trick. So if you want to use `checkseum` in a library, you can link
with the `checkseum` package which **does not** provide an implementation. Then,
end-user can choose between the C implementation or the OCaml implementation
(both work on Mirage).

So, in `utop`, to be able to fully use `checkseum`, you need to write:
```sh
$ utop -require checkseum.c
```
or
```sh
$ utop -require checkseum.ocaml
```

In a `dune` workspace, the build-system is able to choose silently default
implementation (`checkseum.c`) for your executable if you don't specify one of them.
A _dune_-library is not able to choose an implementatio but still able to use the
_virtual_ library `checkseum`.

## Build Requirements

 * OCaml >= 4.03.0
 * `base-bytes`
 * `base-bigarray`
 * `dune` to build
 * `optint`
