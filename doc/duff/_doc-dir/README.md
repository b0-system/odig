Duff – libXdiff implementation in OCaml
=======================================

Duff is a little library to implement [libXdiff][libXdiff] in OCaml. This
library is a part of the [ocaml-git][ocaml-git] project. This code is a
translation of `diff-delta.c` available on the git project in OCaml. So, it
respects some git's constraints unlike libXdiff.

## Examples

This library let the user to calculate an `index` from a source (a hash-table)
which can be computed with a blob. Then, from `index` (which represents your
source) and a blob, we generate a list of `Copy` and `Insert` elements.

- `Copy (off, len)` means to take a slice of `len` bytes from your source at
  `off` (absolute offset) and copy it.
- `Insert (off, len)` means to store a slice of `len` bytes from your __blob__
  at `off` (absolute offset) and copy it.
  
From this information, we can have a tiny representation of your blob which can
be reconstruct with your source. The goal is to store `Copy` *opcode* with `off`
and `len`, and `Insert` *opcode* which contains a slice of your blob.

Finally, to produce a PACK file in git or ocaml-git, we use this algorithm and
this representation to optimize storage of your blobs (cf. `git gc`).

### Binary

You can see an example of `duff` in `bin` directory. It's an executable to
represent a _thin_ representation of your file. Then, you can reconstruct it
with `patch` sub-command.

This is an example to use `duff`:

```sh
$ ./duff.exe diff source target > target.xduff
$ ./duff.exe patch source < target.xduff > target.new
$ diff target target.new
$ echo $?
0
```

The internal format used is close to what `git` does internally (without `zlib`
layer). However, it does not correspond to an _official_ format. The binary is
not optimized to be used in a production environment but feedback and
improvement on it are welcome.

## Limitations

Because this project is used by [ocaml-git][ocaml-git], we have some
limitations:

- We compute at most `0xFFFFFFFE` bytes from source
- An `insert` block can not be bigger than `0x10000` bytes

For example, libXdiff computes a bigger source than this implementation. Then,
limitation about `insert` block depends on the PACK (git) file format. So, don't
ask me to compute bigger source or merge and produce bigger `insert` block -
these constraints is outside the scope of this library.

From this limitation, `Copy` *opcode* have an offset between 0x0 and 0xFFFFFFE
and `off + len` is lower than 0xFFFFFFFE.

## Fuzzer

We provide a fuzzer to randomly test this library. Currently (4/9/2018),
`afl-fuzz` did not find any bugs and it computed 67.7k cycles (117 paths).

[libXdiff]: http://www.xmailserver.org/xdiff-lib.html
[ocaml-git]: https://github.com/mirage/ocaml-git
