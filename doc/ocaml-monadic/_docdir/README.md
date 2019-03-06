# ocaml-monadic
Lightweight PPX extension for OCaml to support natural monadic syntax.

## Purpose
At the time of this writing, the PPX syntax extensions for monads available in the OPAM repositories are largely invested in providing a monadic syntax which looks similar to that of Haskell.  While this syntax is familiar, it is also quite different from OCaml's syntax (and even from Haskell's non-monadic syntax), leading to a well-known difficulty in transitioning existing code to and from monadic form.  This syntax extension aims to provide a monadic syntax which blends more readily with that of OCaml.

## Extensions

### `let%bind`, `if%bind`, `match%bind`, `;%bind`
The first syntax extension provided by this library is the `%bind` syntax.

`let%bind` is supported only for non-recursive `let` expressions.  For instance, the code
  ```ocaml
  let%bind x = [1;2;3] in
  let%bind y = [4;5;6] in
  return (x + y)
  ```
desugars to
  ```ocaml
  bind [1;2;3] (fun x ->
    bind [4;5;6] (fun y ->
      return (x+y)
    )
  )
  ```

`if%bind` permits monadic values to be used directly in conditions.  The code
  ```ocaml
  if%bind x then
    return a
  else
    return b
  ```
desugars to
  ```ocaml
  bind x (function
  | true -> return a
  | false -> return b
  )
  ```

`match%bind` permits monadic values to be used as `match` subjects; the code
  ```ocaml
  match%bind x with
  | A -> return a
  | B -> return b
  ```
desugars to
  ```ocaml
  bind x (function
  | A -> return a
  | B -> return b
  )
  ```

`;%bind` allows monadic unit expressions to be sequenced directly.  The code
  ```ocaml
  expr1 ;%bind
  expr2 ;%bind
  return ()
  ```
desugars to
  ```ocaml
  bind expr1 (fun () ->
    bind expr2 (fun () ->
      return ()
    )
  )
  ```

In all of the above cases, the function `bind` is assumed to be defined in local scope; this may occur in any fashion but is most easily accomplished with a local open (e.g. `let open MyMonad in`).

### `let%orzero`
The `let%orzero` extension, which also applies only to non-recursive `let` expressions, is used with monads that are equipped with a zero operation (such as monads for nondeterminism or exception handling).  It allows the refutable destruction of a value; refutations become zeroed.  For instance, the code
  ```ocaml
  let%orzero Foo(a,b) = x in
  return (a + b)
  ```
desugars to
  ```ocaml
  match x with
  | Foo(a,b) -> return (a + b)
  | _ -> zero ()
  ```
The function `zero` is assumed to be bound in local scope.

Although the above is handy when dealing with zero-equipped monads, non-zero monads can be given ad-hoc `orzero` behavior by binding a `zero` function.  For instance, one might consider the following code:
  ```ocaml
  let some_fn x =
    let open StateMonad in
    let zero () = raise (Invariant_exception "state value has wrong form") in
    let%orzero Foo(a) = get () in
    set (Foo(a+x));
    return (a+x)
  ;;
  ```
In the above, `let%orzero` is used to destruct a value provided by a state monad.  Although the state monad is not equipped with a `zero` operation, a local definition of `zero` is provided here to handle the case in which the stateful value does not match the expected form.  This is, of course, increasingly beneficial as the number of `let%orzero` operations increases, as it allows us to amortize the cost of defining the ad-hoc `zero`.

### `[%guard]`
The `[%guard]` extension accepts a single expression as its payload and is also used with `zero`-equipped monads.  It is used to stop computation and produce a `zero` unless a condition holds.  For example, the code
  ```ocaml
  [%guard b];
  return x
  ```
desugars to
  ```ocaml
  if b then return x else zero ()
  ```
The primary value of `[%guard]` is that it permits these condition checks in a terse, naturally sequential fashion and in a way which automatic code formatters (such as `ocp-indent`) will respect.  Note that `[%guard]` is only processed when it appears on the left-hand side of a sequence operator.

## Usage
To use the above syntax extensions, it should be sufficient to name the `ocaml-monadic` package in an invocation of `ocamlbuild` or `ocamlfind`.  The `lib/META` file (generated here by `lib/META.ab`) ensures that `ocamlfind` will apply the PPX extension.  For OASIS users, it should be sufficient to add `ocaml-monadic` to a library's `BuildDepends` section in an `_oasis` file.  For dune/jbuilder users simply add `ocaml-monadic` to the `(preprocess (pps (...)))` stanza of your `jbuild` file, like you would with any other ppx.
