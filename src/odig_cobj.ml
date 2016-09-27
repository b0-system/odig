(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

module Digest = Digest

type mli =
  { mli_name : string;
    mli_path : Fpath.t }

type cmi =
  { cmi_name : string;
    cmi_digest : Digest.t;
    cmi_deps : (string * Digest.t option) list;
    cmi_path : Fpath.t; }

type cmti =
  { cmti_name : string;
    cmti_digest : Digest.t;
    cmti_deps : (string * Digest.t option) list;
    cmti_path : Fpath.t; }

type cmo =
  { cmo_name : string;
    cmo_cmi_digest : Digest.t;
    cmo_cmi_deps : (string * Digest.t option) list;
    cmo_cma : cma option;
    cmo_path : Fpath.t }

and cma =
  { cma_name : string;
    cma_cmos : cmo list Lazy.t;
    cma_custom : bool;
    cma_custom_cobjs : string list;
    cma_custom_copts : string list;
    cma_dllibs : string list;
    cma_path : Fpath.t; }

and cmx =
  { cmx_name : string;
    cmx_digest : Digest.t;
    cmx_cmi_digest : Digest.t;
    cmx_cmi_deps : (string * Digest.t option) list;
    cmx_cmx_deps : (string * Digest.t option) list;
    cmx_cmxa : cmxa option;
    cmx_path : Fpath.t }

and cmxa =
  { cmxa_name : string;
    cmxa_cmxs : cmx list Lazy.t;
    cmxa_cobjs : string list;
    cmxa_copts : string list;
    cmxa_path : Fpath.t; }

and cmxs =
  { cmxs_name : string;
    cmxs_path : Fpath.t; }

module Mli = struct
  type t = mli
  let read mli_path =
    OS.File.must_exist mli_path >>| fun _ ->
    let mli_name = Fpath.rem_ext mli_path in
    let mli_name = String.Ascii.capitalize (Fpath.filename mli_name) in
    { mli_name; mli_path }

  let name mli = mli.mli_name
  let path mli = mli.mli_path
end

module Cmi = struct
  type t = cmi

  let read cmi_path =
    Odig_ocamlc.read_cmi cmi_path >>| fun cmi ->
    let cmi_name = Odig_ocamlc.cmi_name cmi in
    let cmi_digest = Odig_ocamlc.cmi_digest cmi in
    let cmi_deps = Odig_ocamlc.cmi_deps cmi in
    { cmi_name; cmi_digest; cmi_deps; cmi_path }

  let name cmi = cmi.cmi_name
  let digest cmi = cmi.cmi_digest
  let deps cmi = cmi.cmi_deps
  let path cmi = cmi.cmi_path
  let compare cmi cmi' = String.compare cmi.cmi_digest cmi'.cmi_digest
end

module Cmti = struct
  type t = cmti

  let read cmti_path =
    Odig_ocamlc.read_cmti cmti_path >>| fun cmti ->
    let cmti_name = Odig_ocamlc.cmti_name cmti in
    let cmti_digest = Odig_ocamlc.cmti_digest cmti in
    let cmti_deps = Odig_ocamlc.cmti_deps cmti in
    { cmti_name; cmti_digest; cmti_deps; cmti_path }

  let name cmti = cmti.cmti_name
  let digest cmti = cmti.cmti_digest
  let deps cmti = cmti.cmti_deps
  let path cmti = cmti.cmti_path
end

module Cmo = struct
  type t = cmo

  let of_ocamlc_cmo cmo_path ~cmo_cma cmo =
    let cmo_name = Odig_ocamlc.cmo_name cmo in
    let cmo_cmi_digest = Odig_ocamlc.cmo_cmi_digest cmo in
    let cmo_cmi_deps = Odig_ocamlc.cmo_cmi_deps cmo in
    { cmo_name; cmo_cmi_digest; cmo_cmi_deps; cmo_cma; cmo_path }

  let read cmo_path =
    Odig_ocamlc.read_cmo cmo_path >>| fun cmo ->
    of_ocamlc_cmo cmo_path ~cmo_cma:None cmo

  let name cmo = cmo.cmo_name
  let cmi_digest cmo = cmo.cmo_cmi_digest
  let cmi_deps cmo = cmo.cmo_cmi_deps
  let cma cmo = cmo.cmo_cma
  let path cmo = cmo.cmo_path
end

module Cma = struct
  type t = cma

  let read cma_path =
    Odig_ocamlc.read_cma cma_path >>| fun cma ->
    let cma_name = Odig_ocamlc.cma_name cma in
    let cma_custom = Odig_ocamlc.cma_custom cma in
    let cma_custom_cobjs = Odig_ocamlc.cma_custom_cobjs cma in
    let cma_custom_copts = Odig_ocamlc.cma_custom_copts cma in
    let cma_dllibs = Odig_ocamlc.cma_dllibs cma in
    let cmos = Odig_ocamlc.cma_cmos cma in
    let rec cma_cmos =
      lazy (List.map (Cmo.of_ocamlc_cmo cma_path ~cmo_cma:(Some cma)) cmos)
    and cma = { cma_name; cma_custom; cma_custom_cobjs; cma_custom_copts;
                cma_dllibs; cma_cmos; cma_path }
    in
    (* make sure it is forced for marshalling. *)
    ignore (Lazy.force cma.cma_cmos);
    cma

  let name cma = cma.cma_name
  let cmos cma = Lazy.force cma.cma_cmos
  let custom cma = cma.cma_custom
  let custom_cobjs cma = cma.cma_custom_cobjs
  let custom_copts cma = cma.cma_custom_copts
  let dllibs cma = cma.cma_dllibs
  let path cma = cma.cma_path
end

module Cmx = struct
  type t = cmx

  let of_ocamlc_cmx cmx_path ~cmx_cmxa cmx =
    let cmx_name = Odig_ocamlc.cmx_name cmx in
    let cmx_digest = Odig_ocamlc.cmx_digest cmx in
    let cmx_cmi_digest = Odig_ocamlc.cmx_cmi_digest cmx in
    let cmx_cmi_deps = Odig_ocamlc.cmx_cmi_deps cmx in
    let cmx_cmx_deps = Odig_ocamlc.cmx_cmx_deps cmx in
    { cmx_name; cmx_digest; cmx_cmi_digest; cmx_cmi_deps; cmx_cmx_deps;
      cmx_cmxa; cmx_path }

  let read cmx_path =
    Odig_ocamlc.read_cmx cmx_path >>| fun cmo ->
    of_ocamlc_cmx cmx_path ~cmx_cmxa:None cmo

  let name cmx = cmx.cmx_name
  let digest cmx = cmx.cmx_digest
  let cmi_digest cmx = cmx.cmx_digest
  let cmi_digest cmx = cmx.cmx_cmi_digest
  let cmi_deps cmx = cmx.cmx_cmi_deps
  let cmx_deps cmx = cmx.cmx_cmx_deps
  let cmxa cmx = cmx.cmx_cmxa
  let path cmx = cmx.cmx_path
end

module Cmxa = struct
  type t = cmxa

  let read cmxa_path =
    Odig_ocamlc.read_cmxa cmxa_path >>| fun cmxa ->
    let cmxa_name = Odig_ocamlc.cmxa_name cmxa in
    let cmxa_cobjs = Odig_ocamlc.cmxa_cobjs cmxa in
    let cmxa_copts = Odig_ocamlc.cmxa_copts cmxa in
    let cmxs = Odig_ocamlc.cmxa_cmxs cmxa in
    let rec cmxa_cmxs =
      lazy (List.map (Cmx.of_ocamlc_cmx cmxa_path ~cmx_cmxa:(Some cmxa)) cmxs)
    and cmxa = { cmxa_name; cmxa_cmxs; cmxa_cobjs; cmxa_copts; cmxa_path }
    in
    (* make sure it is forced for marshalling. *)
    ignore (Lazy.force cmxa.cmxa_cmxs);
    cmxa

  let name cmxa = cmxa.cmxa_name
  let cmxs cmxa = Lazy.force cmxa.cmxa_cmxs
  let cobjs cmxa = cmxa.cmxa_cobjs
  let copts cmxa = cmxa.cmxa_copts
  let path cmxa = cmxa.cmxa_path
end

module Cmxs = struct
  type t = cmxs

  let read cmxs_path =
    Odig_ocamlc.read_cmxs cmxs_path >>| fun cmxs ->
    let cmxs_name = Odig_ocamlc.cmxs_name cmxs in
    { cmxs_name; cmxs_path }

  let name cmxs = cmxs.cmxs_name
  let path cmxs = cmxs.cmxs_path
end


let compare_by_name name o o' = compare (name o) (name o)

type set =
  { mlis : mli list;
    cmis : cmi list;
    cmtis : cmti list;
    cmos : cmo list;
    cmas : cma list;
    cmxs : cmx list;
    cmxas : cmxa list;
    cmxss : cmxs list;
 }

let empty_set =
  { mlis = []; cmis = []; cmtis = []; cmos = []; cmas = [];
    cmxs = []; cmxas = []; cmxss = [] }

let mlis s = s.mlis
let cmis s = s.cmis
let cmtis s = s.cmtis
let cmos ?(files = false) s =
  if files then s.cmos else
  let by_name = compare_by_name Cmo.name in
  List.(sort by_name @@ rev_append s.cmos (flatten (rev_map Cma.cmos s.cmas)))

let cmas s = s.cmas
let cmxs ?(files = false) s =
  if files then s.cmxs else
  let by_name = compare_by_name Cmx.name in
  List.(sort by_name @@ rev_append s.cmxs (flatten (rev_map Cmxa.cmxs s.cmxas)))

let cmxas s = s.cmxas
let cmxss s = s.cmxss

let set_of_dir dir =
  let elements = `Files in
  let add_cobj read f objs =
    (read f >>| fun obj -> obj :: objs)
    |> Odig_log.on_error_msg ~use:(fun _ -> objs)
  in
  let add f acc = match Fpath.get_ext f with
  | ".mli" -> { acc with mlis = add_cobj Mli.read f acc.mlis }
  | ".cmi" -> { acc with cmis = add_cobj Cmi.read f acc.cmis }
  | ".cmti" -> { acc with cmtis = add_cobj Cmti.read f acc.cmtis }
  | ".cmo" -> { acc with cmos = add_cobj Cmo.read f acc.cmos }
  | ".cma" -> { acc with cmas = add_cobj Cma.read f acc.cmas }
  | ".cmx" -> { acc with cmxs = add_cobj Cmx.read f acc.cmxs }
  | ".cmxa" -> { acc with cmxas = add_cobj Cmxa.read f acc.cmxas }
  | ".cmxs" -> { acc with cmxss = add_cobj Cmxs.read f acc.cmxss }
  | _ -> acc
  in
  (OS.Dir.fold_contents ~elements add empty_set dir)
  |> Odig_log.on_error_msg ~use:(fun _ -> empty_set)

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
