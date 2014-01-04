
Most bindings in Tgls are automatically generated. The primary source
of data is the XML representation of the [OpenGL registry][1] whose
most (but not all) important bits are decoded by the by the
[`Glreg`](glreg.mli) module. A few missing things are added with the
[`Fixreg`](fixreg.mli) module.

From this raw registry information we derive for each feature tag (API
description really) a cleaned up C API model on which we operate
through with the [`Capi`](capi.mli) module.

Given a C API, we derive an OCaml API with the module
[`Opai`](oapi.mli), most bindings are automatically derived. The few
ones that are manually made are in the [`Manual`](manual.mli)
module. `mli` and `ml` generation for an OCaml API is handled by the
[`Gen`](gen.mli) module.

The [`apiquery`][apiquery.ml] command line tool allows to query APIs
and generate the bindings. Invoke with `-h` for more information.

The documentation of these modules can be generated with:
    
    ./build doc -b 

from the root directory of a repo checkout.

[1]: http://www.opengl.org/registry/
