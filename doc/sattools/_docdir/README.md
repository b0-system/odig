# Sattools

[![Build Status](https://travis-ci.org/ujamjar/sattools.svg?branch=master)](https://travis-ci.org/ujamjar/sattools)

Interfaces to SAT solvers and related utility functions.

The solvers can be accessed through DIMAC files, or through
their c/c++ interface using ctypes.

The solvers `minisat`, `picosat` and `cryptominisat(4)` are
supported.

The appropriate solver library must exist on the system at
build time for the FFI interface to be built.  Access via
DIMACs files it always built in and is detected at run-time.

The following lists available solvers

```
# Sattools.Libs.available_solvers();;
- : bytes list =
["crypto"; "pico"; "mini"; "dimacs-crypto"; "dimacs-mini"; "dimacs-pico"] 
```

An available solver module can be instantiated with

```
# module X = (val (Sattools.Libs.get_solver "mini"));;
module X : Sattools.Libs.Solver
```

and provides the following simple API

```
module type Solver = sig
  type solver
  val create : unit -> solver
  val destroy : solver -> unit
  val add_clause : solver -> int list -> unit
  val solve : solver -> unit Result.t
  val solve_with_model : solver -> int list Result.t
  val model : solver -> int -> Lbool.t
end
```

*note; in some cases extra functionality can be accessed directly through
the FFI interface; see the modules `minisat`, `picosat` and `cryptominisat`*

