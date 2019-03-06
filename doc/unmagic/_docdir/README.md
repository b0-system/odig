# Unmagic: runtime type checking of OCaml marshaled (streamed) data

Unmagic is a library to dynamically type check `Obj.t` data
to assure safety of their coercions to expected types.
It uses Typerep for the representation of data types.
Secured version of `Obj.obj`, `Unmagic.obj` has the following type:

```
val obj : sharing:bool -> 'a Typerep.t -> Obj.t -> 'a
```

`obj ~sharing (tyrep : ty Typerep.t) o` checks the value of `Obj.t` can be
safely coerced to a value of type `ty`.  If the check succeeds it returns
the coerced value of type `ty`.  Otherwise, it raises an exception `Ill_typed`.

The parameter `~sharing:true` enables sharing and cycle detection:
it avoids repeating type checks of shared nodes and cycles which are
already visited with the same types.  It makes the type checking *very* slow
but is necessary for data with cycles.  Type checking may never
terminates for cyclic data with `~sharing:false`.
