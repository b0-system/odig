Linenoise in OCaml
--------------------

# Benefits
1. BSD licensed.
2. No system dependencies, no need for `readline` on your machine.
3. Related to 2, these bindings are self-contained, the source for
   `linenoise` is in this repo and compiled all together with the
   `OCaml`.
4. Written in OCaml.
5. Pretty cool hints feature, see the gif.

# Installation

It is easy with `opam`

```shell
$ opam install linenoise
```

See the pretty
documentation [here](http://hyegar.com/ocaml-linenoise/LNoise.html)

# Example code
This example is also included in the repo under examples:

<p align="center" style='min-width:100%'> 
  <img style='min-width:100%' src='example.gif'/> 
</p>


```ocaml
let rec user_input prompt cb =
  match LNoise.linenoise prompt with
  | None -> ()
  | Some v ->
    cb v;
    user_input prompt cb

let () =
  (* LNoise.set_multiline true; *)
  LNoise.set_hints_callback (fun line ->
      if line <> "git remote add " then None
      else Some (" <this is the remote name> <this is the remote URL>",
                 LNoise.Yellow,
                 true)
    );
  LNoise.history_load ~filename:"history.txt" |> ignore;
  LNoise.history_set ~max_length:100 |> ignore;
  LNoise.set_completion_callback begin fun line_so_far ln_completions ->
    if line_so_far <> "" && line_so_far.[0] = 'h' then
      ["Hey"; "Howard"; "Hughes";"Hocus"]
      |> List.iter (LNoise.add_completion ln_completions);
  end;
  ["These are OCaml bindings to linenoise";
   "get tab completion with <TAB>, type h then hit <TAB>";
   "type quit to exit gracefully";
   "By Edgar Aroutiounian\n"]
  |> List.iter print_endline;
  (fun from_user ->
     if from_user = "quit" then exit 0;
     LNoise.history_add from_user |> ignore;
     LNoise.history_save ~filename:"history.txt" |> ignore;
     Printf.sprintf "Got: %s" from_user |> print_endline
  )
  |> user_input "test_program> "
```
