(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

type 'a result = (Opkg_pkg.t * 'a) list

type digest_occs =
  { cmis : Opkg_cobj.cmi result;
    cmtis : Opkg_cobj.cmti result;
    cmos : Opkg_cobj.cmo result;
    cmxs : Opkg_cobj.cmx result }

type t = { digests : digest_occs String.Map.t; }

let empty = { cmis = []; cmtis = []; cmos = []; cmxs = [] }

let _create pkgs =
  let add p acc =
    let cobjs = Opkg_pkg.cobjs p in
    let add_obj digest add_obj acc obj =
      let d = digest obj in
      let refs = match String.Map.find d acc with None -> empty | Some r -> r in
      String.Map.add d (add_obj obj refs) acc
    in
    let add_cmi =
      let add_cmi cmi acc = { acc with cmis = (p, cmi) :: acc.cmis } in
      add_obj Opkg_cobj.Cmi.digest add_cmi
    in
    let add_cmti =
      let add_cmti cmti acc = { acc with cmtis = (p, cmti) :: acc.cmtis } in
      add_obj Opkg_cobj.Cmti.digest add_cmti
    in
    let add_cmo =
      let add_cmo cmo acc = { acc with cmos = (p, cmo) :: acc.cmos } in
      add_obj Opkg_cobj.Cmo.cmi_digest add_cmo
    in
    let add_cmx acc cobj =
      let add_cmx cmx acc = { acc with cmxs = (p, cmx) :: acc.cmxs } in
      let acc = add_obj Opkg_cobj.Cmx.cmi_digest add_cmx acc cobj in
      add_obj Opkg_cobj.Cmx.digest add_cmx acc cobj
    in
    let acc = List.fold_left add_cmi acc (Opkg_cobj.cmis cobjs) in
    let acc = List.fold_left add_cmti acc (Opkg_cobj.cmtis cobjs) in
    let acc = List.fold_left add_cmo acc (Opkg_cobj.cmos cobjs) in
    let acc = List.fold_left add_cmx acc (Opkg_cobj.cmxs cobjs) in
    acc
  in
  { digests = Opkg_pkg.Set.fold add pkgs String.Map.empty }

let memo : (Opkg_conf.t, (t, R.msg) Result.result) Hashtbl.t =
  (* FIXME switch to ephemerons (>= 4.03) *) Hashtbl.create 143

let create c = try Hashtbl.find memo c with
| Not_found ->
    let i =
      Opkg_pkg.set c >>| fun pkgs ->
      Opkg_log.time (fun _ m -> m "Created index.") _create pkgs
    in
    Hashtbl.add memo c i;
    i

let find_digest i d = match String.Map.find d i.digests with
| None -> ([], [], [], [])
| Some occs -> (occs.cmis, occs.cmtis, occs.cmos, occs.cmxs)

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
