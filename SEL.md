Module selectors (WIP)
----------------------

A *module selector* is a name that denotes a set of public OCaml
toplevel modules definitions, their implementation (if any) and
dependencies (if any), regardless of the compilation target. It is
used to indicate a set of toplevel modules you need to compile a given
source.

The module selectors of a package are defined by the name of the
package and the OCaml compilation archives a package installs. It is
assumed that compilation archives with the same name but in different
formats (i.e. `.cma`, `.cmxa`, `.cmxs`) define the same set of
*public* OCaml toplevel modules.

For a package `pkg` the bijective map between archive names and
selectors is the following, with `.e` denoting `.{cma,cmxa,cmxs}`.

| Module selector      | Archive name
--------------------------------------------------------
| `pkg`                | `$LIBDIR/pkg/pkg.e`
| `pkg.id`             | `$LIBDIR/pkg/[pkg_]id.e`
| `pkg.sub.id`         | `$LIBDIR/pkg/sub/[pkg_]id.e`
| `pkg@variant`        | `$LIBDIR/pkg/@variant/pkg.e`
| `pkg.id@variant`     | `$LIBDIR/pkg/@variant/[pkg_]id.e`
| `pkg.sub.id@variant` | `$LIBDIR/pkg/@variant/sub/[pkg_]id.e` 

The map must be bijective it is therefore an error for a package
to install both `$LIBDIDR/pkg/pkg_id.e` and `$LIBDIR/pkg/id.e`.

# Using selectors for compilation

For compilation, selectors allow to lookup compilation flags and
concrete file dependencies needed to use the corresponding modules
during the various compilation phases.

odig c [--flags | --file-deps | --sel-deps | --rec] [byte | native ] SEL...
odig l [--flags | --file-deps | --sel-deps | --rec] [byte | native ] SEL...
odig dyn-l [--flags | --files | --rec] [byte | native ] SEL...

The result of these commands is computed automatically in a
compilation object universe bounded by the `deps:` and `depopts:`
fields of the package's opam file `$LIBDIR/opam`. Failures can happen
if the universe happens to be ambiguous.

In order to resolve ambiguities, tweak or entirely replace the
result of these computations. The results of these queries can be
tweaked by using special fields in the package's opam file
`$LIBDIR/opam` of the form:

```
x-odig-sel-$SEL:
    [ [synopsis STRING]
      [hide]
      [$QUERY [STRING...]] ]
```

* `$SEL` the selector to which it applies (the toplevel package name
   can be replaced by `_` following OPAM conventions).
* `$QUERY`
  `{compile,link,dynlink}-{flags,files,deps}-{byte,native}-{pre,post,replace}`
   or maybe give more structure to the subfield.
* Maybe variants should rather be defined in the variant less selector.

# Using selectors for toplevel 

Selectors can be used used to load the set of modules it denotes and its
dependencies in the toplevel.

Given an archive `$F.e`, the toplevel loading procedure checks for a
the existence of `$F_top_init.ml` file in the same directory and, if
it exists, loads it right after having loaded the archive unless
explicitely prevented.


```ocaml
val Odig.list : unit -> unit
val Odig.load : ?conf:Odig.Conf.t -> ?noinit:[`Pkg | `All] -> sel -> unit
```






