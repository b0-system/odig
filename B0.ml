open B0_kit.V000
open B00_std

(* OCaml library names *)

let cmdliner = B0_ocaml.lib "cmdliner"
let unix = B0_ocaml.lib "unix"
let b00_std = B0_ocaml.lib "b0.b00.std"
let b00 = B0_ocaml.lib "b0.b00"
let b00_kit = B0_ocaml.lib "b0.b00.kit"

(* Units *)

let odig_tool =
  let requires = [cmdliner; b00_std; b00; b00_kit ] in
  let srcs = [`Dir "src"] in
  B0_ocaml.Unit.exe "odig" ~doc:"odig tool" ~requires ~srcs

(* Packs *)

let default =
  let units = B0_unit.list () in
  let meta = B0_meta.v @@ B0_meta.[
      authors, ["The odig programmers"];
      maintainers, ["Daniel Bünzli <daniel.buenzl i@erratique.ch>"];
      homepage, "https://erratique.ch/software/odig";
      online_doc, "https://erratique.ch/software/odig/doc";
      doc_tags, ["build"; "dev"; "doc"; "meta"; "packaging";
                 "org:erratique"; "org:b0-system"];
      licenses, ["ISC"; "PT-Sans-fonts"; "DejaVu-fonts"];
      repo, "git+https://erratique.ch/repos/odig.git";
      issues, "https://github.com/b0-system/odig/issues"; ]
  in
  B0_pack.v "default" ~doc:"brzo tool" ~meta ~locked:true units
