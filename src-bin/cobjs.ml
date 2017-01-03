(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private


let cobj_mli f =
  let digest _ = strf "%a" Cobj.Digest.pp_opt None in
  let deps _ = [] in
  Cobj.Mli.(f name digest deps path)

let cobj_cmi f = Cobj.Cmi.(f name digest deps path)
let cobj_cmti f = Cobj.Cmti.(f name digest deps path)
let cobj_cmo f = Cobj.Cmo.(f name cmi_digest cmi_deps path)
let cobj_cmx f = Cobj.Cmx.(f name cmi_digest cmi_deps path)
let cobj_cmt f = Cobj.Cmt.(f name cmi_digest cmi_deps path)

(* Print *)

let print_deps deps =
  let print_dep (n, d) = strf "  %a %s\n" Cobj.Digest.pp_opt d n in
  String.concat ~sep:"" List.(rev @@ rev_map print_dep deps)

let print_cobj
    name digest deps path ~show_loc ~show_pkg ~show_deps p obj
  =
  let pre = if show_pkg then strf "%s " (Pkg.name p) else "" in
  let info = strf "%a %s" Cobj.Digest.pp (digest obj) (name obj) in
  let path = if show_loc then strf " %a" Fpath.pp (path obj) else "" in
  let deps = if show_deps then print_deps (deps obj) else "" in
  strf "%s%s%s\n%s" pre info path deps

let print_mli = cobj_mli print_cobj
let print_cmi = cobj_cmi print_cobj
let print_cmti = cobj_cmti print_cobj
let print_cmo = cobj_cmo print_cobj
let print_cmx = cobj_cmx print_cobj
let print_cmt = cobj_cmt print_cobj

let print_cobjs ~print_cobj ~show_loc ~show_pkg ~show_deps fields =
  let str = print_cobj ~show_loc ~show_pkg ~show_deps in
  let print_field (p, cobj) = print_string (str p cobj) in
  List.iter print_field fields;
  ()

(* Json *)

let json_deps deps =
  let add_dep acc (n, d) =
    let digest = strf  "%a" Cobj.Digest.pp_opt d in
    Json.(acc ++ el (obj @@ mem "name" (str n) ++ mem "digest" (str digest)))
  in
  Json.(arr @@ List.fold_left add_dep empty deps)

let json_cobj
  name digest_str deps path ~show_loc ~show_pkg ~show_deps (p, o) =
  let deps () = json_deps (deps o) in
  let path () = Json.str (Fpath.to_string @@ path o) in
  let pkg () = Json.str (Pkg.name p) in
  let digest = Json.str (digest_str o) in
  let name = Json.str (name o) in
  Json.(obj @@
        mem_if show_pkg "pkg" pkg ++
        mem "name" name ++
        mem "digest" digest ++
        mem_if show_loc "path" path ++
        mem_if show_deps "deps" deps)

let json_mli = cobj_mli json_cobj
let json_cmi = cobj_cmi json_cobj
let json_cmti = cobj_cmti json_cobj
let json_cmo = cobj_cmo json_cobj
let json_cmx = cobj_cmx json_cobj
let json_cmt = cobj_cmt json_cobj
let json_cobjs ~json_cobj ~show_loc ~show_pkg ~show_deps vs =
  let json_cobj = json_cobj ~show_loc ~show_pkg ~show_deps in
  let add_el a v = Json.(a ++ el (json_cobj v)) in
  let arr = Json.(arr @@ List.fold_left add_el empty vs) in
  Json.output stdout arr;
  ()

(* Command *)

let show
    ~kind ~get ~print_cobj ~json_cobj
    conf pkgs warn_error show_loc show_pkg show_deps json
  =
  begin
    let undefined v = false in
    Cli.lookup_pkgs conf pkgs >>= fun pkgs ->
    match Pkg_field.lookup ~warn_error ~kind ~get ~undefined pkgs with
    | Error () -> Ok 1
    | Ok vs ->
        let vs = Pkg_field.flatten ~rev:false vs in
        begin match json with
        | true -> json_cobjs ~json_cobj ~show_loc ~show_pkg ~show_deps vs
        | false -> print_cobjs ~print_cobj ~show_loc ~show_pkg ~show_deps vs
        end;
        Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let cmd_info ~cmd ~kind =
  let kinds =
    if kind.[String.length kind - 1] = 's' then kind else kind ^ "s"
  in
  let doc = strf "Show the %s files of a package" kind in
  let man =
    [ `S "DESCRIPTION";
      `P (strf "The $(b,$(tname)) command shows the %s of a package.
                See odig-packaging(7) to understand how %s are found
                by odig." kind kinds);
    ] @ Cli.common_man @ [
      `S "EXIT STATUS";
      `P "The $(b,$(tname)) command exits with one of the following values:";
      `I ("0", "packages exist and the lookups succeeded.");
      `I ("1", "with $(b,--warn-error), a lookup is undefined.");
      `I (">1", "an error occured.");
    ] @ Cli.see_also_main_man
  in
  Cmdliner.Term.info cmd ~sdocs:Cli.common_opts ~doc ~man

let show_deps =
  let doc = "Show the dependencies of the compilation object."
  in
  Arg.(value & flag & info ["d"; "show-deps"] ~doc)

let show_loc =
  let doc = "Show the location of the compilation object." in
  Arg.(value & flag & info ["l"; "show-loc"] ~doc)

let cmd cmd ~kind ~get ~print_cobj ~json_cobj =
  let info = cmd_info ~cmd ~kind in
  let term =
    Term.(const (show ~kind ~get ~print_cobj ~json_cobj) $ Cli.setup () $
          Cli.pkgs_or_all $ Cli.warn_error $ show_loc $ Cli.show_pkg $
          show_deps $ Cli.json)
  in
  term, info

(* Commands *)

let get cobj p = Ok (cobj (Pkg.cobjs p))

let mli_cmd =
  cmd "mli" ~kind:"mli" ~get:(get Cobj.mlis)
    ~print_cobj:print_mli ~json_cobj:json_mli

let cmi_cmd =
  cmd "cmi" ~kind:"cmi" ~get:(get Cobj.cmis)
    ~print_cobj:print_cmi ~json_cobj:json_cmi

let cmti_cmd =
  cmd "cmti" ~kind:"cmti" ~get:(get Cobj.cmtis)
    ~print_cobj:print_cmti ~json_cobj:json_cmti

let cmo_cmd =
  cmd "cmo" ~kind:"cmo" ~get:(get Cobj.cmos)
    ~print_cobj:print_cmo ~json_cobj:json_cmo

let cmx_cmd =
  cmd "cmx" ~kind:"cmx" ~get:(get Cobj.cmxs)
    ~print_cobj:print_cmx ~json_cobj:json_cmx

let cmt_cmd =
  cmd "cmt" ~kind:"cmt" ~get:(get Cobj.cmts)
    ~print_cobj:print_cmt ~json_cobj:json_cmt

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
