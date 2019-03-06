# ocaml-win-error: manipulate Windows system errors

If your application is likely to run on Windows, simply replace uses of
`Unix.error_message` with `Win_error.error_message`. When the application
runs on Windows, Windows system errors will be decoded; when the application
runs elsewhere then the existing `Unix.error_message` function is
called transparently.

A simple example:
```ocaml
try
  let fd = Unix.openfile "/tmp/foo" [ Unix.O_RDONLY ] 0 in
  Unix.close fd
with
| Unix.Unix_error(e, _, _) ->
  Printf.fprintf stderr "Caught: %s\n%!" (Win_error.error_message e)
```

## What's going on?

Errors are typically first thrown by the OCaml standard library as `Unix.Unix_error`
exceptions. In some cases these are mapped onto their Unix equivalents on
such as `Unix.ENOENT`, but when the code isn't recognised OCaml will raise
`Unix.EUNKNOWNERR (-code)`. This library is able to convert these codes back
into human-readable strings.
