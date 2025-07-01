open B0_kit.V000

(* OCaml library names *)

let b0_file = B0_ocaml.libname "b0.file"
let b0_kit = B0_ocaml.libname "b0.kit"
let b0_memo = B0_ocaml.libname "b0.memo"
let b0_std = B0_ocaml.libname "b0.std"
let cmdliner = B0_ocaml.libname "cmdliner"

let odig_support = B0_ocaml.libname "odig.support"

(* Units *)

let odig_support_lib =
  let srcs =
    [`Dir ~/"src"; `X ~/"src/gh_pages_amend.ml"; `X ~/"src/odig_main.ml"]
  in
  let requires = [ b0_std; b0_memo; b0_file; b0_kit; ] in
  B0_ocaml.lib odig_support ~srcs ~requires

let odig_tool =
  let srcs = [`File ~/"src/odig_main.ml"] in
  let requires = [ cmdliner; b0_std; b0_memo; b0_file; b0_kit; odig_support ] in
  B0_ocaml.exe "odig" ~public:true ~requires ~srcs

let gh_pages_amend =
  let doc = "GitHub pages publication tool" in
  let requires = [ cmdliner; b0_std; b0_memo; b0_file; b0_kit ] in
  let srcs = [`File ~/"src/gh_pages_amend.ml"] in
  B0_ocaml.exe "gh-pages-amend" ~public:true ~doc ~requires ~srcs

(* Testing *)

let publish_sample =
  let srcs = [ `File ~/"sample/publish.ml" ] in
  let requires = [ cmdliner; b0_std; b0_file (* For B0_cli *) ; b0_kit ] in
  B0_ocaml.exe "publish-sample" ~requires ~srcs ~doc:"Publish sample tool"

(* Packs *)

let default =
  let meta =
    B0_meta.empty
    |> ~~ B0_meta.authors ["The odig programmers"]
    |> ~~ B0_meta.maintainers ["Daniel Bünzli <daniel.buenzl i@erratique.ch>"]
    |> ~~ B0_meta.homepage "https://erratique.ch/software/odig"
    |> ~~ B0_meta.online_doc "https://erratique.ch/software/odig/doc"
    |> ~~ B0_meta.description_tags
      ["build"; "dev"; "doc"; "meta"; "packaging"; "org:erratique";
       "org:b0-system"]
    |> ~~ B0_meta.licenses
      ["ISC"; "LicenseRef-ParaType-Free-Font-License";
       "LicenseRef-DejaVu-fonts"]
    |> ~~ B0_meta.repo "git+https://erratique.ch/repos/odig.git"
    |> ~~ B0_meta.issues "https://github.com/b0-system/odig/issues"
    |> B0_meta.tag B0_opam.tag
    |> ~~ B0_opam.build
      {|[["ocaml" "pkg/pkg.ml" "build" "--dev-pkg" "%{dev}%"]]|}
    |> ~~ B0_opam.depends
      [ "ocaml", {|>= "4.14.0"|};
        "ocamlfind", {|build|};
        "ocamlbuild", {|build|};
        "topkg", {|build & >= "1.0.3"|};
        "cmdliner", {|>= "1.3.0"|};
        "odoc", {|>= "2.0.0" |};
        "b0", {|= "0.0.5"|}; ]
  in
  B0_pack.make "default" ~doc:"odig package" ~meta ~locked:true @@
  B0_unit.list ()
