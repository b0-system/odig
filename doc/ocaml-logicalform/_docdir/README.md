# ocaml-logicalform

`LogicalForm` provides modules for efficient and intuitive
manipulation of logical expressions within [OCaml][ocaml].

---

[**OPAM Package**][opam-pkg]
&nbsp;&middot;&nbsp;
[**API Documentation**][api-doc]
&nbsp; &vert; &nbsp;
[Installation](#installation)
&nbsp;&middot;&nbsp;
[Usage](#usage)
&nbsp;&middot;&nbsp;
[Change Log](CHANGES.md)
&nbsp;&middot;&nbsp;
[License (MIT)](#license-mit)

---



## Installation

The library is released as [`ocaml-logicalform`][opam-pkg] package,
and is available on [`opam`][opam].

#### Stable version

```bash
$ opam install ocaml-logicalform
```

#### Development version (pinned to this repository)
```bash
$ opam pin add ocaml-logicalform https://github.com/SaswatPadhi/ocaml-logicalform.git
$ opam install ocaml-logicalform
```



## Usage

We assume the following environment for the examples below:

```ocaml
open LogicalForm.Std (* Predefined standard forms *)
open Sexplib         (* Translating to/from S-Expressions *)
```


### Creating Expressions

#### Using constructors

We use integer indices (starting at `1`) for variables appearing in literals:
- `` `Pos x `` creates an _unchecked_ positive literal
- `` `Neg x `` creates an _unchecked_ negative literal
- `` `L?? x `` or `` `L (id x) `` validates `x`:
  - creates a positive literal for `x`-th variable if `x > 0`
  - creates a negative literal for `x`-th variable if `x < 0`
  - throws an exception if `x = 0`

They  are combined using `` `And `` and `` `Or `` constructors
to form bigger expressions, as shown below:

```ocaml
(* Various representations for E = ~(x1 /\ (x2 \/ (x3 /\ ~x4))) *)

(* E in conjunctive normal form (CNF) : unchecked literals *)
let cnf : CNF.t =
  `And [ `Or [ `Neg 1 ; `Neg 2 ]
       ; `Or [ `Neg 1 ; `Neg 3 ; `Pos 4 ]]

(* E in disjunctive normal form (DNF) : unchecked literals *)
let dnf : DNF.t =
  `Or [ `Neg 1
      ; `And [ `Neg 2 ; `Neg 3 ]
      ; `And [ `Neg 2 ; `Pos 4 ]
      ]

(* E in negation normal form (NNF) : literals validated *)
let nnf : NNF.t =
  `Or [ `L?? (-1)
      ; `And [ `L?? (-2)
             ; `Or [ `L?? (-3) ; `L?? 4 ]
             ]
      ]

(* E not in normal form  : literals validated *)
let unnf : UnNF.t =
  `Not ( `And [ `L (id 1)
              ; `Or [ `L (id 2)
                    ; `And [ `L (id 3) ; `L (id (-4)) ]
                    ]
              ])
```

#### From S-Expressions

One can also parse `LogicalForm` expressions from [SMT-LIB][smt-lib] style
[S-Expressions][s-expression]:

```ocaml
let cnf' : CNF.t =
  CNF.of_pretty_sexp (
    Sexp.of_string "(and (or (not x1) (not x2)) (or (not x1) (not x3) x4))")
```

The `cnf'` expression should be equivalent to `cnf`:

```ocaml
(* Since cnf used `Pos and `Neg, we must validate it *)
# cnf' = CNF.validate cnf;;
- : bool = true
```

`LogicalForm` also supports custom prefixes for variables (instead of the `x` as
above), and custom operator names for conjunction, disjunction, and negation.
(See [advanced usage](#printing-and-parsing-options)).


### Pretty Printing

#### Compact human readable strings

```ocaml
# DNF.to_pretty_string dnf;;
- : string = "(~x1 | (~x2 & ~x3) | (~x2 & x4))"

# NNF.to_pretty_string nnf;;
- : string = "(~x1 | (~x2 & (~x3 | x4)))"
```

#### S-Expressions

```ocaml
# Sexp.to_string_hum (CNF.to_pretty_sexp cnf);;
- : string = "(and (or (not x1) (not x2)) (or (not x1) (not x3) x4))"

# Sexp.to_string_hum (UnNF.to_pretty_sexp unnf);;
- : string = "(not (and x1 (or x2 (and x3 (not x4)))))"
```

`CNF` and `DNF` can be interpreted as `NNF` expressions, but not vice versa.
Similarly an expression in any normal form can be interpreted as an `UnNF`
expression, but not vice versa.

```ocaml
# NNF.to_pretty_string (cnf :> NNF.t);;
- : string = "((~x1 | ~x2) & (~x1 | ~x3 | x4))"

# CNF.to_pretty_string (nnf :> CNF.t);;
Error: ...

# Sexp.to_string_hum (UnNF.to_pretty_sexp (nnf :> UnNF.t));;
- : string = "(or (not x1) (and (not x2) (or (not x3) x4)))"

# NNF.to_pretty_string (unnf :> NNF.t);;
Error: ...
```


### Extracting Executable Functions

```ocaml
# let cnf_f = CNF.eval cnf;;
val cnf_f : bool array -> bool option = <fun>
```

An executable function for a `LogicalForm` expression consumes
an `array` of `bool` values, and returns:
- `None` if the execution failed, because the value of a literal was not provided
- `Some b` if the expression evaluates to the `bool` value `b`

```ocaml
(* Not enough data to evaluate *)
# cnf_f [| true |];;
- : bool option = None

(* Short-circuited evaluation *)
# cnf_f [| false |];;
- : bool option = Some true

(* Unused variables are ignored *)
# cnf_f [| true ; false ; false ; true ; false ; true |];;
- : bool option = Some true
```


### Combining Expressions

Every form `F` in `LogicalForm` is,
- `Conjunctable`: supports conjunction of a `list` of `F` expressions using `and_`
- `Disjunctable`: supports conjunction of a `list` of `F` expressions using `or_`
- `Negatable`: allows negation of an `F` expression using `not_`

Let us define two new expressions:

```ocaml
let cnf_2 : CNF.t = `And [ `Pos 1 ; `Or [ `Neg 2 ; `Pos 3 ] ]
let dnf_2 : DNF.t = `Or [ `Pos 3 ; `And [ `Pos 2 ; `Neg 1 ] ; `Pos 4 ]
```

We can now combine:

```ocaml
(* Disjunction of CNFs into a CNF *)
# let cnf_3 = CNF.or_ [ cnf ; cnf_2 ];;
val cnf_3 : CNF.t = ...

(* Conjunction of expressions in arbitrary NFs into an NNF *)
# let nnf_2 = NNF.and_ [ (dnf :> NNF.t) ; nnf ; (cnf :> NNF.t) ];;
val nnf_2 : NNF.t = ...
```


### Advanced Usage

#### Printing and parsing options

Users may override default pretty-printing styles for strings and S-Expressions
as below:

```ocaml
(* to_pretty_string uses infix operators *)
let my_infix_style = {
  PPStyle.Infix.default
  with var_prefix = "j"
     ; _or_ = " OR "
     ; _and_ = " AND "
}

(* to_pretty_sexp uses prefix operators *)
let my_prefix_style = {
  PPStyle.Prefix.default
  with var_prefix = "k"
     ; or_ = "O"
     ; and_ = "A"
     ; not_ = "N"
}
```

These styles may be provided to the pretty-printing functions as shown below:

```ocaml
# NNF.to_pretty_string nnf ~style:my_infix_style;;
- : string = "(~j1 OR (~j2 AND (~j3 OR j4)))"

# nnf = NNF.of_pretty_sexp
          ~style:my_prefix_style
          (Sexp.of_string "(O (N k1) (A (N k2) (O (N k3) k4)))")
- : bool = true
```

#### Literal index type

`LogicalForm` allows literals to contain custom data types.
The `Std` modules provides pre-defined `CNF`, `DNF`, `NNF`, and `UnNF`
modules based on `Base.Int` type. On modern 64-bit machines,
one may restrict the index type to `Base.Int32`
(instead of `Base.Int = Base.Int64`):

```ocaml
module Index32 = LogicalForm.Index.Make(Base.Int32)
let ( ?? ) = Index32.id

module Literal32 = LogicalForm.Literal.Make(Index32)
module Clause32 = LogicalForm.Clause.Make(Literal32)
module CNF32 = LogicalForm.CNF.Make(Clause32)
module NNF32 = LogicalForm.NNF.Make(Literal32)
...
```

All examples shown above should work for these 32-bit modules too.



## License [(MIT)](LICENSE)

Copyright &copy; 2018 Saswat Padhi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.





[api-doc]:      http://saswatpadhi.github.io/ocaml-logicalform
[opam-pkg]:     https://opam.ocaml.org/packages/ocaml-logicalform/

[ocaml]:        https://ocaml.org/
[opam]:         https://opam.ocaml.org/
[smt-lib]:      http://smtlib.cs.uiowa.edu/
[s-expression]: https://en.wikipedia.org/wiki/S-expression