## GSL-OCaml - GSL-Bindings for OCaml

GSL-OCaml is an interface to the [GSL](http://www.gnu.org/software/gsl)
(GNU scientific library) for the [OCaml](http://www.ocaml.org)-language.
The currently latest GSL-version known to be compatible is 2.0.

### Requirements

The platform must not align doubles on double-word addresses, i.e. the C-macro
`ARCH_ALIGN_DOUBLE` must be undefined in the OCaml C-configuration header in
`<caml/config.h>`.

#### Configuring alternative BLAS-libraries

The underlying GSL-library depends on a C-implementation of the BLAS-library
(Basic Linear Algebra Subroutines).  It comes with its own implementation,
`gslcblas`, which GSL will link with by default.

This implementation is usually considerably slower than alternatives like
[OpenBLAS](http://www.openblas.net) or [ATLAS (Automatically Tuned Linear
Algebra Software)](http://math-atlas.sourceforge.net) or miscellaneous
platform-specific vendor implementations.

If you want GSL-OCaml to link with another BLAS-implementation by default, you
will need to set an environment variable before starting the build process (e.g.
before `opam install`):

```sh
$ export GSL_CBLAS_LIB=-lopenblas
```

Note that on Mac OS X GSL-OCaml requires the Apple-specific, highly optimized
vendor library `vecLib`, which is part of the Accelerate-framework, and will
automatically link with it. If you do not wish to use Accelerate you can 
override it; for a Homebrew-installed OpenBlas in the usual place you then
need to 
```sh
export GSL_CBLAS_LIB="-L/usr/local/opt/openblas/lib/ -lopenblas"
```

### Documentation

Read the [GSL manual](http://www.gnu.org/software/gsl/manual/html_node) to learn
more about the GNU Scientific Library, and also the
[GSL-OCaml API](http://mmottl.github.io/gsl-ocaml/api/gsl).

### Usage Hints

#### Vectors and Matrices

There are several data types for handling vectors and matrices.

  * Modules `Gsl.Vector`, `Gsl.Vector.Single`, `Gsl.Vector_complex`,
    `Gsl.Vector_complex.Single`, and the corresponding matrix modules use
    bigarrays with single or double precision and real or complex values.

  * Modules `Gsl.Vector_flat`, `Gsl.Vector_complex_flat`, and the corresponding
    matrix modules use a record wrapping a regular OCaml float array.  This is
    the equivalent of the `gsl_vector` and `gsl_matrix` structs in GSL.

  * Module `Gsl.Vectmat` defines a sum type with polymorphic variants
    that regroups these two representations.  For instance:

    ```ocaml
    Gsl.Vectmat.v_add (`V v1) (`VF v2)
    ```

    adds a vector in an OCaml array to a bigarray.

  * Modules `Gsl.Blas Gsl.Blas_flat` and `Gsl.Blas_gen` provide a (quite
    incomplete) interface to CBLAS for these types.

#### ERROR HANDLING

Errors in GSL functions are reported as exceptions:

```ocaml
Gsl.Error.Gsl_exn (errno, msg)
```

You have to call `Gsl.Error.init ()` to initialize error reporting.  Otherwise,
the default GSL error handler is used and aborts the program, leaving a core
dump (not so helpful with OCaml).

If a callback (for minimizers, solvers, etc.) raises an exception, GSL-OCaml
either returns `GSL_FAILURE` or `NaN` to GSL depending on the type of callback.
In either case the original OCaml exception is not propagated.  The GSL function
will either return normally (but probably with values containing `NaN`s
somewhere) or raise a `Gsl_exn` exception.

### Contact Information and Contributing

Please submit bugs reports, feature requests, contributions and similar to
the [GitHub issue tracker](https://github.com/mmottl/gsl-ocaml/issues).

Up-to-date information is available at: <https://mmottl.github.io/gsl-ocaml>
