#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let () =
  Pkg.describe "odig" @@ fun c ->
  Ok [ Pkg.mllib "src/odig_support.mllib";
       Pkg.bin "src/odig_bin" ~dst:"odig";
       Pkg.bin "src/gh_pages_amend" ~dst:"gh-pages-amend";
       Pkg.etc "themes/ocamldoc.css"; (* still there for topkg doc support *)
       Pkg.share "themes/light/odoc.css" ~dst:"odoc-theme/light/odoc.css";
       Pkg.share "themes/dark/odoc.css" ~dst:"odoc-theme/dark/odoc.css";
       Pkg.doc "doc/index.mld" ~dst:"odoc-pages/index.mld";
       Pkg.doc "doc/manual.mld" ~dst:"odoc-pages/manual.mld";
       Pkg.doc "doc/packaging.mld" ~dst:"odoc-pages/packaging.mld" ]
