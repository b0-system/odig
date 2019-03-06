ppx_csv_conv
============

Generate functions to read/write records in csv format.

`ppx_csv_conv` generates functions to output some records as a csv
file, and read the records back from a list of strings coming from a
csv file or a database query.

Usage
-----

Annotate the type: [@@deriving fields, csv]

```ocaml
type t = {
  field : ...
  ....
} [@@deriving fields, csv]
```

Csv uses fields so fields is also required. Now the functions listed
in `Csvfields.Csv.Csvable` are included in the module, including
conversion to and from string lists, dumping to files, and loading
files.

The `Csvfields.Csv` module provides the `Atom` functor, which accepts a
Stringable module to produce the necessary functions for recursive
calls:

```ocaml
module Date = struct
  include Date
  include (Csvfields.Csv.Atom (Date) : Csvfields.Csv.Csvable with type t := t)
end

type t = {
  a : float;
  b : string;
  c : int;
  e : Date.t;
} [@@deriving fields, csv]
```

Generate code/functions with types:

```ocaml
include (Csvfields.Csv.Csvable with type  t :=  t)
```

(Known) limitations:
--------------------

- No `option`, `ref`, or `lazy_t` types allowed.
- No variant types ... nothing other than primitive types and
  records. You should create your own stringable version of those
  types and use the `Atom` functor.
- The name of the type must be `t`.
