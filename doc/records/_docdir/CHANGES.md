## v0.8.0

*2017-01-03*

### Breaking changes

- Remove `Record.format` (#32) - was previously deprecated.
  The alternative is to invoke `yojson` by hand.

### Deprecated functions

- Deprecate `Type.list` and `Type.product_2` (#30).
  The alternative is to write converter functions by hand or by using
  `ppx_deriving_yojson`.

### New features

- Add `Type.int{32,64}` (#28)

### Build system

- Use docker in Travis (#31)
- Add `descr` file for `topkg opam`.
- Add `org:cryptosense` tag.
- Add merlin configuration (#29).

## v0.7.0

*2016-09-21*

- Support OCaml 4.04
- Build using topkg:
  - Autogenerate API docs
  - Build example
- Add `Record.Type.result` for `result` values
- Deprecate `Record.format`

## v0.6.0

*2016-08-01*

(This release contains breaking changes, indicated by a star)

- Remove deprecated functions
* `Record.format` now outputs a string based on `Yojson.Safe`.
* Update `of_yojson` function to use `Result` to be compatible with
  `ppx_deriving_yojson >= 3.0` (#18). The `of_string` parameter of `make_string`
  follows the same convention.
- Compile with debugging information (#17).
- Install library with profiling information (#19).

## v0.5.0

*2016-01-27*

(This release contains breaking changes, indicated by a star)

- Install .cmxs, .cmt, .cmti, .mli files (#10)
- Move `declare`, `field`, `seal`, `make`, `layout_name` and
  `layout_id` to a `Record.Unsafe` submodule (#9)
- Move `Polid` to `Record.Polid`
- Require ocaml >= 4.02.0 for deprecation warnings
* Target `Yojson.Safe` (#15):
  - a compatibility layer is provided in the `Record` module.
  - users should migrate to the new functions in the sub modules that are
    expressed in terms of `Safe`. The `Basic` interface will go away.
  * The `Safe` variant, already in a submodule, switches to `Safe`.

## v0.4.0

*2016-01-04*

- Make the type of 'content' abstract (#7)
- Add a Safe sub-module for type-safe creation of layouts (#8),
  thanks Jeremy Yallop!

## v0.3.1

*2015-12-01*

- Compile with `-safe-string` (#6)
- Add a bytecode-only target

## v0.3.0

*2015-08-31*

- Delete embedded .travis-opam.sh (#2)
- Add `Record.declare0` (#4)
- Add `Type.view` (#5)

## v0.2.0

*2015-08-17*

- Sort OPAM fields
- Add ocaml-version bound
- Support OCaml 4.00
- Bisect is not necessary to run the test suite
- Add `Record.declare{1,2,3,4}` to build fixed-size layouts
- Add `Record.layout_type` to use layout as types
- Add 'yojson' dependency to the META file (#3), thanks Jeremy Yallop!

## v0.1.0

*2015-08-03*

- Initial release
