MLT Parser
==========

Mlt_parser contains functions for parsing `*.mlt` files, which contain
OCaml toplevel sessions -- i.e., a series of statements followed by
their output (in the form of [expect
tests](https://github.com/janestreet/toplevel_expect_test)).

The first of these functions, `split_chunks`, was extracted out of
[Toplevel_expect_test](https://github.com/janestreet/toplevel_expect_test),
where it's used to divide the toplevel session into "chunks", where
each chunk comprises a set of toplevel code phrases (statements
separated by `;;`) and the expect test they precede.

The second, `parse`, is used by a tool that converts `*.mlt` files
into `*.org` files. That tool needs to be able to distinguish OCaml
code phrases, expect tests, and blocks of org-mode markup (delimited
by `[%%org]` annotations).
