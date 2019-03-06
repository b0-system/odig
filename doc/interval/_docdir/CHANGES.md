1.4 2018-03-01
--------------

- Improved interface for the `Interval` library by using sub-modules
  and standard mathematical names.  In particular, all operations —
  including infix operators — are in a sub-module `I` which can
  conveniently be used to introduce local scopes after issuing `open
  Interval`.

- Improved pretty-printing functions allowing to pass the format of
  the interval bounds.

- The library functions now signal errors by exceptions
  `Division_by_zero` and `Domain_error` that are *local* to
  `Interval`.

- The `Fpu` module has been redesigned: the rounding up or down of
  functions is controlled by the sub-module (`Low` or `High`) to which
  they belong.  This allows for natural expressions such as
  `Low.(x**2. +. 2. *. x +. 1.)`.

- Jbuilder/dune is used to compile and install the library.

- TravisCI and AppVeyor continuous integration ensure the library
  works on a variety of OCaml versions and platforms.
