Toplevel expectation test
=========================

Overview
--------

Toplevel\_expect\_test is a modified OCaml toplevel that captures its
output and compares it against an expected one. The primary goal is to
test various kind of errors:

- pre-processing errors,
- typing errors,
- compilation errors,
- runtime errors

Since the toplevel is able to print most things out of the box, this
gives an easy way to test the result of an evaluation as well.

Usage
-----

Simply write a .ml file containing the same phrases you would write in
a toplevel, and wherever you want to check the output write
`[%%expect]`. Then run the tool on the file. It will fill the
`[%%expect]` nodes with the real output and write the result in a
`.corrected` file. For convenience, the tool will output the diff
between the original file and the corrected one. You can then copy the
`.corrected` file.

For instance:

```shell
$ cat test.ml
let x = 1 + 'e'
[%%expect]

type t = intt
[%%expect]

$ ocaml-expect test.ml
---test.ml
+++test.ml.corrected
@@@@@@@@@@ -1,6 +1,14 @@@@@@@@@@
  let x = 1 + 'e'
-|[%%expect]
+|[%%expect{|
+|Line _, characters 12-15:
+|Error: This expression has type char but an expression was expected of type
+|         int
+||}]

  type t = intt
-|[%%expect]
+|[%%expect{|
+|Line _, characters 9-13:
+|Error: Unbound type constructor intt
+|Hint: Did you mean int?
+||}]

$ cp test.ml.corrected test.ml
$ ocaml-expect test.ml && echo success
success
```

*Warning:* be sure to write `[%%expect]` with 2 percent signs

Note that you can use whatever directives you use in the toplevel:
`#load`, `#use`, ...

Matching
--------

The matching of the toplevel output against the expectation is done
using [ppx_expect](https://github.com/janestreet/ppx_expect). This
mean that you can use the same modifiers such as `(glob)` or
`(regexp)` in expectations.

Testing the result of an evaluation
-----------------------------------

ocaml-expect doesn't print the toplevel outcome in case of success.
This is because it is often used to test errors. You can change this
behavior at any time using the directive `#verbose`:

```ocaml
#verbose true;;
let x = 6 * 7
[%expect{|
val x : int = 42
|}]
```

Dealing with line numbers
-------------------------

By default ocaml-expect hides line numbers in error messages, as they
can change often and produce useless diffs. You can enable them using
the directive `#print_line_numbers`:

```ocaml
#print_line_numbers true;;
let x = 1 + 2
[%%expect{|
Line 2, characters 12-15:
Error: This expression has type char but an expression was expected of type
         int
|}]
```

Sometimes values contains line numbers, either from a ppx rewriter or
from some special value such as `Pervasives.__LOC__`. Whenever the
expection before some code capturing the line number changes, the line
number will change. This can create annoying differences in a test
suite.

There are two ways to make line numbers predictable:

- write tests sensitive on the location in a file with a single
  `[%%expect]` node
- force the line number with the directive `#reset_line_numbers`

For instance:

```ocaml
Array.make n 0
[%expect{|
- : int array = [|0; 0; 0; 0; 0; 0; 0; 0; 0; 0|]
|}]

#reset_line_number;;
__LINE__
[%expect{|
- : int = 1
|}]
```

Whatever the value of [n] is, the line number of `__LINE__` will
always be 1.

Producing a structured document
-------------------------------

Instead of the normal mode, you can ask the toplevel to produce a
structured document containing a list of code blocks with the toplevel
response.

This is useful when you want to include some code examples with their
output in a document. For that pass the flag `-sexp`:

```
$ cat test.ml
#verbose true;;

let x = 42
[%%expect {|
val x : int = 42
|}]
$ ocaml-expect -sexp test.ml
((parts
  (((name "")
    (chunks
     (((ocaml_code  "#verbose true;;\
                   \n\
                   \nlet x = 42\
                   \n")
       (toplevel_response  "\
                          \nval x : int = 42\
                          \n")))))))
 (matched false))
```

You can use the library `toplevel_expect_test.types` to interpret the
output. You can see the types here
[here](types/toplevel_expect_test_types.mli).

In addition you can add `[@@@part "blah"]` attributes in your code to
organize it. This gives you an easy way to split the results in
different part of the final document.

Building a custom toplevel
--------------------------

You can build a custom toplevel following this example:

```
$ echo 'Toplevel_expect_test.Main.main ()` > main.ml
$ ocamlfind ocamlc -linkpkg -linkall -predicates create_toploop \
    -package toplevel_expect_test -o foo
```

