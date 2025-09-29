open B0_kit.V000
open Result.Syntax

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
  let env =
    let doc = "Configure for the opam in the build env" in
    let env env _unit =
      let* opam = B0_env.get_cmd env Cmd.(tool "opam" % "var" % "prefix") in
      let* prefix = Os.Cmd.run_out ~trim:true opam in
      let* prefix = Fpath.of_string prefix in
      Result.ok @@
      (B0_env.env env `Build_env
       |> Os.Env.add "ODIG_CACHE_DIR" "/tmp/odig-cache"
       |> Os.Env.add "ODIG_LIB_DIR" Fpath.(to_string @@ prefix / "lib")
       |> Os.Env.add "ODIG_DOC_DIR" Fpath.(to_string @@ prefix / "doc")
       |> Os.Env.add "ODIG_SHARE_DIR" Fpath.(to_string @@ prefix / "share"))
    in
    `Fun (doc, env)
  in
  let meta = B0_meta.empty |> ~~ B0_unit.Action.env env in
  B0_ocaml.exe "odig" ~meta ~public:true ~requires ~srcs

let gh_pages_amend =
  let doc = "GitHub pages publication tool" in
  let requires = [ cmdliner; b0_std; ] in
  let srcs = [`File ~/"src/gh_pages_amend.ml"] in
  B0_ocaml.exe "gh-pages-amend" ~public:true ~doc ~requires ~srcs

(* Testing *)

let publish_sample =
  let srcs = [ `File ~/"sample/publish.ml" ] in
  let requires = [ cmdliner; b0_std ] in
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
      {|[["ocaml" "pkg/pkg.ml" "build" "--dev-pkg" "%{dev}%"]
         ["cmdliner" "install" "tool-support"
           "--update-opam-install=%{_:name}%.install"
           "_build/src/odig_main.native:odig" {ocaml:native}
           "_build/src/odig_main.byte:odig" {!ocaml:native}
           "_build/src/gh_pages_amend.native:gh-pages-amend" {ocaml:native}
           "_build/src/gh_pages_amend.byte:gh-pages-amend" {!ocaml:native}
           "_build/cmdliner-install"]]|}
    |> ~~ B0_opam.depends
      [ "ocaml", {|>= "4.14.0"|};
        "ocamlfind", {|build|};
        "ocamlbuild", {|build|};
        "topkg", {|build & >= "1.1.0"|};
        "cmdliner", {|>= "2.0.0"|};
        "odoc", {|>= "2.0.0" |};
        "b0", {|= "0.0.6"|}; ]
  in
  B0_pack.make "default" ~doc:"odig package" ~meta ~locked:true @@
  B0_unit.list ()
