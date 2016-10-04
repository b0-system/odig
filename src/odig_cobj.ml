(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

module Digest = struct
  include Digest
  module Set = Asetmap.Set.Make (Digest)
  module Map = Asetmap.Map.Make_with_key_set (Digest) (Set)
  type set = Set.t
  type 'a map = 'a Map.t
end

type digest = Digest.t

type mli =
  { mli_name : string;
    mli_path : Fpath.t }

type cmi =
  { cmi_name : string;
    cmi_digest : digest;
    cmi_deps : (string * digest option) list;
    cmi_path : Fpath.t; }

type cmti =
  { cmti_name : string;
    cmti_digest : digest;
    cmti_deps : (string * digest option) list;
    cmti_path : Fpath.t; }

type cmo =
  { cmo_name : string;
    cmo_cmi_digest : digest;
    cmo_cmi_deps : (string * digest option) list;
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
    cmx_digest : digest;
    cmx_cmi_digest : digest;
    cmx_cmi_deps : (string * digest option) list;
    cmx_cmx_deps : (string * digest option) list;
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
  let compare c0 c1 = Fpath.compare c0.cma_path c1.cma_path

  (* Derived information *)

  let cmi_digests ?(init = Digest.Set.empty) cma =
    let add_cmo acc cmo = Digest.Set.add (Cmo.cmi_digest cmo) acc in
    List.fold_left add_cmo init (Lazy.force cma.cma_cmos)

  let cmi_deps ?(init = Digest.Set.empty) cma =
    let self = cmi_digests cma in
    let add_cmo acc cmo =
      let add_dep acc (_, d) = match d with
      | None -> acc
      | Some d ->
          match Digest.Set.mem d self with
          | true -> acc
          | false -> Digest.Set.add d acc
      in
      List.fold_left add_dep acc (Cmo.cmi_deps cmo)
    in
    List.fold_left add_cmo init (Lazy.force cma.cma_cmos)
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
  let compare c0 c1 = Fpath.compare c0.cmxa_path c1.cmxa_path

  (* Derived information *)

  let cmi_digests ?(init = Digest.Set.empty) cmxa =
    let add_cmx acc cmx = Digest.Set.add (Cmx.cmi_digest cmx) acc in
    List.fold_left add_cmx init (Lazy.force cmxa.cmxa_cmxs)

  let cmi_deps ?(init = Digest.Set.empty) cmxa =
    let self = cmi_digests cmxa in
    let add_cmx acc cmx =
      let add_dep acc (_, d) = match d with
      | None -> acc
      | Some d ->
          match Digest.Set.mem d self with
          | true -> acc
          | false -> Digest.Set.add d acc
      in
      List.fold_left add_dep acc (Cmx.cmi_deps cmx)
    in
    List.fold_left add_cmx init (Lazy.force cmxa.cmxa_cmxs)
end

module Cmxs = struct
  type t = cmxs

  let read cmxs_path =
    Odig_ocamlc.read_cmxs cmxs_path >>| fun cmxs ->
    let cmxs_name = Odig_ocamlc.cmxs_name cmxs in
    { cmxs_name; cmxs_path }

  let name cmxs = cmxs.cmxs_name
  let path cmxs = cmxs.cmxs_path
  let compare c0 c1 = Fpath.compare c0.cmxs_path c1.cmxs_path
end

let compare_by_name name o o' = compare (name o) (name o')

(* Cobj sets. *)

type set =
  { mlis : mli list;
    cmis : cmi list;
    cmtis : cmti list;
    cmos : cmo list;
    cmas : cma list;
    cmxs : cmx list;
    cmxas : cmxa list;
    cmxss : cmxs list; }

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

let err f = function
| Error (`Msg e) -> Odig_log.err (fun m -> m "%a: %a" Fpath.pp f Fmt.text e)
| Ok _ -> assert false

let set_of_dir ?(err = err) dir =
  let add_cobj read f objs = match (read f >>| fun obj -> obj :: objs) with
  | Ok objs -> objs
  | Error _ as e -> err f e; objs
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
  let fold_err f e = err f e; Ok () in
  let elements = `Files in
  match OS.Dir.fold_contents ~err:fold_err ~elements add empty_set dir with
  | Error _ as e -> err dir e; empty_set
  | Ok cobjs -> cobjs

(* Cobj indexes *)

module Index = struct

  type ('a, 'b) result = ('a * 'b) list

  type 'a digest_occs =
    { cmis : ('a, cmi) result;
      cmtis : ('a, cmti) result;
      cmos : ('a, cmo) result;
      cmxs : ('a, cmx) result }

  type 'a t = { digests : 'a digest_occs String.Map.t; }

  let empty_occs = { cmis = []; cmtis = []; cmos = []; cmxs = [] }
  let empty = { digests = String.Map.empty }

  let add_cobjs acc tag cobjs =
    let add_obj digest add_obj acc obj =
      let d = digest obj in
      let refs = match String.Map.find d acc with
      | None -> empty_occs | Some r -> r
      in
      String.Map.add d (add_obj obj refs) acc
    in
    let add_cmi =
      let add_cmi cmi acc = { acc with cmis = (tag, cmi) :: acc.cmis } in
      add_obj Cmi.digest add_cmi
    in
    let add_cmti =
      let add_cmti cmti acc = { acc with cmtis = (tag, cmti) :: acc.cmtis } in
      add_obj Cmti.digest add_cmti
    in
    let add_cmo =
      let add_cmo cmo acc = { acc with cmos = (tag, cmo) :: acc.cmos } in
      add_obj Cmo.cmi_digest add_cmo
    in
    let add_cmx acc cobj =
      let add_cmx cmx acc = { acc with cmxs = (tag, cmx) :: acc.cmxs } in
      let acc = add_obj Cmx.cmi_digest add_cmx acc cobj in
      add_obj Cmx.digest add_cmx acc cobj
    in
    let acc = List.fold_left add_cmi acc (cmis cobjs) in
    let acc = List.fold_left add_cmti acc (cmtis cobjs) in
    let acc = List.fold_left add_cmo acc (cmos cobjs) in
    let acc = List.fold_left add_cmx acc (cmxs cobjs) in
    acc

  let of_set ?(init = empty) v cobjs =
    { init with digests = add_cobjs init.digests v cobjs } [@warning "-23"]

  (* Queries *)

  let find_cobjs i d = match String.Map.find d i.digests with
  | None -> ([], [], [], [])
  | Some occs -> (occs.cmis, occs.cmtis, occs.cmos, occs.cmxs)

  let find_cmi i d = match String.Map.find d i.digests with
  | None -> [] | Some occs -> occs.cmis

  let find_cmti i d = match String.Map.find d i.digests with
  | None -> [] | Some occs -> occs.cmtis

  let find_cmo i d = match String.Map.find d i.digests with
  | None -> [] | Some occs -> occs.cmos

  let find_cmx i d = match String.Map.find d i.digests with
  | None -> []
  | Some occs ->
      let has_cmi_digest (_, cmx) = Cmx.cmi_digest cmx = d in
      List.filter has_cmi_digest occs.cmxs
end

type 'a index = 'a Index.t

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
