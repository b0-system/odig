open B0_kit.V000

(* OCaml library names *)

let cmdliner = B0_ocaml.libname "cmdliner"
let b0_std = B0_ocaml.libname "b0.std"
let b0_b00 = B0_ocaml.libname "b0.b00"
let b0_b00_kit = B0_ocaml.libname "b0.b00.kit"
let odig_support = B0_ocaml.libname "odig.support"

(* Units *)

let odig_support_lib =
  let requires = [ b0_std; b0_b00; b0_b00_kit ] in
  let srcs = Fpath.[`Dir (v "src");
                    `X (v "src/gh_pages_amend.ml"); `X (v "src/odig_main.ml")] in
  B0_ocaml.lib odig_support ~doc:"odig support library" ~requires ~srcs

let odig_tool =
  let requires = [ cmdliner; b0_std; b0_b00; b0_b00_kit; odig_support ] in
  let srcs = Fpath.[`File (v "src/odig_main.ml")] in
  B0_ocaml.exe "odig" ~doc:"odig tool" ~requires ~srcs

let gh_pages_amend =
  let requires = [ cmdliner; b0_std; b0_b00; b0_b00_kit ] in
  let srcs = Fpath.[`File (v "src/gh_pages_amend.ml")] in
  let doc = "GitHub pages publication tool" in
  B0_ocaml.exe "gh-pages-amend" ~doc ~requires ~srcs

(* Packs *)

let default =
  let units = B0_unit.list () in
  let meta =
    let open B0_meta in
    empty
    |> add authors ["The odig programmers"]
    |> add maintainers ["Daniel Bünzli <daniel.buenzl i@erratique.ch>"]
    |> add homepage "https://erratique.ch/software/odig"
    |> add online_doc "https://erratique.ch/software/odig/doc"
    |> add description_tags
      ["build"; "dev"; "doc"; "meta"; "packaging"; "org:erratique";
       "org:b0-system"]
    |> add licenses ["ISC"; "LicenseRef-ParaType-Free-Font-License"; "LicenseRef-DejaVu-fonts"]
    |> add repo "git+https://erratique.ch/repos/odig.git"
    |> add issues "https://github.com/b0-system/odig/issues"
    |> add B0_opam.Meta.build
      {|[["ocaml" "pkg/pkg.ml" "build" "--dev-pkg" "%{dev}%"]]|}
    |> add B0_opam.Meta.depends
      [ "ocaml", {|>= "4.08"|};
        "ocamlfind", {|build|};
        "ocamlbuild", {|build|};
        "topkg", {|build & >= "1.0.3"|};
        "cmdliner", {|>= "1.1.0"|};
        "odoc", {|>= "2.0.0" |};
        "b0", {|= "0.0.4"|}; ]
    |> tag B0_opam.tag
  in
  B0_pack.v "default" ~doc:"The odig project" ~meta ~locked:true units
