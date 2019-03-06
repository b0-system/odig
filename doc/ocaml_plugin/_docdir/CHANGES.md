## v0.11

- Rework the API of Ocaml_plugin to use the new stdless idiom. (Keep the old one
  as deprecated)
  Also, the following modules were renamed:
  + `Ocaml_plugin.Std.Ocaml_dynloader` is now accessible at `Ocaml_plugin.Dynloader`
  + `Ocaml_plugin.Std.Ocaml_compiler` is now accessible at `Ocaml_plugin.Compiler`

## 113.43.00

- In Ocaml_plugin, drop `t_of_sexp` on an unstable type not meant to expose this.
  This was most probably added either temporarily or maybe by mistake.

- Allow the specification of the permissions with which to create
  `in_dir` (the directory where ocaml_plugin does its compilation).

- If a persistent compiler archive is modified, ocaml\_plugin will probably fail at
  compiling. Make it more robust by considering the archive invalid instead.
  This can easily happen when deleting a bunch of cmi/cmx/exe recursively and inadvertently
  messing up the ocaml_plugin archive.

  On the way, I simplify things by passing more information from ocaml\_embed\_compiler (at
  compile time) to ocaml_plugin (at runtime) without having to look in the archive.

## 113.33.00

- Improve the check plugin command that comes with ocaml-plugin:

  1) Improve documentation, add `readme` to include more info about what is being
  checked exactly.

  2) Avoid the switch `-code-style _` for application that have made a choice of
  code style statically.  Having the swtich available at runtime is just
  confusing, since only 1 style is going to work anyway.

## 113.24.02

- Added an ocamlbuild plugin to ease the creation of embed programs

## 113.24.00

- Switch to ppx.

- Allow ppx-style code to be loaded by plugin-applications build using ocaml\_plugin.

- Follow Core & Async evolution.

## 113.00.00

- Made `Ocaml_plugin.Plugin_cache.Config.t` stable.

## 112.35.00

- In `copy_source_files_to_working_dir`, exclude files that start with
  a dot.

    emacs creates temporary files that cannot be read with names like
    `.#foo.ml`, and attempting to copy those causes this function to
    fail.

## 112.24.00

Minor update: follow Async evolution.

## 112.17.00

- Fixed spurious `interface mismatch` error when a plugin cache is
  shared by incompatible compilers.

  When a plugin cache directory is used by several executables with
  incompatible cmis/compilers, and the cache config option
  `try_old_cache_with_new_exec` is set to true, this could lead to the
  following error:

  ```ocaml
  Plugin failed: (ocaml_dynloader.ml.Dynlink_error "interface mismatch")
  ```

  This feature fixes this.

  Since it modifies some record, for later changes it seems easier and
  more conservative to allow field additions without breaking older
  version.  Thus we allow extra fields in persisted records.

  ```ocaml
  let t_of_sexp = Sexp.of_sexp_allow_extra_fields t_of_sexp
  ```

  New executables can read both old and new caches, but old
  executables will either blow away new caches, or if the config says
  the cache is read-only, fail.

  Take the chance to modernize part of the code.
- Switched tests to unified tests.
- Fixed bugs dealing with paths with spaces in them.
- Check that plugins have the expected type before running them rather
  than after, which is what one would expect.

  Also check that runtime and compile types match in
  `check_ocaml_src_files` and
  `compile_ocaml_src_files_into_cmxs_file`.

## 112.06.00

- Stopped using the `~exclusive` with `Reader`, because it doesn't work
  on read-only file systems.

    It's not even needed because these files are written atomically.

- Used a generative functor in the generated code, so the user code can
  apply generative functors at toplevel, or unpack first class modules
  that contain type components.
- Fixed bug when mli file references something defined only in
  another ml.
- Made it possible to compile a plugin in one process, and dynload the
  compiled `cmxs` file without starting async in another process.

    This was done with two new APIs in `Ocaml_dynloader.S`:

        val compile_ocaml_src_files_into_cmxs_file
          : dynloader
          -> string list
          -> output_file:string
          -> unit Deferred.Or_error.t

        val blocking_load_cmxs_file : string -> t Or_error.t

- Allowed plugins to optionally have a shebang line.
- Made `Ocaml_dynloader.find_dependencies` also support files with
  shebang lines.

## 112.01.00

- Changed to not use `rm -r` when it is expected to remove one file.

## 111.28.00

- Fixed a bug in tests that could leave the repository in a state where
  running the tests would fail.

    The bug happened if the tests were interrupted after creating
    read-only directories but before cleaning then up.

## 111.25.00

- ignore more warnings by default

## 111.21.00

- Fixed a bug in `ocaml_embed_compiler` on 32-bit machines.

    `ocaml_embed_compiler` tries to read the full contents of the file as
    a string, but the string might be too big on 32bits:

    https://github.com/ocaml/opam-repository/pull/2062#issuecomment-43045491

## 111.11.00

- Added a tag to exceptions coming from the toplevel execution of
  plugins so that we do not confuse them with exceptions coming from
  the library.

  Also, added a function to check a plugin without executing it.  And
  captured the common pattern of checking the compilation of a plugin
  in a `Command.t` offered in the library.

## 111.08.00

- Use `ocamldep` to generate the dependencies of an `.ml` file, if
  requested.

    Added a function to find the dependencies of a module, but did not
    change the existing behavior and interface of the library if one
    does not choose to use this functionality.

## 110.01.00

- Added `cmi`'s so that plugins can use `lazy`, recursive modules, and
  objects.

## 109.53.00

Bump version number

## 109.45.00

- Made executables link without error even if no archive is embedded
  in them.

  This is often the desired behavior (for inline tests of libraries
  using transitively ocaml-plugin for instance).

## 109.41.00

- Added option `-strict-sequence`, which is set to `true` by default.

## 109.35.00

- Changed the execution of plugin's toplevel to run in async instead
  of `In_thread.run`, unless a config parameter says otherwise.

## 109.32.00

- Fixed the slow and memory-consuming compilation of > 100MB `.c` files generated by `ocaml_embed_compiler`.

  This was done by having them contain one big string instead of one big
  array.

- Added more unused-value warnings in plugins.

  If { `Ui` , `M` } are the modules that constitute a given plugin of
  expected module type `S`, then previously we generated a file like:

  ```ocaml
  module Ui : sig
    ...
  end = struct
    ...
  end

  module M : sig
    ...
  end = struct
    ...
  end

  let () = ##register (M : S)
  ```

  Doing that, we did not get unused variables:

  1. for the toplevel of `Ui` if `Ui` does not have a `mli`.
  2. for unused values of `Ui` and `M` if they have an `mli` exporting them.

  OCaml plugin now allows one to get these warnings.  Since (2) is
  rather annoying for utils kind of file, this comes only if a config
  flag is enabled.

## 109.31.00

- Fixed OCaml Plugin on CentOS 5 -- it had problems because the generated c files did not end with a newline.
- Finished the transition from `Command_deprecated` to `Command`.

## 109.30.00

- Support for Mac OSX

  Removed the dependency of `ocaml-plugin` on `objcopy` and `/proc`.

## 109.20.00

- Removed a test that (rarely) failed nondeterministically.
