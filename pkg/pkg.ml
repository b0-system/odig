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
    OS.File.write "src/opkg_etc.ml" config

let build = Pkg.build ~pre:etc_config ()

let () =
  Pkg.describe "opkg" ~build @@ fun c ->
  Ok [ Pkg.mllib ~api:["Opkg"] "src/opkg.mllib";
       Pkg.mllib "src/opkg_cli.mllib";
       Pkg.bin "src-bin/opkg_bin" ~dst:"opkg";
       Pkg.etc "etc/opkg.conf";
       Pkg.etc "etc/odoc.css";
       Pkg.etc "etc/ocamldoc.css";
       Pkg.test ~run:false "src-bin/opkg_bin"; ]
