# Convert md files into odoc mld files

`md2mld` converts a Markdown-format file into the `mld` format used by [odoc](https://github.com/ocaml/odoc) to render HTML documentation or OCaml libraries.  You can use this script to automatically embed a `README.md` file into API documentation for an OCaml  library.

You can use it manually as follows

```
$ md2mld filename.md > outfile.mld
```

In `dune` you can use it to generate an mld file with

```
(rule (with-stdout-to outfile.mld (run md2mld filename.md)))
```

You can see the documentation generated from the latest tagged version of this README at [mseri.github.io/md2mld/md2mld/index.html](http://mseri.github.io/md2mld/md2mld/index.html).


# Known issues

Until the new odoc [fixing #141](https://github.com/ocaml/odoc/issues/141) is released, the minimal header allowed in the `md` file will be the level 3 one `###`.
You can work around this by using the `-min-header 3` flag during the invocation of `md2mld`.

