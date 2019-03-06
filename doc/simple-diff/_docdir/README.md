# Simple Diff

## Description

Simple Diff is a pure OCaml implementation of a diffing algorithm ported from https://github.com/paulgb/simplediff.

## Usage

`opam install simple-diff`

Below is some example usage in top/utop:

```ocaml
let old_lines = [| "I"; "really"; "like"; "icecream" |]
let new_lines = [| "I"; "do"; "not"; "like"; "icecream" |]

module Diff = Simple_diff.Make(String);;
open Diff;;

get_diff old_lines new_lines;;

#=> [
  Equal [| "I" |];
  Deleted [| "really" |];
  Added [| "do"; "not" |];
  Equal [| "like"; "icecream" |]
]
```

As displayed above, Simple Diff exposes a `Simple_diff.Make` functor which accepts a module that implements the `Simple_diff.Comparable` interface (check out the docs for the interface). This makes `Simple_diff.S.get_diff` work with lists of elements of whatever you type you want (as long as interface is followed).
