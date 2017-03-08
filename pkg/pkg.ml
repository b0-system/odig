#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let etc_dir =
  let doc = "Use $(docv) as the etc install directory" in
  Conf.(key "etc-dir" fpath ~absent:"etc" ~doc)

let lib_dir =
  let doc = "Use $(docv) as the lib directory" in
  let absent () =
    let opam = Conf.tool "opam" `Host_os in
    OS.Cmd.(run_out Cmd.(opam % "config" % "var" % "lib") |> to_string)
  in
  Conf.(discovered_key "lib-dir" fpath ~absent ~doc)

let etc_config c = match Conf.build_context c with
| `Dev -> Ok ()
| `Pin | `Distrib ->
    let etc_dir = Conf.value c etc_dir in
    let config = strf "let dir = Fpath.v %S\n" etc_dir in
    OS.File.write "src/odig_etc.ml" config

let top_config c = match Conf.build_context c with
| `Dev -> Ok ()
| `Pin | `Distrib ->
    let bootf = "src/odig.bytetop" in
    let lib_dir = Conf.value c lib_dir in
    OS.File.read bootf >>= fun boot ->
    OS.File.write_subst bootf ["LIBDIR", lib_dir] boot

let pre c = etc_config c >>= fun () -> top_config c
let build = Pkg.build ~pre ()

let () =
  Pkg.describe "odig" ~build @@ fun c ->
  Ok [ Pkg.mllib ~api:["Odig"] "src/odig.mllib";
       Pkg.mllib "src/odig_cli.mllib";
       Pkg.lib "src/odig.bytetop" ~dst:"../ocaml/odig.top";
       Pkg.bin "src-bin/odig_bin" ~dst:"odig";
       Pkg.etc "etc/odig.conf";
       Pkg.etc "etc/odoc.css";
       Pkg.etc "etc/ocamldoc.css";
       Pkg.bin "toys/metagen" ~dst:"metagen";
       Pkg.bin "toys/linkable" ~dst:"linkable"; ]
