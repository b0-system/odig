## v0.11

- Depend on ppxlib instead of (now deprecated) ppx\_core, ppx\_driver and
  ppx\_metaquot.

## v0.10

- Made `ppx_type_conv` accept the `ppx_deriving` syntax for derivers arguments,
  which makes it easier for for people to switch from `ppx_deriving` to
  `ppx_type_conv`.

## v0.9

## 113.43.00

- Use the new context-free API

- Change a behavior in ppx\_type\_conv: attributes inside the type
  definition such as `@default` are not removed. This is not really a
  big deal as we still check that they are used. We could restore this
  bevavior with a full pass at the end to remove used attributes.

## 113.33.01

- Make the ppx\_deriving glue more resilient to small changes in
  ppx\_deriving. Related to whitequark/ppx_deriving#94

## 113.24.00

- Kill the nonrec rewrite done by typerep. It is no longer needed since
  4.02.2, we kept it only for compatibility with the camlp4 code.

- Cleanup in type\_conv: remove `Type_conv.Generator_result.make_at_the_end`,
  which was a hack to remove warnings. We can do it better now, and because this
  is only for signatures, the code generation issue what we had in
  simplify-type-conv-ignore-unused-warning doesn't apply.

- Update to follow `Ppx_core` evolution.
