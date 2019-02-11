## 113.43.00

- We currently reject code which contains attribute on constructor inside
  polymorphic variant types definition.
  The reason is that while there is a dedicated place for them in the AST, the
  surface syntax didn't allow one to write such attributes.

  This won't be true anymore once we switch to 4.03 as documentation comments
  present in these locations get turned into attributes.

- accept attributes on object types fields.

- Make all ppx rewriters context free. We currently have an API for
  context free extension expanders but other kind of transformations
  still require a full AST traversal, even though they are all local
  transformations.

  This features adds the necessary bits to make it possible to merge all
  the transformations in one pass. This both improve speed and
  semantic. Speed as we do less passes, and semantic as the resulting
  AST is completely independent of the order in which transformations
  are listed in jbuild files.

  Passes before this feature:

      $ ppx.exe -print-passes
      <builtin:freshen-and-collect-attributes>
      <bultin:context-free>
      type_conv
      custom_printf
      expect_test
      fail
      js_style
      pipebang
      <builtin:check-unused-attributes>
      <builtin:check-unused-extensions>

  After:

      <builtin:freshen-and-collect-attributes>
      <bultin:context-free>
      js_style
      <builtin:check-unused-attributes>
      <builtin:check-unused-extensions>

  The resulting driver is about twice faster, which might help
  compilation speed.

## 113.24.00

- Kill the nonrec rewrite done by typerep. It is no longer needed since
  4.02.2, we kept it only for compatibility with the camlp4 code.

- Merlin uses `@merlin.* ...` attributes in different places. Which ppx\_driver
  reports as unused.

  Introduce the concept of reserved namespaces.
  When one declares the namespace "foo" as reserved then:
    - `foo.*` will never get reported as unused
    - it is impossible to `Attribute.declare "foo.*"`

  Mark the "merlin" namespace as reserved by default.

- Don't print:

    Extension `foo' was not translated.
    Hint: Did you mean foo?

- OCaml makes no distinctions between "foo" and
  `{whatever|foo|whatever}`. The delimiter choice is simply left to the
  user.

  Do the same in our ppx rewriters: i.e. wherever we accept "foo", also
  accept {whatever|foo|whatever}.

- Avoid stupid hints like this one:

    Attribute `default' was not used.
    Hint: `default' is available for label declarations but is used here
    in the context of a label declaration. Did you put it at the wrong
    level?

- Update the API for the common case of extension point expanders.

  Make it simpler to define ppx rewriters that locally expand extension
  points, which is the majority of our non-type-conv rewriters.

  Such expanders are run inside the same `Ast_traverse.map` in a
  top-down manner which:

  - probably improve speed
  - help with rewriters that capture a pretty-print of their payload
  - help with rewriter that interpret some extension points in a special
    way inside their payload

- Fix the order in which errors are reported by ppx rewriters.
  Make them be reported in the same order as they appear.

- Mark attributes as handled inside explicitly dropped pieces of code.

  So that a `@@deriving` inside a let%test dropped by
  `ppx_inline_test_drop` doesn't cause a failure.
