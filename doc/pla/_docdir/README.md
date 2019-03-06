![Pla](/resources/pla.png?raw=true "Pla")

Pla is a simple library and ppx syntax extension to create composable templates based on verbatim strings.

[Project page](https://modlfo.github.io/pla/)

[Full API](https://modlfo.github.io/pla/pla_ppx.docdir/Pla.html)

[![Build Status](https://travis-ci.org/modlfo/pla.svg?branch=master)](https://travis-ci.org/modlfo/pla)

## Basic usage

To create templates from basic types you can use the following functions:

```ocaml
let str_template   : Pla.t = Pla.string "text" ;;
let int_template   : Pla.t = Pla.int 1 ;;
let float_template : Pla.t = Pla.float 1.0 ;;
```
Templates from verbatim strings are created using the markers `[%pla{|` to start the string and `|}]` to close it. For example:

```ocaml
let code_template : Pla.t = [%pla{| you can put anything "here" !!! |}] ;;
```
To compose templates you can use the special markers `<#` and `#>`. For example:
```ocaml
let name  : Pla.t = Pla.string "Bob" ;;
let value : Pla.t = Pla.int 10 ;;
let text  : Pla.t = [%pla{|The name is <#name#> and the value is <#value#>|}] ;;
```
When printing the template the markers `<#name#>` and `<#value#>` will be replaced by the contents of the templates `name` and `value` found in the scope.

```ocaml
# Pla.print text ;;
- : bytes = "The name is Bob and the value is 10"
```
Alternatively you can write a template to a file as follows
```ocaml
# Pla.write "file.txt" text ;;
- : unit = ()
```

There exist special markers to print values other than `Pla.t`. To print integers, strings and floats (without needing to convert them to template first) use the following markers:

- `<#...#s>` for string values
- `<#...#i>` for int values
- `<#...#f>` for float values

For example:

```ocaml
let name      : string = "Bob" ;;
let int_val   : int    = 10 ;;
let float_val : float  = 10.0 ;;
let text      : Pla.t  = [%pla{| String <#name#s>, int value <#int_val#i>, float value <#float_val#f>|}] ;;
```

This will produce the following string:
```ocaml
# Pla.print text ;;
- : bytes = "String Bob, int value 10, float value 10.0"
```

The markers are type-checked so if the types do not match you will get a compile error.

There are two special markers more:

- `<#...#+>` this will indent all the contents of the template
- `<#>` this will explicitly insert a new line

For example:
```ocaml
let lines : Pla.t = [%pla{|Line 1<#>Line 2|}] ;;
let text  : Pla.t = [%pla{|The lines are:<#lines#+>|}] ;;
```

will produce the text:
```
The lines are:
   Line 1
   Line 2
```

The Pla library provides a few useful functions
- `join` : appends a list of templates.
- `map_join` : applies the function `f` to each element and appends all the templates.
- `map_sep` : applies the function `f` to each element and appends all the templates separated by the template `sep`.

Pla also provides a few predefined templates:
- `unit` : empty template
- `newline` : to print a new lines
- `comma` : to print a comma
- `semi` : to print a semicolon

Note: You can find more information in the documentation.

One example of using the previous functions is the following:

```ocaml
let data = [1; 2; 3] ;;
let text = Pla.map_sep Pla.comma Pla.int data ;; (* produces: 1,2,3 *)
```

#### Adding Pla to your Project

In order to create templates with `[%pla{|...|}]` you need to preprocess the files with the ppx `pla.ppx` and link with the `pla` library. When using ocamlbuild this can be done by adding the following lines to the `_tags` file:
```
<*.ml>: package(pla.ppx)
<*.byte>: package(pla)
<*.native>: package(pla)
```

#### Features and Limitations

Pla does not provide advanced pretty-printing features like the ones available in libraries like Format or others. On the other hand, it produces fast code whose performance is near to manually written code. Internally, every template is a function that writes text to a `Buffer.t`.

## Installing

```
$ opam install pla
```

### Manual Installation

```
$ ./configure --prefix <#your ocaml directory#>
$ make
$ make install
```

### Requirements

#### Compiler

- OCaml      >= 4.02

#### Libraries

- ocaml-migrate-parsetree
- jbuild

## Syntax for Pla Templates

Templates are delimited by `[%pla{|` and `|}]`. Alternatively, you can use the syntax `{pla|` and `|pla}` to specify templates.

```ocaml
let _ = [%pla{|
This is a verbatim string.
You can put whatever text you want.
The compiler will create the corresponding string.
You don't need to escape the "quotes".
|}];;
```

#### Markers

The following markers in a `[%pla{|...|}]` template are replaced:

- `<#>`       - inserts a new line
- `<#name#>`  - inserts the contents of a `Pla.t` value
- `<#name#s>` - inserts the contents of a `string` value
- `<#name#i>` - inserts the contents of a `int` value
- `<#name#f>` - inserts the contents of a `float` value
- `<#name#+>` - creates an indented block and print the contents of a `Pla.t` value


