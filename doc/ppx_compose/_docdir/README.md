[![Build Status](https://travis-ci.org/paurkedal/ppx_compose.svg?branch=master)](https://travis-ci.org/paurkedal/ppx_compose)

## `ppx_compose` - Inlined Function Composition

`ppx_compose` is a simple syntax extension which rewrites code containing
function compositions into composition-free code, effectively inlining the
composition operators.  The following two operators are supported
```ocaml
let (%) g f x = g (f x)
let (%>) f g x = g (f x)
```
Corresponding definitions are not provided, so partial applications of `(%)`
and `(%>)` will be undefined unless you provide the definitions.

The following rewrites are done:

  * A composition occurring to the left of an application is reduced by
    applying each term of the composition from right to left to the
    argument, ignoring associative variations.

  * A composition which is not the left side of an application is first
    turned into one by η-expansion, then the above rule applies.

  * Any partially applied composition operators are passed though unchanged.

E.g.
```ocaml
h % g % f ==> (fun x -> h (f (g x)))
h % (g % f) ==> (fun x -> h (f (g x)))
(g % f) (h % h) ==> g (f (fun x -> h (h x)))
```

### Is It Needed?

Recent flambda-enabled compilers can inline the following alternative
definitions of the composition operators [[1]]:
```ocaml
let (%) g f = (); fun x -> g (f x)
let (%>) f g = (); fun x -> g (f x)
```
so this syntax extension will likely be retired at some point.

[1]: https://discuss.ocaml.org/t/ann-ppx-compose-0-0-3/345
