ocaml_plugin - a wrapper around dynlink for OCaml
=================================================

ocaml_plugin is a library meant to make dynlink more easier. It offers
a high-level kind of api where you can get a first class module out of
a few ml source files, while handling the compilation of the files
automatically.

Installation via opam
---------------------

ocaml_plugin can be installed via [opam](http://opam.ocamlpro.com/):

    $ opam install ocaml_plugin

Usage
-----

A simple example is provided under the [hello_world]() directory. A
recommended set-up usually involves 2 steps in the code
- defining the interface of the plugin, as well as an univ value
- applying a functor to get a customized plugin loader plugin_intf.ml:

```ocaml
module type S = sig
  val message : string
end
let univ_constr =
  (Univ_constr.create "Plugin_intf.S" sexp_of_opaque : (module S) Univ_constr.t)
```

run.ml:

```ocaml
module Plugin = Compiler.Make(struct
  type t = (module Plugin_intf.S)
  let t_repr = "Plugin_intf.S"
  let univ_constr = Plugin_intf.univ_constr
  let univ_constr_repr = "Plugin_intf.univ_constr"
end)
```

```ocaml
Plugin.load_ocaml_src_files (files:string list) >>= function
| Error err ->
  Printf.eprintf "loading failed:\n%s%!" (Error.to_string_hum err)
| Ok plugin ->
  let module M = (val plugin : Plugin_intf.S) in
  Printf.printf "loaded plugin's message : %S\n%!" M.message
```

Standalone executable
---------------------

It is possible to embed the compiler in an executable such that a full
ocaml environment is not mandatory to actually load plugins. The way
it is done in this version of the library is by embedding
`ocamlopt.opt` and some `cmi files` inside a tgz archive that is
getting amended at the end of the exec. At runtime, this archive is
extracted into a temporary directory where the compilation will
happen. To create this standalone version of an exec
(exec+ocamlopt+cmi), you would typically run something like:

    $ ../bin/ocaml_embed_compiler.exe -exe ./run.exe -cc $(which ocamlopt) \
         dsl.cmi ../lib/ocaml_plugin.cmi $(ocamlopt -where)/pervasives.cmi \
         -o ./run-standalone.exe

`opam` will install this executable as `ocaml-embed-compiler`.
