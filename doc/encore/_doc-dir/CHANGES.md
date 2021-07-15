### v0.8 2021-03-17 Paris (France)

- Upgrade to ocamlformat.0.17.0 (@dinosaure, #31)
- Fix stack-overflow on large objects (@dinosaure, @zshipko, #31)
- Remove conflict with `git.2.1.3` (@dinosaure, @kit-ty-kate, fd0ef8c)

### v0.7 2020-09-04 Paris (France)

- Add a pure label on some encoders to help the `choose` operator
  to not grow the internal stack (#27, @dinosaure)
- Use an unlimited internal buffer with a `dequeue` to encode an
  object (#28, @dinosaure)

### v0.6 2020-07-03 Paris (France)

__breaking changes__
- Defunctorize the core of the library (#24)
- Improve the core with `ocaml-git` (#26)
- Add documentation (#26)

### v0.5 2020-06-29 Paris (France)

- Move to `bigarray-overlap` to be compatible with > MirageOS 3.6 and `js_of_ocaml` (#23)
- Update to `angstron.0.14.0` (@sternenseemann, #22)

### v0.4 2019-11-11 Paris (France)

- Move to `bigarray-compat` to be compatible with > MirageOS 3.6 (#19, @dinosaure, @TheLortex)
- Add `bigstringaf` as a dependency (#18, @andreas, @dinosaure)

### v0.3 2019-05-01 Paris (France)

- Fix OPAM file about how to ask to `dune` to build `encore` (@kit-ty-kate)
- Use `ke` as common implementation of ring-buffer
- Support of 4.07.0 in Travis CI
- Provide a C stubs to know if a bigarray overlaps an other
 * Compilation fixed with MirageOS (@hannesm)
- Tests about printer, parsers and combinators
- Add `from` function to let user to allocate internal buffer
- Use rev_iter instead fold and rev on internal queue
- Delete tag argument on bijection objects to be more usable
- Delete dependency of ocplib-endian and use bigstringaf instead
- Use angstrom.0.10.0 (@andreas)

### v0.2 2018-10-15 Paris (France)

- _Dunify_ project

### v0.1 2018-03-31 Paris (France)

- First release
