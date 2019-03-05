#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let theme t =
  let src f = strf "themes/%s/%s" t f in
  let dst f = strf "odoc-theme/%s/%s" t f in
  let mv f = Pkg.share (src f) ~dst:(dst f) in
  Pkg.flatten
  [ mv "odoc.css"; mv "theme.css"; mv "manual.css";
    mv "fonts/fonts.css";
    mv "fonts/DejaVuSansMono-Bold.woff2";
    mv "fonts/DejaVuSansMono-BoldOblique.woff2";
    mv "fonts/DejaVuSansMono-Oblique.woff2";
    mv "fonts/DejaVuSansMono.woff2";
    mv "fonts/PTC55F.woff2";
    mv "fonts/PTC75F.woff2";
    mv "fonts/PTS55F.woff2";
    mv "fonts/PTS56F.woff2";
    mv "fonts/PTS75F.woff2";
    mv "fonts/PTS76F.woff2"; ]

let () =
  Pkg.describe "odig" @@ fun c ->
  Ok [ Pkg.mllib "src/odig_support.mllib";
       Pkg.bin "src/odig_bin" ~dst:"odig";
       Pkg.bin "src/gh_pages_amend" ~dst:"gh-pages-amend";
       Pkg.etc "themes/ocamldoc.css"; (* still there for topkg doc support *)
       Pkg.doc "doc/index.mld" ~dst:"odoc-pages/index.mld";
       Pkg.doc "doc/manual.mld" ~dst:"odoc-pages/manual.mld";
       Pkg.doc "doc/packaging.mld" ~dst:"odoc-pages/packaging.mld";
       Pkg.test "sample/publish";
       theme "dark";
       theme "light";
       theme "solarized.dark";
       theme "solarized.light";
       theme "gruvbox.dark";
       theme "gruvbox.light"; ]
