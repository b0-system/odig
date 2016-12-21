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

| Module selector      | Archive name                          |
|----------------------|---------------------------------------|
| `pkg`                | `$LIBDIR/pkg/pkg.e`                   |
| `pkg.id`             | `$LIBDIR/pkg/[pkg_]id.e`              |
| `pkg.sub.id`         | `$LIBDIR/pkg/sub/[pkg_]id.e`          |
| `pkg@variant`        | `$LIBDIR/pkg/@variant/pkg.e`          |
| `pkg.id@variant`     | `$LIBDIR/pkg/@variant/[pkg_]id.e`     |
| `pkg.sub.id@variant` | `$LIBDIR/pkg/@variant/sub/[pkg_]id.e` |

The map must be bijective it is therefore an error for a package
to install both `$LIBDIDR/pkg/pkg_id.e` and `$LIBDIR/pkg/id.e`.

# Using selectors for compilation

For compilation, selectors allow to lookup compilation flags and
concrete file dependencies needed to use the corresponding modules
during the various compilation phases.

```
odig c [--flags | --file-deps | --sel-deps | --rec] [byte | native ] SEL...
odig l [--flags | --file-deps | --sel-deps | --rec] [byte | native ] SEL...
odig dyn-l [--flags | --files | --rec] [byte | native ] SEL...
```

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

# Assumptions & issues

* When automatic sort, need a deterministic sort,
  in full generality need to control build order (=> refine via `x-` field
  and stable sort) Simple example:
     ```ocaml
       module Msg : sig
         val get : unit -> string 
         val set : string -> unit
       end = struct
         let msg = ref "ho"
         let get () = !msg
         let set m = msg := m
       end

      module A = struct let () = Msg.set "hey" end
      module B = struct let () = print_endline (Msg.get ()) end
     ```

* The (cmi/cmx) files for a given compilation archive are always located
  in the same directory as the archive itself.

* A module implementation cannot depend on another one without importing
  its cmi.

* cmi files with equal digests are totally interchangeable.

* Given a `cmi` and a program at most one module can implement the `cmi`
  in the program. (toplevel)

* When both a `cmo` is available both independently and in a cma
  we favour the `cma`.

* `None` digest (`-opaque`) handling strategy.

* The compilation unit name of a cmi is included in its digest.

* Toplevel loading for cmi only. Directive to declare them ?

* In a dependency dag it is not possible to have the same module
  name with different cmi digests.

* In a dependency dag all cmis without digests with the same name
  must resolve to the same digest.


* Compilation model uncertaineties
** ~~Deps inclusion seems overly inclusive.~~
** No way to detect cmi-only dependencies.


# Cmi needs for separate compilation (`ocaml{c,opt} -c`)

We talk in terms of concrete `cmi` files rather than include path
(`-I`). The latter can always be derived from the former.

Given an `.ml` or `.mli` files and a set of root `cmi` files that
match the compilation unit names mentioned in the `.ml` or `.mli`
file.

The root `cmi` files are determined by selectors. ~~Note that in
constrast to toplevel loading the recursive dependencies of `cmi`
are not needed.~~

# Cmo needs for linking

Given a `cmo` file, we lookup its imported interfaces, match them
to corresponding `cmo` and recursively.

One problem is `cmi`-only dependencies. Another one is None digests.

# Cmx needs for linking

Given a `cmx` file, we lookup its imported implementation, match them
to correspnding `cmx`'s and remove these names from imported
interfaces. For the remaining interface we match them to corresponding
`cmx` files.

