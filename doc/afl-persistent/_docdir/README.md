# afl-persistent - persistent-mode afl-fuzz for ocaml

by using `AflPersistent.run`, you can fuzz things really fast:

```ocaml
let f () =
  let s = read_line () in
  match Array.to_list (Array.init (String.length s) (String.get s)) with
    ['s'; 'e'; 'c'; 'r'; 'e'; 't'; ' '; 'c'; 'o'; 'd'; 'e'] -> failwith "uh oh"
  | _ -> ()

let _ = AflPersistent.run f
```

compile with a version of ocaml that supports afl. that means trunk
for now, but the next release (4.05) will work too, and pass the
`-afl-instrument` option to ocamlopt.
