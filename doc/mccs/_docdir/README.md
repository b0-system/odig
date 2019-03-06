# mccs OCaml library

mccs (which stands for Multi Criteria CUDF Solver) is a CUDF problem solver
developed at UNS during the European MANCOOSI project.

This repository contains a stripped-down version of the
[mccs solver](http://www.i3s.unice.fr/~cpjm/misc/mccs.html), taken from snapshot
1.1, with a binding as an OCaml library, and building with `jbuilder`. The
[GLPK](https://www.gnu.org/software/glpk/glpk.html) source it links against is
also included within src/glpk, at version 4.63 (unmodified, apart from many
removed modules, corresponding to the parts that we don't use).

The binding enables interoperation with binary CUDF data from
[the OCaml CUDF library](https://gforge.inria.fr/projects/cudf/), and removes
the native C++ parsers and printers from mccs.

Only the GLPK backend and the `lpsolve` interface are compiled by default, but
that can be tuned by setting the MCCS_BACKENDS environment variable, at
compile-time, to a space-separated list of the following: `GLPK`, `COIN`, `CLP`,
`CBC`, `SYMPHONY`. Note that, apart from `GLPK`, you will need the corresponding
libraries installed, the backends will be dynamically linked, and these are
experimental may not work as expected. Additionally, the compilation of the
included GLPK version can be disabled by removing `src/glpk/jbuild`, and
replaced by dynamic/static linking by renaming one of the `jbuild-shared` and
`jbuild-static` files.

NOTE: the lib takes criteria as a string, in the format accepted by mccs (see
`mccs -h`), assuming `-lexagregate[CRITERIA]`. There are two important
differences:
- the colon after properties can be omitted `-count[version-lag,true]` rather
  than `-count[version-lag:,true]`
- the second parameter for `count[]` has been **extended** from a boolean to any
  one of `request`, `new`, `changed`, `solution`, for more expressivity.
Example: `-removed,-count[version-lag,true],-changed,-count[version-lag,false]`

Build using `opam install .` (opam 2.0), or `jbuilder build`.

Note: this depends on a C++ compiler, and was only tested with g++.
