[![Build Status](https://travis-ci.org/Chris00/ocaml-cairo.svg?branch=master)](https://travis-ci.org/Chris00/ocaml-cairo)
[![AppVeyor Build status](https://ci.appveyor.com/api/projects/status/5dp8aftaq7ohyflq?svg=true)](https://ci.appveyor.com/project/Chris00/ocaml-cairo)

OCaml interface to Cairo
========================

This is an OCaml binding for the
[Cairo](http://www.cairographics.org/) library, a 2D graphics library
with support for multiple output devices.

You can read the API of
[Cairo](http://chris00.github.io/ocaml-cairo/doc/cairo2/Cairo/),
[Cairo_gtk](http://chris00.github.io/ocaml-cairo/doc/cairo2-gtk/Cairo_gtk/),
and
[Cairo_pango](http://chris00.github.io/ocaml-cairo/doc/cairo2-pango/Cairo_pango/)
online.

Prerequisites
-------------

You need the development files of Cairo (see the
[conf-cairo](https://github.com/ocaml/opam-repository/blob/master/packages/conf-cairo/conf-cairo.1/opam#L7)
package)
and the OCaml package
``lablgtk2`` (in the [OPAM](https://opam.ocaml.org/) package
``lablgtk``).

Compilation & Installation
--------------------------

The easier way to install this library — once the prerequisites are set
up — is to use [opam](http://opam.ocaml.org/):

    opam install cairo2

If you would like to compile from the sources, install [Dune][]

    opam install dune

and do:

    dune build @install

or just `make`.  You can then install it with:

	dune install

[Dune]: https://github.com/ocaml/dune

Examples
--------

You can read a version of the
[Cairo tutorial](http://chris00.github.io/ocaml-cairo/) using
this module.  The code of this tutorial is available in the
``examples/`` directory.  To compile it, just do

    dune build @examples

All the examples below are available (with some comments) by clicking
on images in the [tutorial](http://cairo.forge.ocamlcore.org/tutorial/).

### Basic examples

- [stroke.ml](examples/stroke.ml) shows how to draw (stroke) a simple
  rectangle on a PNG surface.
- [stroke.ml](examples/stroke.ml) shows how to fill a simple
  rectangle on a PNG surface.
- [showtext.ml](examples/showtext.ml) illustrates how to select a font
  and draw some text on a PNG surface.
- [paint.ml](examples/paint.ml) shows how to paint the current source
  everywhere within the current clip region.
- [mask.ml](examples/mask.ml) shows how to apply a radial transparency
  mask on top of a linear gradient.
- [setsourcergba.ml](examples/setsourcergba.ml) produces

  ![Source RGBA](http://cairo.forge.ocamlcore.org/tutorial/setsourcergba.png)

- [setsourcegradient.ml](examples/setsourcegradient.ml) shows how to use
  radial and linear patterns.  It generates:

  ![Gradient](http://cairo.forge.ocamlcore.org/tutorial/setsourcegradient.png)

- [path_close.ml](examples/path_close.ml) shows how to draw a closed
  path.  It produces the PNG:

  ![close path](http://cairo.forge.ocamlcore.org/tutorial/path-close.png)

- [textextents.ml](examples/textextents.ml) displays graphically the various
  dimensions one can request about text.  It generates the PNG:

  ![text](http://cairo.forge.ocamlcore.org/tutorial/textextents.png)

- [text_extents.ml](examples/text_extents.ml) exemplifies drawing
  consecutive UTF-8 strings in a PDF file.  Some helping lines are
  also added to show the text extents.

- [tips_ellipse.ml](examples/tips_ellipse.ml) shows the action of
  dilation on the line width and how to properly draw ellipses.
  It generates the PNG:

  ![ellipse](http://cairo.forge.ocamlcore.org/tutorial/tips_ellipse.png)

- [tips_letter.ml](examples/tips_letter.ml) illustrates the wrong way
  of centering characters based on their individual extents:

  ![letters](http://cairo.forge.ocamlcore.org/tutorial/tips_letter.png)

  Instead, one should combine them with the font extents as shown in
  [tips_font.ml](examples/tips_font.ml) to have:

  ![fonts](http://cairo.forge.ocamlcore.org/tutorial/tips_font.png)


### Examples generating the images of the tutorial

- [diagram.ml](examples/diagram.ml) draw the images of the section
  [Cairo's Drawing Model](http://cairo.forge.ocamlcore.org/tutorial/#drawing_model):

  ![destination](http://cairo.forge.ocamlcore.org/tutorial/destination.png)
  ![source](http://cairo.forge.ocamlcore.org/tutorial/source.png)
  ![the mask](http://cairo.forge.ocamlcore.org/tutorial/the-mask.png)
  ![stroke](http://cairo.forge.ocamlcore.org/tutorial/stroke.png)
  ![fill](http://cairo.forge.ocamlcore.org/tutorial/fill.png)
  ![show text](http://cairo.forge.ocamlcore.org/tutorial/showtext.png)
  ![paint](http://cairo.forge.ocamlcore.org/tutorial/paint.png)
  ![mask](http://cairo.forge.ocamlcore.org/tutorial/mask.png)

- [draw.ml](examples/draw.ml) generates the various images in
  [Drawing with Cairo](http://cairo.forge.ocamlcore.org/tutorial/#drawing_with_cairo), namely:

  ![Source RGBA](http://cairo.forge.ocamlcore.org/tutorial/setsourcergba.png)
  ![Gradient](http://cairo.forge.ocamlcore.org/tutorial/setsourcegradient.png)
  ![moveto](http://cairo.forge.ocamlcore.org/tutorial/path-moveto.png)
  ![lineto](http://cairo.forge.ocamlcore.org/tutorial/path-lineto.png)
  ![arcto](http://cairo.forge.ocamlcore.org/tutorial/path-arcto.png)
  ![curveto](http://cairo.forge.ocamlcore.org/tutorial/path-curveto.png)
  ![close path](http://cairo.forge.ocamlcore.org/tutorial/path-close.png)
  ![text](http://cairo.forge.ocamlcore.org/tutorial/textextents.png)
