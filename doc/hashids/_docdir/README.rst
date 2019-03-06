*hashids-ocaml* is an OCaml (4.02.3+) implementation of `hashids <http://hashids.org/>`__.
It generates short, unique, non-sequential ids from numbers, that you can also decode.
It is compatible with version 1.0.0 of hashids.

It's licensed under the `MIT license <http://choosealicense.com/licenses/mit/>`__.
It's available on `OPAM <https://opam.ocaml.org/packages/hashids>`__,
its `documentation <http://jacquev6.github.io/hashids-ocaml>`__
and its `source code <https://github.com/jacquev6/hashids-ocaml>`__ are on GitHub.

Questions? Remarks? Bugs? Want to contribute? `Open an issue <https://github.com/jacquev6/hashids-ocaml/issues>`__!

.. image:: https://img.shields.io/travis/jacquev6/hashids-ocaml/master.svg
    :target: https://travis-ci.org/jacquev6/hashids-ocaml

.. @todo Use ocveralls to upload to coveralls.io

.. image:: https://img.shields.io/github/issues/jacquev6/hashids-ocaml.svg
    :target: https://github.com/jacquev6/hashids-ocaml/issues

.. image:: https://img.shields.io/github/forks/jacquev6/hashids-ocaml.svg
    :target: https://github.com/jacquev6/hashids-ocaml/network

.. image:: https://img.shields.io/github/stars/jacquev6/hashids-ocaml.svg
    :target: https://github.com/jacquev6/hashids-ocaml/stargazers

Quick start
===========

.. highlight:: none

Install from OPAM::

    $ opam install hashids

Launch utop::

    $ utop -require hashids

Create a config::

    utop # let config = Hashids.make ();;
    val config : Hashids.t = <abstr>

Encode some integers::

    utop # Hashids.encode config [42; 57];;
    - : string = "wYcGX"

And decode them::

    utop # Hashids.decode config "wYcGX";;
    - : int list = [42; 57]
