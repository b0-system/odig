# Polymorphic record in OCaml

This ppx adds polymorphic record.

## Poylmorphic records

Polymorphic records provided by `Poly_record` has type
`fields Poly_record.t`, where `fields` encodes field type information
as object type. For example, `< x : int; y : float > Poly_record.t`
is a type of polymorphic records whose fields are `x : int` and `y : float`.

Polymorphic records are like objects but *not* objects:

* Internally, poly records are implemented as hash tables, whose keys are hash of field names. This is just like OCaml's object implementation therefore the operation consts of the both are almost the same.
* Type safety by object type. The same restrictions of objects apply to poly records too. For example, you cannot newly add fields by `!{ e with l = e'}`: the expression forces `e` contain the field `l`.
* Poly records do not contain closures themselves, therefore safely streamable to other programs if fields do not contain closured. Objects have closures by themselves therefore marshaling to other programs is not safe.

## Creation of polymorphic records `!{ l = e; ...}`

Prefixed by `!`, the record literal is cahnged from  
the normal (monomorphic) records to polymorphic records
whose type is `_ Ppx_poly_record.Poly_record.t`.

```ocaml
# !{ x = 1; y = 1.0 };;
- : < x : int; y : float > Ppx_poly_record.Poly_record.t = <abstr>
```

Unlike the normal monomorphic records, it is not required to declare
fields of the polymorphic records. They are inferred using OCaml's
object type. 


## Field access `r#!l`

Accessing fields of the polymorphic records is by `r#!x`:

```ocaml
# fun r -> r#!x;;
- : < x : 'tvar_1; .. > Ppx_poly_record.Poly_record.t -> 'tvar_1 = <fun>
```

## Field mutation `r#!l := e`

Since the polymorphic record has no type declaration, there is no way for it 
to pre-declare some fields are mutable. Therefore, all the fields
of polymorphic records are immutable. Still, if you want mutbility,
you can use reference:

```ocaml
# let r = !{ x = ref 0 } in r#!x := 1; r
- : < x : int ref; .. > Ppx_poly_record.Poly_record.t = <abstr>
```

## Record copy with field updates: `!{ r with l = e; .. }`

The syntax of record copy `{ r with x = e }` works for polymorphic records too,
with the prefix `!`:

```ocaml
# fun r -> !{ r with x = 1 };;
- : (< x : int; .. > as 'a) Ppx_poly_record.Poly_record.t 
    -> 'a Ppx_poly_record.Poly_record.t
```

## Conversion of mono-record syntax uses to poly-record ones automatically: `[%poly_record ..]`

Inside `[%poly_record ..]`, all the monomorphic record syntax constructions are automatically translated to those for polymorphic records. For example,
`[%poly_record { x = 1; y = 1.0}.x]` is equivalent with `!{ x = 1; y = 1.0}#!x`:

* `{ l = e; ...}` becomes `!{ l = e; ...}`
* `{ e with l = e'; ...}` becomes `!{ e with l = e'; ...}`
* `r.x` becomes `r#!x`
* `r.x <- e` becomes `r#!x := e`

Inside `[%poly_record ..]`, you can use `[%mono_record ..]` to locally disable this conversion.

## Todo

* Printing
* Patterns: `!{ x = p }`. This is diffcult...
