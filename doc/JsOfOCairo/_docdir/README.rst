*JsOfOCairo* is an OCaml (4.02.3+) library to reuse Cairo-based drawing code in web browsers.
It's an adapter, implementing (a reasonable subset of) the interface of `Cairo OCaml <https://github.com/Chris00/ocaml-cairo/>`_
targeting HTML5 canvas elements as exposed to OCaml by `js_of_ocaml <https://ocsigen.org/js_of_ocaml/>`_ (3.0.0+).

It's licensed under the `MIT license <http://choosealicense.com/licenses/mit/>`_.
It's available on `OPAM <https://opam.ocaml.org/packages/JsOfOCairo/>`_.
Its `source code <https://github.com/jacquev6/JsOfOCairo>`_ is on GitHub.

Here is `DrawGrammar <https://jacquev6.github.io/DrawGrammar/>`_, a real-life aplication of JsOfOCairo.

There is no real documentation besides this README.rst file.
See below what is implemented, what behaves differently from Cairo, and what is not implemented.

Questions? Remarks? Bugs? Want to contribute? `Open an issue <https://github.com/jacquev6/JsOfOCairo/issues>`__!

.. image:: https://img.shields.io/travis/jacquev6/JsOfOCairo/master.svg
    :target: https://travis-ci.org/jacquev6/JsOfOCairo

.. image:: https://img.shields.io/github/issues/jacquev6/JsOfOCairo.svg
    :target: https://github.com/jacquev6/JsOfOCairo/issues

.. image:: https://img.shields.io/github/forks/jacquev6/JsOfOCairo.svg
    :target: https://github.com/jacquev6/JsOfOCairo/network

.. image:: https://img.shields.io/github/stars/jacquev6/JsOfOCairo.svg
    :target: https://github.com/jacquev6/JsOfOCairo/stargazers

Versions
========

A breaking change was `introduced in OCaml Cairo version 0.6 <https://github.com/Chris00/ocaml-cairo/commit/9aa9ce403fd16c56245c695eb0108aebdedec150#diff-d9fad5803a4c2c22f5c1be3854b69e50>`_.

`JsOfOCairo version 2 <https://opam.ocaml.org/packages/JsOfOCairo/JsOfOCairo.2.0.0/>`_ implements a subset of
the interface of `OCaml Cairo version 0.6 <https://opam.ocaml.org/packages/cairo2/cairo2.0.6/>`_,
while
`JsOfOCairo version 1 <https://opam.ocaml.org/packages/JsOfOCairo/JsOfOCairo.1.1.1/>`_ implements a subset of
the interface of `OCaml Cairo version 0.5 <https://opam.ocaml.org/packages/cairo2/cairo2.0.5/>`_.

Quick start
===========

Install from OPAM::

    $ opam install JsOfOCairo

The files described below are available as a `demo directory <https://github.com/jacquev6/JsOfOCairo/tree/master/demo>`_.
Have a look at this directory for the details about compiling.
In particular see the `dune file <https://github.com/jacquev6/JsOfOCairo/blob/master/demo/dune>`_
and the `call to dune <https://github.com/jacquev6/JsOfOCairo/blob/master/demo/demo.sh>`_.

Create a functor implementing your drawing code against the ``JsOfOCairo.S`` signature.
File ``drawings.ml``::

    module Make(C: JsOfOCairo.S) = struct
      let draw ctx =
        C.save ctx;
        C.arc ctx 50. 50. ~r:40. ~a1:0. ~a2:5.;
        C.stroke ctx;
        C.restore ctx
    end

Instantiate this functor with ``Cairo`` to create a command-line program.
File ``draw_on_command_line.ml``::

    module Drawings = Drawings.Make(Cairo)

    let () = begin
      let image = Cairo.Image.create Cairo.Image.ARGB32 ~w:100 ~h:100 in
      Drawings.draw (Cairo.create image);
      Cairo.PNG.write image "draw_on_command_line.png";
    end

Instantiate the same functor with ``JsOfOCairo`` and compile it using js_of_ocaml to create a Javascript file.
File ``draw_in_browser.ml``::

    module Drawings = Drawings.Make(JsOfOCairo)

    let () = Js.export "draw" (fun canvas ->
      Drawings.draw (JsOfOCairo.create canvas)
    )

And call this javascript file in an HTML document.
File ``draw_in_browser.html``::

    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">

      <title>JsOfOCairo demo</title>
    </head>
    <body>
      <h1>PNG image from command-line</h1>
      <img src="draw_on_command_line.png" />
      <h1>HTML5 canvas</h1>
      <canvas id="drawings" width="100" height="100"></canvas>
      <script src="_build/default/draw_in_browser.bc.js"></script>
      <script>
        draw(document.getElementById("drawings"));
      </script>
    </body>
    </html>

As a bonus, *JsOfOCairo* comes with ``CairoMock``, which implements the ``JsOfOCairo.S`` signature and simply records the
calls made on the context object. You can use it to automate some tests on your drawing code::

    module Drawings = Drawings.Make(CairoMock)

    let () = begin
      let ctx = CairoMock.create () in
      Drawings.draw ctx;
      assert (CairoMock.calls ctx = ["save"; "arc 50.00 50.00 ~r:40.00 ~a1:0.00 ~a2:5.00"; "stroke"; "restore"])
    end

*CairoMock* itself is split into *CairoMock.Mock*, an actual mock implementation of ``JsOfOCairo.S`` that does nothing, and *CairoMock.Decorate*, that can be used to record calls made on *any* implementation of ``JsOfOCairo.S``. So, you can draw and record calls at the same time.

What is implemented
===================

See the `interface file (S.incl.ml) <https://github.com/jacquev6/JsOfOCairo/blob/master/src/S.incl.mli>`_.
If a function is present, it should behave as described in the `Cairo OCaml Tutorial <http://cairo.forge.ocamlcore.org/tutorial/index.html>`__.

How to avoid pitfalls
=====================

There **are** limitations however: text-related functions, arcs, re-use of the same canvas...
Details of the `limitations identified so far <https://jacquev6.github.io/JsOfOCairo/>`_ are available with the tests.
We believe they are small enough for the library to be useful anyway.

Here is a set of rules to follow to stay on the safe side of using *JsOfOCairo*:

- Always call ``save`` just after creating a context, and ``restore`` just before stopping using it.
- Never create two contexts from the same canvas at the same time: wait until you have ``restore``-d a context before creating another.
- Never draw arcs of more than one full turn.
- Use only the ``width``returned by ``text_extents``.
- Use only the ``ascent`` and ``descent`` returned by ``font_extents``.

What is not implemented
=======================

Contributions in this area are welcome.
Please `start a discussion <https://github.com/jacquev6/JsOfOCairo/issues>`_ before doing anything to avoid wasting time.

Everything involving a ``Surface.t`` has been dismissed.
This doesn't make much sense in an HTML5 context.
An attempt has been made to implement ``set_source_for_image`` using a hidden canvas but it's been unsuccessful.

A few other functions commented out at the beginning of `S.incl.ml <https://github.com/jacquev6/JsOfOCairo/blob/master/src/S.incl.mli>`_ have been dismissed as well.

Testing strategy
================

There are three sets of tests:

universal tests
    They are run on ``Cairo`` to check their validity, and then on ``JsOfOCairo`` and ``CairoMock`` to actually test the library.
    They verify that getters return the value that was last set, that the current point is updated, and that all this is saved and restored consistently.

drawing tests
    They are run on ``Cairo`` to generate reference bitmaps, and then on ``JsOfOCairo`` to verify that both libraries produce very similar drawings.

decoration tests
    They verify the strings generated by ``CairoMock``.

All these tests are run automatically as `OCaml bytecode and in Node.js (through js_of_ocaml) <https://travis-ci.org/jacquev6/JsOfOCairo>`_
and are available in `web browsers <https://jacquev6.github.io/JsOfOCairo/>`_.
