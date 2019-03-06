# Linkage - easier plugin loading for OCaml

*Linkage* provides an easy way for OCaml programs to dynamically load
 plugins. (Internally, Linkage uses OCaml's standard `Dynlink` module).

You specify the type your plugin provides by extending Linkage's
`plugin` type. Here, we're defining a plugin which provides a single
`string -> int` function:

    type Linkage.plugin += MyPlugin of (int -> string)

The plugin is an ordinary OCaml module, which ends with a call to
`Linkage.provide`:

    let f = ...
    ...
    Linkage.provide (MyPlugin f)

The main application then uses `Linkage.load` to load the plugin (here
with only minimal error handling):

    let f =
      match Linkage.load "plugins/plugin.cma" with
      | Ok (MyPlugin f) -> f
      | e -> Linkage.raise_error e

The plugin type (the `Linkage.plugin +=` line) should be in a module
by itself, since both the main application and the plugin depend on
it. Only the main application and not the plugin should link against
this module, to ensure that there's only one copy. If using
OCamlbuild, you do this by omitting it from the plugin's `.mllib`
file.

There are some working examples in the `examples/` directory.
