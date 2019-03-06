OCaml exception tracing
=======================

This small library allows a user or a preprocessor to reliably
trace exceptions, i.e. give a list of source code locations
through which an exception propagated.

The traditional method consisting in recording the stack trace at the
point where an exception is raised is not satisfying. In particular
it doesn't allow exceptions to be stored while other functions run
and may themselves raise exceptions, resetting the stack trace. Some
examples of what works and what doesn't work with stack traces
are given here: https://github.com/mjambon/backtrace

Instead of relying on stack traces, Trax wraps the original exception
within a special exception together with a trace, i.e. a list of
source code locations.

Sample usage
------------

```ocaml
let foo x y z =
  ...
  (* some error occurred *)
  Trax.raise __LOC__ (Failure "uh oh")

let bar x y z =
  try foo x y z
  with e ->
    (* inspect the exception; requires unwrapping *)
    match Trax.unwrap e with
    | Invalid_arg _ ->
       assert false
    | _ ->
       (* re-raise the exception, adding the current location to the trace *)
       Trax.raise __LOC__ e

let main () =
  try
    ...
    bar x y z
    ...
  with e ->
    Trax.print stderr e
```
