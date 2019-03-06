# ppx_test : ppx replacement of pa_ounit

# Overview

ppx_test is a PPX preprocessor to embed tests in source code
and to run these tests and collect the results.

Embedding tests are by special `let %TEST` declarations. For example:

```ocaml
let %TEST split_at = split_at 3 "hello world" = ("hel", "lo world")
```

A `let %TEST` declaration is converted to code which registers 
the test function. 
The registered tests are executed by calling `Ppx_test.Test.collect ()`.

# History

`ppx_test` is build as a PPX port of CamlP4 module `pa_test`.

# Pros and Cons

Pros:

* Test declarations are valid in OCaml's syntax. Therefore it can benefit
  the editor support such as source code highlighting and auto-indentaitons.
* No special test code extraction is required to type-check, compile and run them.

Cons:

* Tests are embeded. Therefore it increases object size of
  the libraries and applications.

# Requirement

ppx_test converts the embeded test codes using the following functions:

* `PTest.test : Ppx_test.Location.t -> string option -> (unit -> unit) -> unit`
* `PTest.test_unit : Ppx_test.Location.t -> string option -> (unit -> unit) -> unit`
* `PTest.test_fail : Ppx_test.Location.t -> string option -> (unit -> unit) -> unit`

It is the client responsibility to make the module `PTest` available
in the name space where the tests are embeded.

`Ppx_test.Test` is a ready-to-use example for `PTest`.
See the later section how to use it.
Another example, `examples/wrap_pa_ounit.ml` provides 
a simple wrapper for `pa_ounit`.

# How to declare tests

## Inlined test `let %TEST`

Test expression `e` can be embedded using `let %TEST` toplevel declaration as follows:

```
let %TEST <name> = e
```

Test names `<name>` can be one of the following:

* `_` : anonymous
* `"name"` : string
* `name` : variable
* `M.X` : "constr_longident"

Names except `_` are identified with the current module path.
For example, in the following code,

```ocaml
(* x.ml *)
module M = struct
  let %TEST test = ...
end
```

The test has the global name `X.M.test`. 
If the file is compiled with `-for-package P`, 
then it is prefixed as `P.X.M.test`.

### Boolean test

By default, tests are all boolean. The test code `e` in `let %TEST name = e`
must have type `bool`. The test succeeds when `e` is evaluated to `true`.

For example,
```
let %TEST add = 1 + 2 = 3
```

### Unit test

If a name is not anonymous and ends with `_` ex. `let %TEST name_ = e`,
it is considered `unit` test: the test expression `e` must have type `unit`.
The test succeeds when `e` is evaluated without raising any exception.

For example,
```
let %TEST add_ = assert (1 + 2 = 3)
```

This naming convention of `_` follows Haskell function naming (ex. `mapM_ :: Monad m => (a -> m b) -> [a] -> m ()`.)

### Failure test

If a name is not anonymous and end with `_fail` ex. `let %TEST name_fail = e`,
it is considered `failure` test: the test expression `e` must have type `unit`.
The test succeeds when `e`'s evaluation raises any exception.

For example,
```
let div100 x = 100 / x
let %TEST div100_10 = div100 10 = 10  (* boolean test *)
let %TEST div100_fail = div100 0      (* fail test *)
```

### Group of tests by [%%TEST ..]

You can write a bunch of tests inside `[%%TEST ..]`:

```
[%%TEST

  let add = 1 + 2 = 3              (* boolean test *) 
  let add_ = assert (1 + 2 = 3)    (* unit test *)
]
```

You can also omit the name of the test in `[%%TEST]`:

```
[%%TEST
   length [1;2;3] = 3;;
]
```
This is equivalent with `let %TEST _ = length [1;2;3] = 3`.

### Testing order

Tests are listed in their order of registeration: 
in the same order of their occurrences and module linking.  
If tests are inside a functor, they are added when the functor is
applied: if not applied, tests are ignored.

Tests running order can be shown using `--test-show` option,
but you should not rely on it: tests should be independent each other.

### Tests inside functors

Tests inside functors are only registered when the functors are applied and
the code registeration by `let %TEST ..` or `[%%TEST ..]` are executed.

## `__FOR_PACKAGE__`

`__FOR_PACKAGE__` is a pseudo value of type `string option`
which returns the package name specified by comipler's `-for-package` option. 
