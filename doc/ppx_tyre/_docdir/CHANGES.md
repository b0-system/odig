## v0.4.1 - 2018-09-04

- Fix multi-group top level regexp for `ppx_tyre`.

## v0.4.0 - 2018-08-20

- Switched to internal regexp parser.
- Added syntax extension for `tyre` (Gabriel Radanne).
- Fixed type of captures under alternatives for `%pcre`.
- Better error reporting, including locations.
- The PPX now declares its runtime libraries.

## v0.3.2 - 2018-03-01

- Prepare for re 1.7.2.

## v0.3.1 - 2017-08-21

- Fix accidental shadowing of open from another interface-less module using
  `ppx_regexp`.
- Support binding of group 0 and the universal pattern.
- Switch to `ppx_tools_versioned`. This provides support for 4.02.3 in the
  main branch.

## v0.3.0 - 2017-06-04

- Initial release for OCaml 4.03.0 and 4.04.1.

## v0.2.0 - 2017-06-04

- Initial release for OCaml 4.02.3.
