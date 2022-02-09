hxd - HeX Dump in OCaml
-----------------------

`hxd` is a little program to output a hexdump of a /<stdin>/ or a binary file.
The main difference with `xxd` is to color outputs to be more fancy to read.
Then, it provides a way to generate a Caml code which is a dump of inputs. This project
was mostly done to be able to integrate dump of some sources (like `ngrep`) to an
OCaml code - like dump of a smart flow (git protocol) to be able to write easily
regression tests with small examples.

For a long time, I worked on several formats and protocols and it always a pain to
read dump of something which is only machine-comprehensible. As a MirageOS project,
core library is agnostic to the system.

`hxd` provides several ways to dump a source:
* `lib/` is the core library which needs only `bigarray`
* `lib_lwt/` is a library which can be used in a LWT context
* `lib_lwt_unix/` uses `Lwt_io.channel`
* `lib_string/` needs only OCaml and `bigarray` and provides a pretty-printer function
* `lib_unix/` uses `unix` module

Examples
--------

With:

```sh
$ hxd.xxd --color=always dump
```

![example.png](https://raw.githubusercontent.com/dinosaure/hxd/master/img/example.png)

Or a Caml output with `$ hxd.caml --with-comments dump`:

```ocaml
[
; "\x78\x01\x4b\xca\xc9\x4f\x52\x30\x35\x60\xd0\x48\xad\x48\x4d\x2e" (* x.K..OR05`.H.HM. *)
; "\x2d\x49\x4c\xca\x49\xe5\x52\xd0\xc8\x4b\xcc\x4d\x55\x48\x2b\xad" (* -IL.I.R..K.MUH+. *)
; "\xaa\xd2\x04\x72\x72\x32\x93\x8a\x12\x8b\x32\x53\x8b\x15\x32\x2a" (* ...rr2....2S..2. *)
; "\x52\x14\x92\x8b\xf2\xcb\x93\x12\x8b\x34\x35\x01\x2c\x48\x13\x4f" (* R........45.,H.O *)
]
```

Repository has an OPAM package, so:

```
$ opam pin add hxd https://github.com/dinosaure/hxd.git
```

is enough to get this fabulous binary.
