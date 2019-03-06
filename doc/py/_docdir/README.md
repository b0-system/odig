py — OCaml interface to Python
-------------------------------------------------------------------------------
%%VERSION%%

py is a ctypes interface to Python 3.5+ for OCaml

py is distributed under the ISC license.

Homepage: https://github.com/zshipko/ocaml-py

## Installation

py can be installed with `opam`:

```shell
$ opam install py
```

If your Python installation is not in the typical location you may have to set `OCAML_PY_VERSION` to point to the Python `.so` file.

For example, one way of finding this path:

```shell
$ find `python3 -c 'import sys, os; print(os.path.join(sys.prefix, "lib"))'` -name 'libpython*.so'
```

(That seems to be the most straight forward way, but let me know if there's something better!)

If you'd like to run the tests:

```shell
$ dune runtest
```

## Introduction

Simple conversion from OCaml to Python:
```ocaml
    open Py
    let s = !$(String "a string")
    let f = !$(Float 12.3)
    let i = !$(Int 123)
```
See `src/py.mli` for a full list of types.

Call a function defined in a module and return the result:
```ocaml
    let np = PyModule.import "numpy" in
    let np_array = np $. (String "array") in
    let arr = np_array $ [List [Int 1; Int 2; Int 3]] in
    ...
```
Which is shorthand for
```ocaml
    let np = PyModule.import "numpy" in
    let np_array = Object.get_attr_s np "array" in
    let arr = run np_array [List [Int 1; Int 2; Int 3]] in
    ...
```
Evaluate a string and return the result:
```ocaml
    let arr = eval "[1, 2, 3]" in
    ...
```
Get object index:
```ocaml
    let a = arr $| Int 0 in
    let b = arr $| Int 1 in
    let c = arr $| Int 2 in
    ...
```
Set object index:
```ocaml
    let _ = (a_list, Int 0) <-$| Int 123 in
    let _ = (a_dict, String "key") <-$| String "value" in
    ...
```
Execute a string and return true/false depending on the status returned by Python:
```ocaml
    if exec "import tensorflow" then
        let tf = PyModule.get "tensorflow" in  (* Load an existing module *)
        ...
```
