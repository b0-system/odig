#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let etc_dir =
  let doc = "Use $(docv) as the etc install directory" in
  Conf.(key "etc-dir" fpath ~absent:"etc" ~doc)

let etc_config c = match Conf.build_context c with
| `Dev -> Ok ()
| `Pin | `Distrib ->
    let etc_dir = Conf.value c etc_dir in
    let config = strf "let dir = Fpath.v %S\n" etc_dir in
    OS.File.write "src/odig_etc.ml" config

let build = Pkg.build ~pre:etc_config ()

let () =
  Pkg.describe "odig" ~build @@ fun c ->
  Ok [ Pkg.mllib ~api:["Odig"] "src/odig.mllib";
       Pkg.mllib "src/odig_cli.mllib";
       Pkg.mllib "src/odig_top.mllib";
       Pkg.bin "src-bin/odig_bin" ~dst:"odig";
       Pkg.etc "etc/odig.conf";
       Pkg.etc "etc/odoc.css";
       Pkg.etc "etc/ocamldoc.css";
       Pkg.bin "toys/metagen" ~dst:"metagen"; ]
