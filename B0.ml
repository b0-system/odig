open B0_kit.V000
open B00_std

(* OCaml library names *)

let cmdliner = B0_ocaml.lib "cmdliner"
let b0_b00_std = B0_ocaml.lib "b0.b00.std"
let b0_b00 = B0_ocaml.lib "b0.b00"
let b0_b00_kit = B0_ocaml.lib "b0.b00.kit"
let odig_support = B0_ocaml.lib "odig.support"

(* Units *)

let odig_support_lib =
  let requires = [ b0_b00_std; b0_b00; b0_b00_kit ] in
  let srcs = [`Dir "src"; `X "src/gh_pages_amend.ml"; `X "src/odig_main.ml"] in
  B0_ocaml.Unit.lib odig_support ~doc:"odig support library" ~requires ~srcs

let odig_tool =
  let requires = [ cmdliner; b0_b00_std; b0_b00; b0_b00_kit; odig_support ] in
  let srcs = [`File "src/odig_main.ml"] in
  B0_ocaml.Unit.exe "odig" ~doc:"odig tool" ~requires ~srcs

let gh_pages_amend =
  let requires = [ cmdliner; b0_b00_std; b0_b00; b0_b00_kit ] in
  let srcs = [`File "src/gh_pages_amend.ml"] in
  let doc = "GitHub pages publication tool" in
  B0_ocaml.Unit.exe "gh-pages-amend" ~doc ~requires ~srcs

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
  B0_pack.v "default" ~doc:"The odig project" ~meta ~locked:true units
