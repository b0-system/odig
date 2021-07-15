## v0.1.1 2017-01-30

* Include both `lib` and `share` in pkg-config path.
* Use `mirage-xen-ocaml` for Xen pkg-config.
* Add include dirs to `cmxs` linking.

## v0.1.0 2016-11-03

* Fix header discovery and its interaction with multi-lib.
* `pkg-config()` can query a subset of `--cflags`, `--libs` or `--static`.
* Rename `ccopt_flags`/`cclib_flags` to `ccopt`/`cclib`; add `ldopt`.
* Detect old `ocamlbuild` and add 0.9.3-compatible `ccopt`/`cclib` flags.
* `mirage` combinator returns a single `install`, not a list.
* Topkg 0.8.x.

## v0.0.2 2016-10-27

* Fix the wrong dependencies in META.

## v0.0.1 2016-10-26

First release. 
