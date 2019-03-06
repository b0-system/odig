Genspio: Generate Shell Phrases In OCaml
========================================

Genspio is a typed EDSL to generate shell scripts and commands from OCaml.

The idea is to build values of type `'a EDSL.t` with the
combinators in the `Genspio.EDSL` module, and compile them to POSIX
shell scripts (or one-liners) with functions from `Genspio.Compile`.
See the file
[`src/examples/small.ml`](https://github.com/hammerlab/genspio/blob/master/src/examples/small.ml)
which generates a useful list of usage examples, or the
section [“Getting Started”](#getting-started) below.

The tests run the output of the compiler against a few shells that it tries to
find on the host (e.g. `dash`, `bash`, `busybox`, `mksh`, `zsh` … cf. the
example test results summary below).

If you have any questions, do not hesitate to submit an
[issue](https://github.com/hammerlab/genspio/issues).

Genspio's documentation root is at <https://smondet.gitlab.io/genspio-doc/>.

Build
-----

You can install the library though `opam`:

    opam install genspio

Or get the development version with `opam pin`:

    opam pin add genspio https://github.com/hammerlab/genspio.git

You can also build locally:

You need OCaml ≥ 4.03.0 together with
[`nonstd`](http://www.hammerlab.org/docs/nonstd/master/index.html),
[`sosa`](http://www.hammerlab.org/docs/sosa/master/index.html), and
[`jbuilder`](https://github.com/janestreet/jbuilder):

    ocaml please.mlt configure
    jbuilder build @install

Getting Started
---------------

Here is a quick example:

```ocaml
utop> open Genspio.EDSL;;

utop>
let c =
  let username_one_way : str t =
    (* We lift the string "USER" to EDSL-land and use function `getenv`: *)
    getenv (str "USER") in
  let username_the_other_way : str t =
    (* The shell-pipe operator is `||>` *)
    (exec ["whoami"] ||> exec ["tr"; "-d"; "\\n"])
    (* `get_stdout` takes `stdout` from a `unit t` as a `byte_array t` *)
    |> get_stdout
  in
  let my_printf : string -> str t list -> unit t = fun fmt args ->
    (* The function `call` is like `exec` but operates on `str t` values
       instead of just OCaml strings: *)
    call (str "printf" :: str fmt :: args) in
  (* The operator `=$=` is `str t` equality, it returns a `bool t` that
     we can use with `if_seq`: *)
  if_seq Str.(username_one_way =$= username_the_other_way)
     ~t:[
        my_printf "Username matches: `%s`\\n" [username_one_way];
     ]
     ~e:[
        my_printf "Usernames do not match: `%s` Vs `%s`\\n"
          [username_one_way; username_the_other_way];
     ]
;;
val c : unit t

utop> Sys.command (Genspio.Compile.to_one_liner c);;
Username matches: `smondet`
- : int = 0
```

### Important Modules

- `Genspio.EDSL` provides the Embedded Domain Specific Language API to build
  shell script expressions (there is also a lower-level, *not recommended*,
  `Genspio.EDSL_v0` API).
- `Genspio.Compile` has the 3 “compilers” provided by the library:
    - The pretty printer outputs `'a EDSL.t` values as expressions of a
      lisp-like pseudo-language.
    - The default “`To_posix`” compiler generates POSIX-compliant shell
      scripts (with the option of avoiding new-lines).<br/>
      ⤷ Note that MacOSX's default `bash` version is buggy and has been
      witnessed to choke on generated POSIX-valid scripts.
    - The newer “`To_slow_flow`” compiler generates POSIX shell scripts which
      are much simpler, hence more portable across shell implementations, but
      use (*a lot of*) temporary files and are generally slower.
- `Genspio.Transform` implements code transformations:
    - The module `Visitor` provides an extensible AST visitor.
    - The module `Constant_propagation` does some basic constant propagation
      (using the visitor).


### More Examples

- There are many examples in
  [`src/examples/small.ml`](https://github.com/hammerlab/genspio/blob/master/src/examples/small.ml)
  which are used to generate the usage examples documentation webpage.
- The file
  [`src/examples/service_composer.ml`](https://github.com/hammerlab/genspio/blob/master/src/examples/service_composer.ml)
  is the code generator for the “COSC” project (Github:
  [`smondet/cosc`](https://github.com/smondet/cosc)), a family of scripts which
  manage long-running processes in a GNU-Screen session.
- The file
  [`src/examples/downloader.ml`](https://github.com/hammerlab/genspio/blob/master/src/examples/downloader.ml)
  contains another big example: a script that downloads and unpacks archives
  from URLs.
- The file
  [`src/examples/vm_tester.ml`](https://github.com/hammerlab/genspio/blob/master/src/examples/vm_tester.ml)
  is a *“Makefile + scripts”* generator to setup Qemu virtual machines, they can
  be for instance used to run the tests on more exotic platforms.
- The project
  [`hammerlab/secotrec`](https://github.com/hammerlab/secotrec) is a real-world,
  larger-scale use of Genspio (uses Genspio version 0.0.0).

### Additional Documentation

From here, one can explore:

- Some implementation [notes](./doc/exec-return-issue.md).
- More [information](./doc/extra-testing.md) on testing, e.g. on more exotic
  operating systems.
- The module `Genspio.EDSL_v0` is an older version of the API, which can still
  be useful as it is lower-level: it gives full access to the two “string-like”
  types, byte-arrays and C-strings while of course becoming more cumbersome to
  use.
<!--TOSLOWFLOW-->
<!--TRANSFORM-->
<!--SERCOEX-->

Testing
-------

To run the tests you also need `make` and there is an additional dependency on
the `uri` library, see:

    genspio_test=_build/default/src/test/main.exe
    jbuilder build $genspio_test
    $genspio_test --help


Try this:

    $genspio_test --important-shells bash,dash /tmp/gtests/
    cd /tmp/gtests/
    make run-all # Attempts to run all the tests on all the shells
    make check   # Checks that all the tests for the important ones succeeded

You can generate a markdown report with `make report` and check `report.md`.

Some failures are expected with not-really-POSIX or buggy shells like
[KSH93](https://en.wikipedia.org/wiki/Korn_shell), or on some corner cases
cf. [`#35`](https://github.com/hammerlab/genspio/issues/35).

You can check failures in the `<shell-test>/failures.md` files, see for instance
`ksh-StdML/failures.md` for the failures of the “KSH with standard Genspio
compilation to multi-line scripts” (similarly there are
`<shell-test>/successes.md` files).


Building The Documentation
--------------------------

To build the documentation one needs `pandoc` and `caml2html`:

    sh tools/build-doc.sh

The build of the whole website, including the
[web-based demo](https://smondet.gitlab.io/genspio-doc/demo/master/index.html),
happens in a different repository:
<https://gitlab.com/smondet/genspio-doc>.

License
-------

It's [Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0).
