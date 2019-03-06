Topkg-jbuilder - Helpers for using topkg with jbuilder
======================================================

Topkg-jbuilder exposes helpers for using [topkg-care][topkg] in
projects using [Jbuilder][jbuilder].

## Overview

Topkg-jbuilder provides some default topkg settings that are common to
all jbuilder projects, allowing you to use the `topkg` command line
tool in Jbuilder projects.

Note that Topkg-jbuilder only supports the `topkg` command line
tool. Since Jbuilder already handles installation, you don't need to
describe the contents of your project in the `pkg/pkg.ml` file or
replace the build invokcation by `ocaml pkg/pkg.ml build ...` as this
is usually the case in projects using topkg.

You only need to customize the `pkg.ml` file with the bits related to
the release of your package.

## Setup

### pkg/pkg.ml

If there is nothing special in your project and you use the topkg
defaults, simply add this `pkg/pkg.ml` to your project:

```ocaml
#use "topfind"
#require "topkg-jbuilder.auto"
```

Otherwise use this one and customize the options:

```ocaml
#use "topfind"
#require "topkg-jbuilder"

open Topkg

let () =
  Topkg_jbuilder.describe "<project-name>" ...
```

For the simple version to work, you need to have the following files:
- `README.md`
- `CHANGES.md`
- `LICENSE.md`

Additionally, you must have at least one `<package>.opam` file at the
root of your project. If you have multiple ones, the package names
must be prefixed by the shortest one, for instance: `foo.opam`,
`foo-bar.opam` and `foo-baz.opam`. This prefix is used as project name
and will be used to expand the `topkg-jbuilder` strings in your source
files.

This is enough to use the `topkg` command line tool to create and
distribute releases.

### <package>.opam

As said previously, you don't need to change the build instruction in
your `<package>.opam` files. However, if you want `%%ID%%` strings to
be expanded when your packages in pinned, simply add a call to
`jbuilder subst`:

```
build: [
  ["jbuilder" "subst"] {pinned}
  ["jbuilder" "build" "-p" name "-j" jobs]
]
```

Note that if you have multiple `<package>.opam` files and they are not
all prefixed by the shortest package name, you need to pass a `-n`
option to `jbuilder subst`:

```
build: [
  ["jbuilder" "subst" "-n" "foo"] {pinned}
  ["jbuilder" "build" "-p" name "-j" jobs]
]
```

Additionally, make sure that there is no `version: ...` fields in your
`<package>.opam` files, as they will be added automatically by `topkg
distrib` and `jbuilder subst`.

[topkg]:    https://github.com/dbuenzli/topkg
[jbuilder]: https://github.com/janestreet/jbuilder
