# v0.2.0 (2018-12-23)

## Breaking changes

- _Potentially breaking change:_ `Traversable.S0_container` now
  contains `module Elt : Equal.S`, and constrains `type elt` to be
  equal to `Elt.t`.  This reflects the situation in
  `Basic_container0`, and shouldn't break any code using
  `Make_container0`, but may cause custom-built modules to fail to
  type-check.
- `T_container.any`'s arguments have swapped order, to be more
  in line with `Core` idioms.

## New features

- Add `Traversable.Chain0`, a functor for combining two
  `S0_container` instances together for nested traversal.
- Add `T_fn.disj` to go with `T_fn.conj`.
- Add `Filter_mappable`, which generalises `List.filter_map`.
- Add `tee_m` to monad extensions.  This is a small wrapper over
  `f x >>| fun () -> x` that allows unit-returning monadic
  side-effects to be treated as part of a monad pipeline.
- Add `T_or_error`: monad extensions for `Core.Or_error`.
- `one` and `two` are now implemented on `T_container`, not just
  `T_list`.  The errors are slightly less precise, but otherwise
  nothing has changed.
- Add `T_container.at_most_one` to complement `one` and `two`.
- Add `Monad.To_mappable`, which makes sure that monads can be
  converted to mappables.
- Add `T_container.all` and `none`, to complement `any`.

## Other

- Improve API documentation.

# v0.1.3 (2018-12-13)

- Fix incorrect module name (was `Lib`, not `Travesty`).
- Restrict to OCaml v4.06+ (this was the case in the final v0.1.2
  OPAM release, but not upstream).

# v0.1.2 (2018-12-12)

- Improve API documentation.
- Move functors and concrete modules out of `Intf` files.
- Generally rationalise the interface ready for a public release.
- Add various container modules from `act`: `Singleton`, `T_list`, and
  `T_option`.

# v0.1.1 (2018-12-10)

- Move API documentation, in an attempt to get `dune-release` to work.

# v0.1 (2018-12-10)

- Initial release.
- Existing functionality migrated from `act`'s utils directory.
