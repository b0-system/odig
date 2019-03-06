v1.4.0 2017-11-05
-----------------

* Fix build on OCaml 4.06 (and -safe-string)

v1.3.4 2017-06-19
-----------------

* Documentation fixes in odoc comments.
* Refine opam constraints on cstruct.
* Rename LICENSE file to markdown to be topkg compliant.
* Add topkg-jbuilder integration.

v1.3.3 2017-05-23
-----------------

* Port to [Jbuilder](https://github.com/janestreet/jbuilder).
* Modernise Travis CI matrix.

v1.3.2 2014-12-19
-----------------

* Remove the dependency to dolog

v1.3.1 2014-10-16
------------------

* Add `Mstruct.to_cstruct`, `Mstruct.of_cstruct` and `Mstruct.with_mstruct`
* Fix `Mstruct.to_bigarray` to return the current window instead of the whole bigarray

v1.3.0 2014-02-10
----------------

* Remove debugging message in hot path
* Remove duplicated bound checks (which were already done by cstruct)
* Remove `Mstruct.dump`, replace it by `Mstruct.{hexdump,hexdump_to_buffer,debug}`
  to share the same API as `Cstruct`

v1.2.0 2014-01-04
-----------------

* Export `Mstruct.index`
* Add `Mstruct.get_le_uint16` and `Mstruct.set_le_uint16`
* Add `Mstruct.get_le_uint32` and `Mstruct.set_le_uint32`
* Add `Mstruct.get_le_uint64` and `Mstruct.set_le_uint64`
* Rename `Mstruct.get_uint16` to `Mstruct.get_be_uint16`
* Rename `Mstruct.get_uint32` to `Mstruct.get_be_uint32`
* Rename `Mstruct.get_uint64` to `Mstruct.get_be_uint64`
* Rename `Mstruct.set_uint16` to `Mstruct.set_be_uint16`
* Rename `Mstruct.set_uint32` to `Mstruct.set_be_uint32`
* Rename `Mstruct.set_uint64` to `Mstruct.set_be_uint64`

v1.1.0 2014-01-03
-----------------

* Add `Mstruct.to_string` and `Mstruct.of_string`

v1.0.0 2014-01-02
-----------------

* Add `Mstruct.offset`
* Add `Mstruct.sub`
* Add `Mstruct.clone`
* Add `Mstruct.shift`
* Add `Mstruct.get_delim` to scan for a given character in a window buffer

v0.9.0 2013-19-12
-----------------

* Initial release
