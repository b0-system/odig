Webglue — Command line tool to build static websites
-------------------------------------------------------------------------------
v0.0.0-34-g4398318

Webglue is a command line tool to build static websites.

The website's URIs and their content are defined by maps. Maps are
uniquely identified sets of data bindings. Data bindings are defined
by a uniform s-expression syntax. They support localization and inter
map data sharing.

The format of a map determines how the data bindings are consulted to
define URIs and their content. The distribution provides formats for
URIs containing XML, HTML, CSS, UTF-8 text, search engine sitemaps and
raw files. New formats can be defined by dynamically loaded plugins
via the webglue API.

Webglue is distributed under the ISC license.

Home page: http://erratique.ch/repo/webglue  
Contact: Daniel Bünzli `<daniel.buenzl i@erratique.ch>`  
Dogfooding: http://erratique.ch

## Installation

**Warning** webglue is an experiment, it is unsupported software.

Webglue can be installed with `opam`


    opam pin add webglue http://erratique.ch/repos/webglue.git
    opam install webglue


## Getting started

The webglue command line tool and formats are largely self-documented
in the built-in help system. Type :

    webglue 

to get help pointers.

The `share` directory of the distribution contains an emacs mode to
edit map files and an ocamlbuild plugin for that handles the
incremental construction of a website with ocamlbuild and webglue. The
`doc` directory has the documentation of the API to define new map
formats.


## Bugs and ideas

The following could be implemented in future versions of webglue.
Comments and suggestion are welcome.

* All UTF-8 output should be normalized for the web (i.e. NFC).
  http://www.w3.org/TR/charmod-norm/

* Automatic localized data generation for certain categories (day of 
  week, month names) based on CLDR and/or locale(1). 
  E.g. webglue localize days en fr de | webglue set localized month-name

* For now the sort-key of the w.seq directive uses binary comparison on 
  UTF-8 data. The Unicode collation algorithm could be used. 
  Tailoring according to locale ?

* Memoization, however this wouldn't help for ocamlbuild.

* Case directives. w.uppercase, w.lowercase, w.titlecase, w.casefold.
  See Unicode default case algorithms (sections 3.13 and 4.2, 5.18 in
  v5.0.0).  Tailoring according to locale ?  Or shouldn't we just
  leave that to CSS's text-transform property ?

* Better validity checks for generated data (e.g. HTML, CSS).

* Not everything is tail-recursive in there, especially the data language
  evaluator. 

* w.xmlt format, generate a s-expression template and provide a lib to
  substitute. This allows to reuse the map definitions to generate a
  template for a dynamic part of the site.

* Finer dependency tracking, experimental implementation seems to indicate
  that this is overkill.

* Link checker format. E.g. see in erratique website the link.map
