Flexible Embedded Build System
==============================

<!--begin:description-->
Febusy is a library which, through a monadic API, allows one to build a
dependency graph between effectful computations while keeping track of
their products, a.k.a. “build artifacts.”

For now, one can run the builds sequentially with the `Febusy.Edsl.Make_unix`
module but the build-artifacts are still properly kept track of between runs
with “state” files.
<!--end:description-->

- Source: <https://gitlab.com/smondet/febusy/>
- Documentation: <http://smondet.gitlab.io/febusy/>.

Build
-----

This builds everything:

    ocaml please.ml configure
    jbuilder build @install
    jbuilder build _build/default/src/test/main.exe

See also `tools/ci-build.sh`.

Usage
-----

See the module `Febusy.Edsl` to construct a direct acyclic graph of build
artifacts and then the function `Febusy.Edsl.Make_unix.run` to “run” the
incremental build (cf. also
[`edsl.mli`](https://gitlab.com/smondet/febusy/blob/master/src/lib/edsl.mli)).

See `src/test/examples.ml` for examples, especially:

- `let tiny_example () = ...`: a very simple `A->B->C` dependency DAG.
- `let build_website ~output = ...`: the build of the
  <http://smondet.gitlab.io/febusy/> website.

Works with `utop`:

    jbuilder utop src/lib/
    #use "src/test/examples.ml";;
    tiny_example;; (* <- checkout the type *)
    let ret = Febusy.Edsl.Make_unix.run ~state_file:"/tmp/utop-test.state" tiny_example;;

Authors
-------

- Seb Mondet <https://seb.mondet.org>

License
-------

ISC License:

```
Copyright 2018, Seb Mondet <seb@mondet.org>

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
```

