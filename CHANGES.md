
- Require OCaml 4.14.0.
- Install manpages and shell completions.
- Fix race condition in `odoc compiler-deps` invocations.  Thanks to
  Raphaël Proust and José Nogueira for investigating and reporting (#77).
- Improve built-in `index.mld` of the `ocaml` package to adapt 
  to new upstream install structure and provide better access
  to OCaml stdlib modules.

## Command line interface changes 

If you are parsing the outputs of `odig` note that it no longers
automatically disable ANSI text styling based on `isatty`. Invoke the
tool with option `--no-color` or set the environment variable
`NO_COLOR=true` to make sure it does not.

- The variable `ODIG_VERBOSITY` no longer affects `odig`.
- The variable `LOG_LEVEL` sets the log level.
- The variable `ODIG_COLOR` no longer affects `odig`.
- The variable `NO_COLOR` with a non empty value suppresses ANSI text styling.
- The command `odig show` is renamed to `odig info`.
- The option `odig --verbosity` is renamed to `odig --log-level`.
- The option `odig --color` no longer exists.
- The option `odig --no-color` is added to suppress ANSI text styling.
- The option `odig show --show-empty` is renamed to `odig info --keep-empty`.
- The options `odig doc -f` and `odig doc --show-file` are renamed to 
  `odig doc -t` and `odig doc --output-paths`.
- The option `odig log --errors` is renamed to `odig log --failed` (tracks b0).

v0.0.9 2023-06-04 Zagreb
------------------------

- CSS tweaks for record defs.
- Track b0.
- `odig doc -f`: do not quote paths (#68).


v0.0.8 2022-02-09 La Forclaz (VS)
---------------------------------

- Support Cmdliner 1.1.0.
- Exit code 3 is now reported as 123.


v0.0.7 2021-10-09 Zagreb
------------------------

- Stylesheet support for odoc 2.0.0.
- `--index-intro` option. Fix option no longer interpreting 
  relative files w.r.t. the cwd.
- Add `--index-toc` option, to specify the package index table of
  content.  If you used to define a table of contents in the
  `--index-intro` fragment you now need to define it via this
  option. The contents goes into the `odoc-toc` `nav` element.

v0.0.6 2021-02-11 La Forclaz (VS)
---------------------------------

- Stylesheets. Change strategy to make code spans unbreakable.
  The previous way broke Chrome in-page search.
- Track `b0` changes.
- Update link to OCaml manual (#59).
- Require OCaml >= 4.08.0

v0.0.5 2020-03-11 La Forclaz (VS)
---------------------------------

- Rework the `odoc-theme` command. The `set` command now
  unconditionally writes to `~/.conf/odig/odoc-theme` and sets the
  theme for generated doc (the `--default` flag no longer exists).
  The `default` command is renamed to `get`, a `--config` option is
  added to get the theme actually written in the configuration file.
- Add theme `odig.default`, `gruvbox` and `solarized`. These themes
  automatically switch between their corresponding light or dark 
  version acccording to the user browser preference (#54).
- Make `odig.default` the default theme instead of `odoc.default`.
- Generate package index page even if some package fails (#57).
- Hide anchoring links to screen readers on odig generated pages (#55).
- Remove the `--trace` option of `odig odoc` and corresponding
  `ODIG_ODOC_TRACE` variable for generating a build log in Event trace
  format. See the `odig log` command. Use `odig log --trace-event` to
  generate what `--trace` did.
- For consistency with other tools, options `--{cache,doc,lib,share}dir` 
  are renamed to `--{cache,doc,lib,share}-dir` and corresponding 
  environment variable from `ODIG_{CACHE,DOC,LIB,SHARE}DIR` to
  `ODIG_{CACHE,DOC,LIB,SHARE}_DIR`.
- mld only packages: work around `odoc html-deps` bug (#50).
- Package landing pages: fix cache invalidation. In particular opam metadata
  changes did not retrigger a rebuild.
- `gh-pages-amend` tool, add a `--cname-file` option to set
  the `CNAME` file in gh-pages.
- Fix `META` file (#52). Thanks to Kye W. Shi for the report.
- Fix 4.08 `Pervasives` deprecation.
- Require OCaml >= 4.05.0 


v0.0.4 2019-03-08 La Forclaz (VS)
---------------------------------

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
- The odoc API documentation generation support needs an `odoc` v1.4.0
  binary in your `PATH`.
- `odig doc` exit with non-zero on unknown package (#34).
- `odig doc` add `-u` option to guarantee docset freshness (#4).
- Depend only on `cmdliner` and `b0`. Drop dependency on `compiler-libs`,
  `rresult`, `asetmap`, `fpath`, `logs`, `mtime`, `bos`, `webbrowser` and
  `opam-format`.

### Removals

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
