

- Support for odoc manuals (`.mld` files) and package page customization
  (`index.mld` file) (#31, #18). See the packaging conventions; if you are
  using `dune` and already authoring `.mld` files the right thing should
  be done automatically install-wise.
- Support for odoc themes (#21). Themes can be distributed via `opam`, see
  command `odig odoc-theme` and the packaging conventions in `odig doc odig`.
- Support for best-effort OCaml manual theming. Themes can provide a stylesheet
  to style the local manual installed by the `ocaml-manual` package and linked
  from the generated documentation sets.
- Support for customizing the title and introduction of the package list
  page (#19). See the `--index-title` and `--index-intro` options of
  `odig odoc`.
- Add `gh-pages-amend` a tool to easily push documentation sets on
  GitHub pages (see the odig manual and `--help` for details).
- The `opam` metadata support needs an `opam` v2 binary in your `PATH`.
- The odoc API documentation generation support needs an `odoc` v1.3.3
  binary in your `PATH`.
- `odig doc` exit with non-zero on unknown package (#34).
- `odig doc` add `-u` option to guarantee docset freshness (#4).
- Depend only on `cmdliner` and `b0`. Drop dependency on `compiler-libs`,
  `rresult`, `asetmap`, `fpath`, `logs`, `mtime`, `bos`, `webbrowser` and
  `opam-format`.

## Removals

- The best-effort `ocamldoc` support and corresponding command are dropped.
- The `metagen` and `linkable` experimental tools are gone.
- The data-driven toplevel loaders are gone. See the
  [`omod`](https://erratique.ch/software/omod) project if your
  are interested in this.
- Removed JSON output from the commands that supported it.
- The `help` command is dropped. Documentation is now in `odig`'s API
  docs and is where the manual and the packaging conventions can be
  found. Consult `odig doc odig`.
- The `--docdir-href` option of `odig odoc` no longer exists. The
  docset in `$(odig cache path)/html` is self-contained and can be
  published as is (provided you follow symlinks).
- The `authors`, `deps`, `maintainers`, `tags`, `version` and `repo` commands
  are gone but the lookups are available via the `show` command.
- The `homepage`, `issues` and `online-doc` commands are available via
  the `show` and `browse` commands.
- The `cobjs`, `graph` and `guess-deps` commands are dropped.

v0.0.3 2017-10-31 Zagreb
------------------------

- Fix obscure build bug on 4.06.0 (#32)

v0.0.2 2017-05-31 Cambridge (UK)
--------------------------------

- Added experimental data-driven toplevel loaders.
- The `odoc` API documentation is shown by default on `odig doc`.
- The `mli`, `cmi`, `cmo`, `cmti`, `cmx` and `cmt` commands are grouped in
  the `cobjs` command.
- Track latest cmdliner and mtime.

v0.0.1 2016-09-23 Zagreb
------------------------

First release. The ocamldoc release.
