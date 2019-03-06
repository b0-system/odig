[![Build Status][ci-build-status]][ci]

# Two PPXes for Working with Regular Expressions

This repo provides two PPXes providing regular expression-based routing:

- `ppx_regexp` maps to [re][] with the conventional last-match extraction
  into `string` and `string option`.
- `ppx_tyre` maps to [Tyre][tyre] providing typed extraction into options,
  lists, tuples, objects, and polymorphic variants.

Another difference is that `ppx_regexp` works directly on strings
essentially hiding the library calls, while `ppx_tyre` provides `Tyre.t` and
`Tyre.route` which can be composed an applied using the Tyre library.

## `ppx_regexp` - Regular Expression Matching with OCaml Patterns

This syntax extension turns
```ocaml
function%pcre
| {|re1|} -> e1
...
| {|reN|} -> eN
| _ -> e0
```
into suitable invocations of the [Re library][re], and similar for
`match%pcre`.  The patterns are plain strings of the form accepted by
`Re_pcre`, with the following additions:

  - `(?<var>...)` defines a group and binds whatever it matches as `var`.
    The type of `var` will be `string` if the match is guaranteed given that
    the whole pattern matches, and `string option` if the variable is bound
    to or nested below an optionally matched group.

  - `?<var>` at the start of a pattern binds group 0 as `var : string`.
    This may not be the full string if the pattern is unanchored.

A variable is allowed for the universal case and is bound to the matched
string.  A regular alias is currently not allowed for patterns, since it is
not obvious whether is should bind the full string or group 0.

### Example

The following prints out times and hosts for SMTP connections to the Postfix
daemon:
```ocaml
(* Link with re, re.pcre, lwt, lwt.unix.
   Preprocess with ppx_regexp.
   Adjust to your OS. *)

open Lwt.Infix

let check_line =
  (function%pcre
   | {|(?<t>.*:\d\d) .* postfix/smtpd\[[0-9]+\]: connect from (?<host>[a-z0-9.-]+)|} ->
      Lwt_io.printlf "%s %s" t host
   | _ ->
      Lwt.return_unit)

let () = Lwt_main.run begin
  Lwt_io.printl "SMTP connections from:" >>= fun () ->
  Lwt_stream.iter_s check_line (Lwt_io.lines_of_file "/var/log/syslog")
end
```

## `ppx_tyre` - Syntax Support for Tyre Routes

### Typed regular expressions

This PPX compiles
```ocaml
[%tyre {|re|}]
```
into `'a Tyre.t`.

For instance, We can define a pattern that recognize strings of the form "dim:3x5" like so:

```ocaml
# open Tyre ;;
# let dim = [%tyre "dim:(?&int)x(?&int)"] ;;
val dim : (int * int) Tyre.t
```

The syntax `(?&id)` allows to call a typed regular expression named `id` of type `'a Tyre.t`, such as `Tyre.int`.

For convenience, you can also use *named* capture groups to name the captured elements.
```ocaml
# let dim = [%tyre "dim:(?<x>(?&int))x(?&y:int)"] ;;
val dim : < x : int; y : int > Tyre.t
```

Names given using the syntax `(?<foo>re)` will be used for the fields
of the results. `(?&y:int)` is a shortcut for `(?<x>(?&int))`.
This can also be used for alternatives, for instance:

```ocaml
# let id_or_name = [%tyre "id:(?&id:int)|name:(?<name>[:alpha:]+)"] ;;
val id_or_name : [ `id of int | `name of string ] Tyre.t
```

Expressions of type `Tyre.t` can then be composed as part of bigger regular
expressions, or compiled with `Tyre.compile`. 
See [tyre][]'s documentation for details.

### Routes

`ppx_tyre` can also be used for routing, in the style of `ppx_regexp`:

```ocaml
    function%tyre
    | {|re1|} -> e1
    ...
    | {|reN|} -> eN
```

is turned into a `'a Type.route`, where `re`, `re1`, ... are regular expressions
using the same syntax as above. `"re" as v` is considered like `(?<v>re)` and
`"re1" | "re2"` is turned into a regular expression alternative.

Once routes are defined, matching is done with `Tyre.exec`.

### Details

The syntax follow Perl's syntax:

- `re?` extracts an option of what `re` extracts.
- `re+`, `re*`, `re{n,m}` extracts a list of what `re` extracts.
- `(?&qname)` refers to any identifier bound to a typed regular expression
  of type `'a Tyre.t`.
- Normal parens are *non-capturing*.
- There are two ways to capture:
  - Anonymous capture `(+re)`
  - Named capture `(?<v>re)`
- One or more `(?<v>re)` at the top level can be used to bind variables
  instead of `as ...`.
- One or more `(?<v>re)` in a sequence extracts an object where each method
  `v` is bound to what `re` extracts.
- An alternative with one `(?<v>re)` per branch extracts a polymorphic
  variant where each constructor `` `v`` receives what `re` extracts as its
  argument.
- `(?&v:qname)` is a shortcut for `(?<v>(?&qname))`.

## Limitations

### No Pattern Guards

Pattern guards are not supported.  This is due to the fact that all match
cases are combined into a single regular expression, so if one of the
patterns succeed, the match is committed before we can check the guard
condition.

### No Exhaustiveness Check

The syntax extension will always warn if no catch-all case is provided.  No
exhaustiveness check is attempted.  Doing it right would require
reimplementing full regular expression parsing and an algorithm which would
ideally produce a counter-example.

## Bug Reports

The processor is currently new and not well tested.  Please break it and
file bug reports in the GitHub issue tracker.  Any exception raised by
generated code except for `Match_failure` is a bug.


[ci]: https://travis-ci.org/paurkedal/ppx_compose
[ci-build-status]: https://travis-ci.org/paurkedal/ppx_regexp.svg?branch=master
[re]: https://github.com/ocaml/ocaml-re
[tyre]: https://github.com/Drup/tyre
