*General* is an OCaml (4.02.3+) general purpose library.
It adds rich functionality to built-in and basic OCaml types.

It's licensed under the `MIT license <http://choosealicense.com/licenses/mit/>`_.
It's available on `OPAM <https://opam.ocaml.org/packages/General/>`_,
its `documentation <http://jacquev6.github.io/General>`_
and its `source code <https://github.com/jacquev6/General>`_ are on GitHub.

Questions? Remarks? Bugs? Want to contribute? `Open an issue <https://github.com/jacquev6/General/issues>`_!

.. image:: https://img.shields.io/travis/jacquev6/General/master.svg
    :target: https://travis-ci.org/jacquev6/General

.. image:: https://img.shields.io/coveralls/jacquev6/General/master.svg
    :target: https://coveralls.io/r/jacquev6/General

.. image:: https://img.shields.io/github/issues/jacquev6/General.svg
    :target: https://github.com/jacquev6/General/issues

.. image:: https://img.shields.io/github/forks/jacquev6/General.svg
    :target: https://github.com/jacquev6/General/network

.. image:: https://img.shields.io/github/stars/jacquev6/General.svg
    :target: https://github.com/jacquev6/General/stargazers

Quick start
===========

Install from OPAM::

    $ opam install General

Launch utop::

    $ utop -require General

Open::

    open General.Abbr;;

And use::

    ["a"; "b"; "c"; "d"] |> StrLi.concat ~sep:", "
    -: string = "a, b, c, d"
