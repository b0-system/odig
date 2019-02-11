0.6 2018-09-05
--------------

- New `Ft` module to support FreeType fonts.  This is enabled if the
  package `conf-freetype` is installed.  On the C side, the exported
  header file `cairo_ocaml.h` defines the macro `OCAML_CAIRO_HAS_FT`
  when the Cairo bindings were compiled with TrueType support.
- New package `Cairo2-pango` providing the module `Cairo_pango`.
- Remove labels that were not bringing a clear benefit.  With Dune
  default behavior, users will feel compelled to write labels which
  was cluttering the code with the previous interface.  With Merlin,
  it is now possible to have the documentation of a function under the
  cursor displayed with a simple keystroke which should alleviate
  having slightly less documentation in the types.
- Improve the documentation.
- Use Dune (not the former Jbuilder) to compile.
