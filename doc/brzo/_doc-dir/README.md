brzo — Quick-setting builds
-------------------------------------------------------------------------------
79d316a5

Brzo is a build tool to quickly turn source files of various languages
into executable programs and documents.

Brzo favors best-effort heuristics and advices over formal
configuration. It is a simple build tool made for exploratory design
and learning. It is unsuitable for building software distributions.

Brzo partitions its build logics into *domains* which broadly map to
support for different languages. Each domain provides a few build
*outcomes* which determine a build artefact and an action performed on
it. The following domains are defined:

* `c`, C support. Outcomes for executable programs and source
  documentation via [Doxygen][doxygen]. 
* `cmark`, [CommonMark][commonmark] support. Outcomes for a web of
  HTML programs (via [cmark][cmark]).
* `latex`, [LaTeX][latex] support. Outcomes for PDF documents and
  source file listings.
* `ocaml`, [OCaml][ocaml] support. Outcomes for byte and native code
  executable programs with C bindings, HTML and JavaScript programs
  via [js_of_ocaml][jsoo], interactive toplevel sessions in the
  terminal and in the browser, source documentation and manuals.

Brzo is distributed under the ISC license, it depends on [`b0`][b0] and
[`cmdliner`][cmdliner].

## Domain support

Homepage: http://erratique.ch/software/brzo  

[emscripten]: http://emscripten.org
[doxygen]: http://www.doxygen.org/
[commonmark]: https://commonmark.org/
[cmark]: https://github.com/commonmark/cmark
[latex]: https://www.latex-project.org
[ocaml]: https://ocaml.org
[jsoo]: https://ocsigen.org/js_of_ocaml
[b0]: https://erratique.ch/software/b0
[cmdliner]: https://erratique.ch/software/cmdliner

## Installation

brzo can be installed with `opam`:

    opam install brzo

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Quick start

A few invocations to get you started.

```shell
> touch BRZO
> cat > echo.ml <<EOCAML
print_endline (String.concat " " (List.tl (Array.to_list Sys.argv)))
EOCAML
> brzo -- 'Quick!'
'Quick!'
> brzo ocaml --html -- 'Quick!' # See your browser console.
> brzo --doc 
```

Use `brzo --help` to see which domains are available and `brzo DOMAIN
--help` to see which outcomes are available for a domain. For more
information see the [manual][doc] or `odig doc brzo`.

## Documentation & support

The manual can be consulted [online][doc] or via `odig doc brzo`.
Brzo strives to give a hassle free build experience but it may still
be useful to go through the manual to understand a bit better how the
heuristics work for a domain and or how to guide them via a `BRZO`
file.

Questions are welcome but better asked on the [OCaml forum][ocaml-forum]
than on the issue tracker.

[doc]: https://erratique.ch/software/brzo/doc/
[ocaml-forum]: https://discuss.ocaml.org/
