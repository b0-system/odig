OCaml GDAL and OGR bindings
---------------------------

This library provides access to the GDAL library (http://www.gdal.org/).  It
provides both direct, low-level access to GDAL and OGR library functions as
well as a higher level, more OCaml-like interface.

The API is [viewable here](http://hcarty.github.io/ocaml-gdal/gdal/index.html).

Using the bindings
------------------

Linking to the underlying GDAL library is performed at runtime.
To initialize:

    Gdal.Lib.init_dynamic ();

The `init_dynamic` function takes an optional `~lib` argument which may be
used to specify the specific shared object to link against.  It defaults to
`libgdal.so`.
