# ppx_monadic

`ppx_monadic` is a PPX syntax extension for monadic bind syntactic sugar.
It provides:

* `do_` sequence and `p <-- e` notation for monadic bind
* Extension to `when` to support pattern guards
* `[%comp e || ..]` for list (and other monadic) comprehensions
* `let%m p = e in'` for monadic bind, equivalent with `p <-- e`
* `match%m e with ..'` for monadic bind+match, equivalent with `p <-- e; match p with ..`
* `[%do ..]` and `begin%do .. end`, other forms for `do_` sequence

`ppx_monadic` follows the tradition of `pa_monad`, a CamlP4 syntax extension
for `do` notation. Basically almost of all the code with `pa_monad` 
should work with `ppx_monadic` only by replacing `perform` by `do_;`. 
(I find `perform` is bit too long to type.)

# Syntax of do-sequence

*Do-sequence* `phs` is a non-empty sequence of the following phrases `ph` seprated by `;`:

```
phs ::= ph
      | ph ; phs
      | let .. in phs
      | [%x phs]

ph ::= p <-- e
     | e
     | ()
```

### Bind `p <-- e`

`p` is a pattern to bind the result of `e`. 
The syntax of the pattern `p` is limited to those which are parsable 
as OCaml expressions. For example, you cannot write

```
(Foo x as y) <-- e
```

since `Foo x as y` is not a valid OCaml expression. 
You can still write such complex patterns wrapping them with `[%p? ..]`:

```
[%p? (Foo x as y)] <-- e
```

is a valid phrase.

### Action `e`

Action `e` in a do-sequence is an arbitrary expression except
in the form of `p <-- e`.

### Escape by `()`

`ppx_monadic` overrides the original meaning of `;` operator in do-sequence,
but we often want to use the original meaning of `;` for sequential execution
in order to perform side effects.
For this purpose, we have a sugar to escape the override:

```
(); e; phs
```

If an expression `e` is prefixed by `(); ` in do-sequence, 
`e; phs` is desguared simply to `e; <phs>` using OCaml's original sequential
execution, where `<phs>` is the desugar of `phs`.

If you do not like this syntax, you can always define:

```
let escape e = e; return ()
```

and use it inside `do_`:

```
do_;
  ...;
  escape @@ e;
  ...;
```

### Lets `let .. in phs`

A do-sequence can be a let-binding 
such as the normal `let` and `let rec`, `let module`, etc.

`let .. in phs` is always desugared to 
`let .. in <phs>` where `<phs>` is the desugar of `phs`.

### Extension `[%x phs]`

A do-sequence can be an extension `[%x phs]` which contains another do-sequence.

`[%x phs]` is always desugared to
`[%x <phs>]` where  `<phs>` is the desugar of `phs`.

# Monadic `do_` notation

`do_` (and also `M.do_` for a module path `M`) is treated as a new keyword 
in `ppx_monadic`. It can only appear at the head of an expresison. 
`do_` introduces syntactic sugar for the monadic operations against 
the expressions followed by it as far as they are sequenced using `;`.
A `do_` clause looks like:

```ocaml
do_
; ph1
; ..
; phn
```

or

```
M.do_
; ph1
; ..
; phn
```

**You cannot omit `;` after `do_`.**
This is since `do_ x <-- e` is parsed as `(do_ x) <-- e` by OCaml 
and usually this is not what you want.

### Desugaring inside `do_`

`<phs>`, the desguaring of do-sequence `do_; phs` is defined as follows:

```
< p <-- e; phs >   =  bind e (fun p -> <phs>)
< p <-- e >        =  THIS IS ERROR
< e; phs >         =  bind e (fun () -> <phs>)
< e >              =  e
<(); e; phs>       =  e; <phs>
<(); e>            =  e
<let .. in phs>    =  let .. in <phs>
<[%x phs]>         =  [%x <phs>]
```

`bind` must be available in the scope so that the desugared expression 
can be properly compiled.

### With a module path: `M.do_`

`do_` clause with a module path, `M.do_`, has the same syntactic sugar as `do_` but adds `let bind = M.bind and return = M.return in` at the head of the desugared expression in addition. For example, `Option.do_; x <-- e1; phs` is desugared to:

```
let bind = Option.bind
and return = Optin.return
in
bind e1 (fun x -> <phs>)
```

when `phs` is desugared to `<phs>`. This is convenient when `bind` and other monadic operators are defined in the module specified by the module path.

### Incompatibility with `pa_monad`

* `do_;` instead of `perform`
* `M.do_;` instead of `perform with M`
* Refutable patterns such as `1 <-- exp` are simply translated to non-exhaustive pattern matches, where `pa_monad` inserts `failwith` to the default case. In `ppx_monadic`, we recommend to use bind + multi-case pattern match: `match%m exp with 1 -> ... | _ -> ...`.
* Recursive monad bindings are not supported.

### Difference between Haskell's `do` notation

`ppx_monadic` is different from Haskell's `do` notation in the following points:

* `do_`: We cannot use `do` since it is a keyword in OCaml which cannot be used at the head of expressions.
* `<--`: We cannot use `<-` since it is for record/object field mutation in OCaml.
* `(); e; phs`: OCaml is impure and side effects are often used even inside `do_`. `(); e;` is to escape the desugaring and regain the original meaning of `;`.

# Pattern guards

`ppx_monadic` extends `when` clause so that it can take pattern guards
[*pattern guards*](http://citeseer.ist.psu.edu/erwig00pattern.html).
The expression inside `when` is parsed as a do-sequence.

The meaning of do-sequence phrases inside `when` is as follows:

### Bind `p <-- e`

The result of `e` is pattern-matched with `p`.

If the match of `p` fails, the match case immediately fails,
then the next match case is tried.

If the match of `p` succeeds, then the next pharse is tested
keeping the variable bindings in `p`. If there is no more phrase,
then the match action is executed with all the variable bindings
of `p <-- e` inside `when`.

### Action `e`

If the result of `e` is false, the match case immediately fails
and the next case is tested.

If the result of `e` is true, then the next phrase is tested.
If there is no more phrase, the match action is executed
with all the variable bindings of `p <-- e` inside `when`.

### Escape `(); e`

Simply executed `e`, then test the next phrase.

### Let `let .. in phs`

Binds variables inside `let` binding then tests `phs`.

### Extension `[%x phs]`

Desugared to `[%x <phs>]`, where `<phs>` is the desugar of `phs`.

### Incompatibility

`ppx_monadic` changes the semantics of `when` clause.
If some existing code has code like `when e1; e2 -> ..`,
this `e1; e2` is no longer considered as a sequential execution
but do-sequence.

Normally such uses of `;` inside `when` should be found by the type-checker,
since in `ppx_monadic` `e1` should have type `bool` in `e1; e2`, 
instead of `unit`. Therefore I believe the impact is negligble.

# List (and monadic) comprehensions

`ppx_monadic` introduces list comprehension syntax `[%comp e || phs]`.
(Unfortunatelly `|` is not usable here.)

`ppx_monadic` also introduces general monad comprehension `[%M.comp e || phs]`.
It uses `M.return`, `M.bind` and `M.mzero` inside the desugaring, 
therefore they must be defined inside module `M`.

Syntax of list comprehension could be as simple as `[e || phs]`, but
in that case the `||` symbol would become ambiguous: we cannot tell 
it is the separator of the list comprehension or normal boolean "OR".
In addition, I personally feel `[ e || phs ]` is too confusing
with the normal list expression `[ e1; ..; en ]`,
though their semantics are pretty different.

# Notation `let%m`

`let%m p = e1 in e2` is another form of `p <-- e1; e2` and desugared to

```
bind e1 (fun p -> e2')
```

when `e2` is desugared to `e2'`. `let%m` is not required inside `do_`. 
You can also write `let%M.m p = e1 in e2` which uses `M.bind`.

In side `do_`, you can use `let%m p = e` as an alternative of `p <-- e`,
it is useful when pattern `p` is too complex and you cannot simply write `p <-- e`.

## Multi bindings of `let%m`

Note that

```
let%m p1 = e1
and   p2 = e2
in
e
```

is equivalent with

```
let fresh_var1 = e1
and fresh_var2 = e2
in
bind fresh_var1 (fun p1 ->
  bind fresh_var2 (fun p2 ->
    e))
```

This is not equal to the following sequence of two `let%m` bindings:

```
let%m p1 = e1 in
let%m p2 = e2 in
e
```

# Notation `match%m`

`match%m e with ..` is equivalent with

```
bind e (function ..)
```

You can simplify bind-then-match sequences using `match%m`. For example,

```
do_;
  x <-- e
  match x with
  | ...
```
can be simplified to:

```
match%m e with
| ...
```

# Notations `[%do ..]`, `begin %do .. end`

Notations `[%do <e>]` and `begin %do <e> end` are other forms of `do_; <e>`.
You can use them if you do not like `do_; ..`.

Like `M.do_; ..`, you can qualifiy `do` in `[%do ..]` and `begin%do .. end`
like `[%M.do ..]` and `begin%M.do .. end`.

# To see the output of `ppx_monadic`

```shell
$ ppx_monadic -debug x.ml
```

prints out desugared source code. This should be convenient if you feel the desugaring is buggy.
