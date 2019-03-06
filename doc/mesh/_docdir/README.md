Mesh
====

This library defines a data structure for triangular meshes and
provides several functions to manipulate them.  In particular, a
[binding](triangle/mesh\_triangle.mli) to [Triangle][] is provided.
It also allows to export meshes of functions defined on their nodes to
[LaTeX][], [SciLab][], [Matlab][], [Mathematica][], and [Graphics][].

[Triangle]: https://www.cs.cmu.edu/~quake/triangle.html
[LaTeX]: src/mesh.mli#L225
[SciLab]: src/mesh.mli#L289
[Matlab]: src/mesh.mli#L314
[Mathematica]: src/mesh.mli#L338
[Graphics]: display/mesh_display.mli

Install
-------

The easier way to install this library is using
[opam](http://opam.ocaml.org/).  It is divided in multiple packages
with `mesh` being the base one, providing the fundamental structure
ans output functions and the other one being bindings to mesh
generation programs/libraries and graphical output.

    opam install mesh
    opam install mesh-display
    opam install mesh-easymesh
    opam install mesh-triangle

If you clone this repository, you can compile the code with `make`
after installing the dependencies listed in the `*.opam` files.
