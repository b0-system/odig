---
title: ppx_optcomp - Optional compilation for OCaml
parent: ../README.md
---

ppx\_optcomp stands for Optional Compilation. It is a tool used to
handle optional compilations of pieces of code depending of the word
size, the version of the compiler, ...

ppx\_optcomp can be used a a standalone pre-processor, but is also
integrated in the
[ppx\_driver](https://github.com/janestreet/ppx_driver).

The syntax is quite similar to cpp:

```ocaml
#if ocaml_version < (4, 02, 0)
let x = 1
#else
let y = 2
#endif
```

Note that ppx\_optcomp does not support macros like cpp, we only use
it for optional compilations.

Syntax
------

ppx\_optcomp runs after the OCaml lexer and before the OCaml
parser. This means that parts of the file that are dropped by
ppx\_optcomp needs to be lexically correct but not grammatically
correct.

ppx\_optcomp will interpret all lines that start with a `#`. `#` has
to be the first character, if there are spaces before ppx\_optcomp
will not try to interpret the line and will pass it as-is to the OCaml
parser. The syntax is:

```
#identifier directive-argument
```

The argument is everything up to the end of the line. You can use `\`
at the end of lines to span the argument over multiple line. Optcomp
will also automatically fetch arguments past the end of line if a set 
of parentheses is not properly closed.

So for instance one can write:

```ocaml
#if ocaml_version < (  4
                    , 02
                    ,  0
                    )
```

Note that since ppx\_optcomp runs after the lexer it won't interpret
lines starting with `#` if they are inside another token. So for
instance these won't work:

* `#`-directive inside a string:

    ```ocaml
    let x = "
    #if foo
    "
    ```

* `#`-directive inside a comment:

    ```ocaml
    (*
    #if foo
    *)
    ```

Directives
----------

### Defining variables

- `#let` _pattern_ `=` _expression_
- `#define` _identifier_ _expression_

We also allow: `#define` _identifier_. This will define _identifier_
to `()`.

You can also undefine a variable using `#undef` _identifier_.

### Conditionals

The following directives are available for conditional compilations:

- `#if` _expression_
- `#elif` _expression_
- `#else`
- `#endif`

In all cases _expression_ must be an expression that evaluates to a
boolean value. Ppx\_optcomp will fail if it is not the case.

For people used to cpp, we also allow these:

- `#ifdef` _identifier_
- `#ifndef` _identifier_
- `#elifdef` _identifier_
- `#elifndef` _identifier_

Which will test if a variable is defined. Note that ppx\_optcomp will
only accept to test if a variable is defined if it has seen it before,
in one of `#let`, `#define` or `#undef`. This allows ppx\_opcompt to
check for typos.

We do however allow this special case:

```ocaml
#ifndef VAR
#define VAR
```

### Warnings and errors

`#warning` _expression_ will cause the pre-processor to print a
message on stderr.

`#error` _expression_ will cause the pre-processor to fail with the
following error message.

Note that in both cases _expression_ can be an arbitrary expression.

### Imports

Ppx\_optcomp allows one to import another file using:

`#import` _filename_

where _filename_ is a string constant. Filenames to import are
resolved as follow:

- if _filename_ is relative, i.e. doesn't start with `/`, it is
  considered as relative to the directory of the file being parsed
- if _filename_ is absolute, i.e. starts with `/`, it is used as it

To keep things simple ppx\_optcomp only allows for `#`-directives in
imported files. The intended use is having this at the beginning of a
file:

```ocaml
#import "config.mlh"
```

Expressions and patterns
------------------------

ppx\_optcomp supports a subset of OCaml expressions and patterns:

- literals: integers, characters and strings
- tuples
- `true` and `false`
- let-bindings
- pattern matching

And it provides the following functions:

- comparison operators: `=`, `<`, ...
- boolean operators: `||`, `&&`, `not`, ...
- arithmetic operators: `+`, `-`, `*`, `/`
- `min` and `max`
- `fst` and `snd`
- conversion functions: `to_int`, `to_string`, `to_char`, `to_bool`
- `show`: pretty-print a value

It also provides `defined` which is a special function to test if a
variable is defined. But the same remark as for `#ifdef` applies to
`defined`.
