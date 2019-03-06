ORakuda
===============

Ppx extension for string literals.

For functionality X, it provies `{X|...|X}`, `[%X "..."]` and `[%X {|...|}]`.

* PCRE expression and matching of Perl like syntax `{m|...|m}` using Pcre library.

```ocaml
open Ppx_orakuda.Regexp.Pcre.Literal
{m|regexp|m}               (*  /regexp/  *)
{s|pattern/template/g|s}   (* s/pattern/template/g; *) 
```

* PCRE expression and matching of Perl like syntax `{m|...|m}` using Re library

```ocaml
open Ppx_orakuda.Regexp.Re_pcre.Literal
{m|regexp|m}               (*  /regexp/  *)
{s|pattern/template/g|s}   (* s/pattern/template/g; *) 
```

* Variable and expression references in string `{qq|...|qq}`:

```ocaml
[%qq "Your are ${name} and %{age}02d years old."]
```

* Sub-shell call by back-quotes `{qx|...|qx}`: 

```ocaml
let status = {qx|wc|qx} ~f:handle_output in ...
```

## Name of the project ##

ORakuda has two meanings in Japanese:
    
* 大(O)駱駝(Rakuda): 大(big) 駱駝(dromedary/bactrian camel)
* おお(Oh)楽だ(Rakuda): "Oh, it's easy!"
    
A good name for Perlish OCaml, isn't it ?

How to install
====================

Via OPAM
--------------

    :::sh
    $ opam install orakuda

General syntax
===================================================

ppx_orakuda provides the following syntax for each literal extension X:

* {X|...|X}
* [%X "..." ]
* [%X {|...|} ]

Perl like PCRE `{m|...|m}`
===================================================

SYNTAX
------------------

        {m|regular expression|m}
        {m|regular expression/flags|m}
    
        flags ::= [imsxU8]*    8 is for UTF8
    
`{m|...|m}` expression creates a PCRE expression. You can write regexps more
naturally than `Pcre.create "..."` where you have to escape `'\'`
characters: `Pcre.create "function\\(arg\\)"` can be written more simply
as `{m|function\(arg\)|m}`.

PCRE creation `{m|...|m}`
-----------------------------------------

The type of `{m|...|m}` expression is not `Pcre.regexp` but `'a Regexp.t`, where
the type parameter `'a` encodes accessor information of the regexp's
groups. See GROUP OBJECT METHODS for details:

```ocaml
# {m|(hello)world(?P<name>[a-z]+)|m};;
- : < _0 : string; _1 : string; _2 : string; _group : int -> string;
      _groups : string array; _left : string;
      _named_group : string -> string;
      _named_groups : (string * string) list; _right : string;
      _unsafe_group : int -> string; name : string >
    Orakuda.Std.Regexp.t
```

In non-toplevel environment, a regular expression by `{m|...|m}` is defined
just ONCE at the top of the source file, no matter where it is
declared. Therefore uses of `{m|...|m}` expressions inside frequently called
functions have NO runtime penalty.

SIMPLE MATCH
----------------------------------
    
In `Orakuda.Std.Regexp` module, `exec_exn`, `Infix.(=~)` and `exec` 
are for simple regexp matching and return group objects 
if matches are successful. The matched groups can be retrieved through them:

```ocaml
# let res = "123 + variable12;;" =~ {m|([a-z_][_A-Za-z0-9]*)|m};;
val res :
< _0 : string; _1 : string; _group : int -> string; _groups : string array;
  _left : string; _named_group : string -> string;
  _named_groups : (string * string) list; _right : string;
  _unsafe_group : int -> string > =
<obj>
```
    
GROUP OBJECT METHODS
----------------------------------
    
`_0` .. `_9`        
        Correspond with `$0` .. `$9` in Perl regexp match

`_left`, `_right`   
        Correspond with `$`` and `$'`

name            
        Accessor for named groups, defined by Python
        extension of named groups: `(?P<name>regexp)`

`_named_gruop`, `_named_gruops`, `_unsafe_group`
        More primitive group accessor methods

Perl like PCRE case match `case s |> ( {m|...|m} ==> f ) ...`
=================================================================

SYNTAX
------------

       case s 
       |> ( {m|...|m}  ==>  fun res -> ...)
       | ...
       |> ( {m|...|m}  ==>  fun res -> ...)
       |> default (fun () -> ...)

Module `Orakuda.Std.Regexp.Infix` provides `case`, `(==>)` and `default`
which are useful to write down multiple regular expression pattern match cases.
For example:


```ocaml
# open Orakuda.Std.Regep.Infix;;
# case "variable123" 
  |>  ( {m|^[0-9]+$|m}             ==> fun v -> `Int (int_of_string v#_0) )
  |>  ( {m|^[a-z][A-Za-z0-9_]*$|m} ==> fun v -> `Variable v#_0 )
  |>  default  (fun () -> failwith "parse error");;
- : [> `Int of int | `Variable of string ] = `Variable "variable123"
```

Perl like PCRE substitution `{s|.../...|s}`
===============================================

SYNTAX
--------

```ocaml
{s|regular expression/template|s}
{s|regular expression/template/flags|s}
```

Perl like sprintf. `{qq|...|qq}`
===================================

SYNTAX
--------------

```ocaml
{qq|...|qq}
```
    
Short hand of `Printf.sprintf "..."` with inlined variable and
expression embed by `$`-notation. It runs faster than `Printf.sprintf`,
since the interpretation of the format string is done at compile time.
    
EXAMPLE
---------------------
    
`{qq|... $foo123 ...|qq}`
    Equivalent to `Printf.sprintf "... %s ..." foo123`

`[%qq "... ${Hashtbl.find tbl k} ..."]`
    Equivalent to `Printf.sprintf "... %s ..." (Hashtbl.find tbl k)`

`{qq|...%${var}02d...|qq}`
    Equivalent to `Printf.sprintf "...%02d..." var`

`{qq|...%s...%${var}02d...|qq}`
    Equivalent to `fun s -> Printf.sprintf "...%s...%02d..." s var`

`{qq|...\$...|qq}`
    To have `$`, you must escape it.

Perl like sub-shell call `{qx|...|qx}`
========================================

SYNTAX
---------

```ocaml
{qx|command line|qx}
```

Sub-shell call of `command line` by a function `Qx.command`.
For example:

```ocaml
{qx|cat file.txt >> dest.txt|qx}
```

This is the user's repsponsibility to define `Qx.command` in 
the current scope. `Orakuda.Qx.command` provides an example of such a function. 
