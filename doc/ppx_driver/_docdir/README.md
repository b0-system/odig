ppx_driver - driver for AST transformers
========================================

A driver is an executable created from a set of OCaml AST transformers
linked together with a command line frontend.

The aim is to provide a tool that can be used to:

- easily view the pre-processed version of a file, no need to
  construct a complex command line: `ppx file.ml` will do
- use a single executable to run several transformations: no need to
  fork many times just for pre-processing
- improved errors for misspelled/misplaced attributes and extension
  points

## Using Ppx\_driver based rewriters

The recommended way to use rewriters based on Ppx\_driver is through
[jbuilder](https://github.com/janestreet/jbuilder). All you need to is
add this line to your `(library ...)` or `(executables ...)` stanza:

```scheme
(preprocess (pps (rewriter1 rewriter2 ... ppx_driver.runner)))
```

jbuilder will automatically build a static driver including all these
rewriters. Note the `ppx_driver.runner` at the end of the list, it
will still work if you don't put but some specific features of
ppx_driver won't be available.

If you are not using jbuilder, you can build a custom driver yourself using
ocamlfind.

These methods are described in the following sections.

## Creating a new Ppx\_driver based rewriter

If using jbuilder, you can just use the following jbuild file:

```scheme
(library
 ((name        my_ppx)
  (public_name my_ppx)
  (kind ppx_rewriter)
  (libraries (ppx_core ppx_driver))
  (ppx_runtime_libraries (<runtime dependencies if any>))
  (preprocess (pps (ppx_metaquot)))))
```

`(kind ppx_driver)` has two effects:
1. it links the library with `-linkall`. Since plugins register
   themselves with the Ppx\_driver library by doing a toplevel side
   effect, you need to be sure they are linked in the static driver to
   be taken into accound
2. it instructs jbuilder to produce a special META file that is
   compatible with the various ways of using ppx rewriters, i.e. for
   people not using jbuilder.

## Building a custom driver using ocamlfind

To build a custom driver using ocamlfind, simply link all the AST
transformers together with the `ppx_driver.runner` package at the end:

    ocamlfind ocamlopt -predicates ppx_driver -o ppx -linkpkg \
      -package ppx_sexp_conv -package ppx_bin_prot \
      -package ppx_driver_runner

Normally, ppx\_driver based rewriters should be build with the
approriate `-linkall` option on individual libraries. If one is
missing this option, the code rewriter might not get linked in. If
this is the case, a workaround is to pass `-linkall` when linking the
custom driver.

## The driver as a command line tool

```
$ ppx -help
ppx.exe [extra_args] [<files>]
  -loc-filename <string>      File name to use in locations
  -reserve-namespace <string> Mark the given namespace as reserved
  -no-check                   Disable checks (unsafe)
  -apply <names>              Apply these transformations in order (comma-separated list)
  -dont-apply <names>         Exclude these transformations
  -no-merge                   Do not merge context free transformations (better for debugging rewriters)
  -as-ppx                     Run as a -ppx rewriter (must be the first argument)
  --as-ppx                    Same as -as-ppx
  -as-pp                      Shorthand for: -dump-ast -embed-errors
  --as-pp                     Same as -as-pp
  -o <filename>               Output file (use '-' for stdout)
  -                           Read input from stdin
  -dump-ast                   Dump the marshaled ast to the output file instead of pretty-printing it
  --dump-ast                  Same as -dump-ast
  -dparsetree                 Print the parsetree (same as ocamlc -dparsetree)
  -embed-errors               Embed errors in the output AST (default: true when -dump-ast, false otherwise)
  -null                       Produce no output, except for errors
  -impl <file>                Treat the input as a .ml file
  --impl <file>               Same as -impl
  -intf <file>                Treat the input as a .mli file
  --intf <file>               Same as -intf
  -debug-attribute-drop       Debug attribute dropping
  -print-transformations      Print linked-in code transformations, in the order they are applied
  -print-passes               Print the actual passes over the whole AST in the order they are applied
  -ite-check                  Enforce that "complex" if branches are delimited (disabled if -pp is given)
  -pp <command>               Pipe sources through preprocessor <command> (incompatible with -as-ppx)
  -reconcile                  (WIP) Pretty print the output using a mix of the input source and the generated code
  -reconcile-with-comments    (WIP) same as -reconcile but uses comments to enclose the generated code
  -no-color                   Don't use colors when printing errors
  -diff-cmd                   Diff command when using code expectations
  -pretty                     Instruct code generators to improve the prettiness of the generated code
  -styler                     Code styler
  -help                       Display this list of options
  --help                      Display this list of options
```

When passed a file as argument, a ppx driver will pretty-print the
code transformed by all its built-in AST transformers. This gives a
convenient way of seeing the code generated for a given
attribute/extension.

A driver can simply be used as the argument of the `-pp` option of the
OCaml compiler, or as the argument of the `-ppx` option by passing
`-as-ppx` as first argument:

```
$ ocamlc -c -pp "ppx -as-pp" file.ml
$ ocamlc -c -ppx "ppx -as-ppx" file.ml
```

## ppx_driver rewriters as findlib libraries

Note: if using jbuilder, you do not need to read this as jbuilder
already does all the right things for you.

In normal operation, Ppx\_driver rewriters are packaged as findlib
libraries. When using jbuilder everything is simple as preprocessors
and normal dependencies are separated. However historically, people
have been specifying both preprocessors and normal library
dependencies together. Even worse, many build system still don't use a
static driver and call out to multiple ppx commands to preprocess a
single file, which slow downs compilation a lot.

In order for all these different methods to work properly, you need a
peculiar META file. The rules are explained below.

It is recommended to split the findlib package into two:
1. one for the main library, which almost assume it is just a normal
   library
2. another sub-package one for:
   - allowing to mix preprocessors and normal dependencies
   - the method of calling one executable per rewriter

In the rest we'll assume we are writing a META file for a `ppx_foo`
rewriter, that itself uses the `ppx_driver`, `ppx_core` and `re`
libraries, and produce code using `ppx_foo.runtime-lib`.

We want the META file to support all of these:
1. mix normal dependencies and preprocessors, using one executable per
   rewriter:

   ```
   ocamlfind ocamlc -package ppx_foo -c toto.ml
   ```
2. mix normal dependencies and preprocessors, using a single ppx
   driver:

   ```
   $ ocamlfind ocamlc -package ppx_foo -predicates custom_ppx \
      -ppx ./custom-driver.exe -c toto.ml
   ```
3. build a custom driver:

   ```
   $ ocamlfind ocamlc -linkpkg -package ppx_foo -predicates ppx_driver \
      -o custom-driver.exe
   ```
4. build systems properly specifying preprocessors as such, separated
   from normal dependencies, as jbuilder does

Since preprocessors and normal dependencies are always specified
separately in jbuild files, jbuilder just always set the `ppx_driver`
predicates.

In the end the META file should look like this:

```shell
# Standard package, expect it assumes that the "ppx_driver" predicate
# is set
version                     = "42.0"
description                 = "interprets [%foo ...] extensions"
requires(ppx_driver)        = "ppx_core ppx_driver re"
archives(ppx_driver,byte)   = "ppx_foo.cma"
archives(ppx_driver,native) = "ppx_foo.cmxa"
plugin(ppx_driver,byte)     = "ppx_foo.cma"
plugin(ppx_driver,native)   = "ppx_foo.cmxs"

# This is what jbuilder uses to find out the runtime dependencies of
# a preprocessor
ppx_runtime_deps = "ppx_foo.runtime-lib"

# This line makes things transparent for people mixing preprocessors
# and normal dependencies
requires(-ppx_driver) = "ppx_foo.deprecated-ppx-method"

package "deprecated-ppx-method" (
  description = "glue package for the deprecated method of using ppx"
  requires    = "ppx_foo.runtime-lib"
  ppx(-ppx_driver,-custom_ppx) = "./as-ppx.exe"
)

package "runtime-lib" ( ... )
```

You can check that this META works for all the 4 methods described
above.
