# let%if is if let backwards

This ppx adds a construct similar to `let if` in Rust.
The following two snippets are equivalent:

```OCaml
let%if Some x = Sys.getenv_opt "HELLO" in
print_endline x
```

```OCaml
match Sys.getenv_opt "HELLO" with
| Some x -> print_endline x
| _ -> ()
```
