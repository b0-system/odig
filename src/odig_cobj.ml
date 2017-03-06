(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

let realpath p = match Fpath.is_abs p with (* FIXME real realpath *)
| true -> Ok (Fpath.normalize p)
| false -> OS.Dir.current () >>| fun dir -> Fpath.(normalize @@ dir // p)

(* Compilation object digests. *)

module Digest = struct
  include Digest

  let pp ppf d = Fmt.string ppf (to_hex d)

  let no_digest = String.v 32 (fun _ -> '-')
  let pp_no_digest = Fmt.(const string no_digest)
  let pp_opt = Fmt.(option ~none:pp_no_digest pp)

  module Set = Asetmap.Set.Make (Digest)
  module Map = Asetmap.Map.Make_with_key_set (Digest) (Set)
  type set = Set.t
  type 'a map = 'a Map.t
end

type digest = Digest.t
type dep = string * Digest.t option

let pp_dep ppf (n, digest) = Fmt.pf ppf "@[%s (%a)@]" n Digest.pp_opt digest

(* Generic functions on compilation object archives. *)

module Archive = struct

  let names objs name digest ?(init = String.Map.empty) a =
    let add_obj m o = String.Map.add (name o) (digest o) m in
    List.fold_left add_obj init (objs a)

  let cmi_digests objs name digest ?(init = Digest.Map.empty) a =
    let add_obj m o = Digest.Map.add (digest o) (name o) m in
    List.fold_left add_obj init (objs a)

  let to_cmi_deps objs name digest ?(init = []) a =
    let add_obj acc o = (name o, Some (digest o)) :: acc in
    List.fold_left add_obj init (objs a)

  let log_conflict path a name ~keep:d0 d1 =
    Odig_log.warn
      (fun m -> m "%a: conflicting digests for %s (%a, dropping %a)"
          Fpath.pp (path a) name Digest.pp d0 Digest.pp d1)

  let cmi_deps objs path name digest deps ?conflict:c a =
    let conflict = match c with None -> log_conflict path a | Some c -> c in
    let self_names = names objs name digest a in
    let self_digests = cmi_digests objs name digest a in
    let add_obj acc o =
      let add_dep m (n, d) = match String.Map.find n m with
      | None | Some None ->
          begin match d with
          | None ->
              if String.Map.mem n self_names then m else
              String.Map.add n d m
          | Some dig ->
              if Digest.Map.mem dig self_digests then m else
              String.Map.add n d m
          end
      | Some (Some d0) ->
          begin match d with
          | Some d1 when not (Digest.equal d0 d1) -> conflict n d0 d1; m
          | _ -> m
          end
      in
      List.fold_left add_dep acc (deps o)
    in
    let deps = List.fold_left add_obj String.Map.empty (objs a) in
    String.Map.bindings deps
end

(* Compilation objects *)

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

type ml =
  { ml_name : string;
    ml_path : Fpath.t }

type cmt =
  { cmt_name : string;
    cmt_path : Fpath.t;
    cmt_cmi_digest : digest;
    cmt_cmi_deps : (string * digest option) list; }

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

type cmx =
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

type cmxs =
  { cmxs_name : string;
    cmxs_path : Fpath.t; }

module Mli = struct
  type t = mli
  let read mli_path =
    OS.File.must_exist mli_path >>= fun _ ->
    realpath mli_path >>| fun mli_path ->
    let mli_name = Fpath.rem_ext mli_path in
    let mli_name = String.Ascii.capitalize (Fpath.filename mli_name) in
    { mli_name; mli_path }

  let name mli = mli.mli_name
  let path mli = mli.mli_path
end

module Cmi = struct
  type t = cmi

  let read cmi_path =
    Odig_ocamlc.read_cmi cmi_path >>= fun cmi ->
    realpath cmi_path >>| fun cmi_path ->
    let cmi_name = Odig_ocamlc.cmi_name cmi in
    let cmi_digest = Odig_ocamlc.cmi_digest cmi in
    let cmi_deps = Odig_ocamlc.cmi_deps cmi in
    { cmi_name; cmi_digest; cmi_deps; cmi_path }

  let name cmi = cmi.cmi_name
  let digest cmi = cmi.cmi_digest
  let deps cmi = cmi.cmi_deps
  let path cmi = cmi.cmi_path
  let to_cmi_dep cmi = cmi.cmi_name, Some cmi.cmi_digest
end

module Cmti = struct
  type t = cmti

  let read cmti_path =
    Odig_ocamlc.read_cmti cmti_path >>= fun cmti ->
    realpath cmti_path >>| fun cmti_path ->
    let cmti_name = Odig_ocamlc.cmti_name cmti in
    let cmti_digest = Odig_ocamlc.cmti_digest cmti in
    let cmti_deps = Odig_ocamlc.cmti_deps cmti in
    { cmti_name; cmti_digest; cmti_deps; cmti_path }

  let name cmti = cmti.cmti_name
  let digest cmti = cmti.cmti_digest
  let deps cmti = cmti.cmti_deps
  let path cmti = cmti.cmti_path
  let to_cmi_dep cmti = cmti.cmti_name, Some cmti.cmti_digest
end

module Ml = struct
  type t = ml
  let read ml_path =
    OS.File.must_exist ml_path >>= fun _ ->
    realpath ml_path >>| fun ml_path ->
    let ml_name = Fpath.rem_ext ml_path in
    let ml_name = String.Ascii.capitalize (Fpath.filename ml_name) in
    { ml_name; ml_path }

  let name ml = ml.ml_name
  let path ml = ml.ml_path
end

module Cmo = struct
  type t = cmo

  let of_ocamlc_cmo cmo_path ~cmo_cma cmo =
    let cmo_name = Odig_ocamlc.cmo_name cmo in
    let cmo_cmi_digest = Odig_ocamlc.cmo_cmi_digest cmo in
    let cmo_cmi_deps = Odig_ocamlc.cmo_cmi_deps cmo in
    { cmo_name; cmo_cmi_digest; cmo_cmi_deps; cmo_cma; cmo_path }

  let read cmo_path =
    Odig_ocamlc.read_cmo cmo_path >>= fun cmo ->
    realpath cmo_path >>| fun cmo_path ->
    of_ocamlc_cmo cmo_path ~cmo_cma:None cmo

  let name cmo = cmo.cmo_name
  let cmi_digest cmo = cmo.cmo_cmi_digest
  let cmi_deps cmo = cmo.cmo_cmi_deps
  let cma cmo = cmo.cmo_cma
  let path cmo = cmo.cmo_path

  let to_cmi_dep cmo = cmo.cmo_name, Some cmo.cmo_cmi_digest
end

module Cmt = struct
  type t = cmt

  let read cmt_path =
    Odig_ocamlc.read_cmt cmt_path >>= fun cmt ->
    realpath cmt_path >>| fun cmt_path ->
    let cmt_name = Odig_ocamlc.cmt_name cmt in
    let cmt_cmi_digest = Odig_ocamlc.cmt_cmi_digest cmt in
    let cmt_cmi_deps = Odig_ocamlc.cmt_cmi_deps cmt in
    { cmt_name; cmt_path; cmt_cmi_digest; cmt_cmi_deps }

  let name cmt = cmt.cmt_name
  let path cmt = cmt.cmt_path
  let cmi_digest cmt = cmt.cmt_cmi_digest
  let cmi_deps cmt = cmt.cmt_cmi_deps
end

module Cma = struct
  type t = cma

  let read cma_path =
    Odig_ocamlc.read_cma cma_path >>= fun cma ->
    realpath cma_path >>| fun cma_path ->
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

  (* Derived information *)

  let names = Archive.names cmos Cmo.name Cmo.cmi_digest
  let cmi_digests = Archive.cmi_digests cmos Cmo.name Cmo.cmi_digest
  let to_cmi_deps = Archive.to_cmi_deps cmos Cmo.name Cmo.cmi_digest
  let cmi_deps = Archive.cmi_deps cmos path Cmo.name Cmo.cmi_digest Cmo.cmi_deps
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
    Odig_ocamlc.read_cmx cmx_path >>= fun cmx ->
    realpath cmx_path >>| fun cmx_path ->
    of_ocamlc_cmx cmx_path ~cmx_cmxa:None cmx

  let name cmx = cmx.cmx_name
  let digest cmx = cmx.cmx_digest
  let cmi_digest cmx = cmx.cmx_digest
  let cmi_digest cmx = cmx.cmx_cmi_digest
  let cmi_deps cmx = cmx.cmx_cmi_deps
  let cmx_deps cmx = cmx.cmx_cmx_deps
  let cmxa cmx = cmx.cmx_cmxa
  let path cmx = cmx.cmx_path
  let to_cmi_dep cmx = cmx.cmx_name, Some (cmx.cmx_cmi_digest)
end

module Cmxa = struct
  type t = cmxa

  let read cmxa_path =
    Odig_ocamlc.read_cmxa cmxa_path >>= fun cmxa ->
    realpath cmxa_path >>| fun cmxa_path ->
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

  (* Derived information *)

  let names = Archive.names cmxs Cmx.name Cmx.cmi_digest
  let cmi_digests = Archive.cmi_digests cmxs Cmx.name Cmx.cmi_digest
  let to_cmi_deps = Archive.to_cmi_deps cmxs Cmx.name Cmx.cmi_digest
  let cmi_deps = Archive.cmi_deps cmxs path Cmx.name Cmx.cmi_digest Cmx.cmi_deps
end

module Cmxs = struct
  type t = cmxs

  let read cmxs_path =
    Odig_ocamlc.read_cmxs cmxs_path >>= fun cmxs ->
    realpath cmxs_path >>| fun cmxs_path ->
    let cmxs_name = Odig_ocamlc.cmxs_name cmxs in
    { cmxs_name; cmxs_path }

  let name cmxs = cmxs.cmxs_name
  let path cmxs = cmxs.cmxs_path
end

(* Cobj sets. *)

let compare_by_name name o o' = compare (name o) (name o')

type set =
  { mlis : mli list;
    cmis : cmi list;
    cmtis : cmti list;
    mls : ml list;
    cmos : cmo list;
    cmts : cmt list;
    cmas : cma list;
    cmxs : cmx list;
    cmxas : cmxa list;
    cmxss : cmxs list; }

let empty_set =
  { mlis = []; cmis = []; cmtis = []; mls = []; cmos = []; cmts = [];
    cmas = []; cmxs = []; cmxas = []; cmxss = [] }

let mlis s = s.mlis
let cmis s = s.cmis
let cmtis s = s.cmtis
let mls s = s.mls
let cmos ?(files = false) s =
  if files then s.cmos else
  let by_name = compare_by_name Cmo.name in
  List.(sort by_name @@ rev_append s.cmos (flatten (rev_map Cma.cmos s.cmas)))

let cmts s = s.cmts
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
  | ".ml" -> { acc with mls = add_cobj Ml.read f acc.mls }
  | ".cmo" -> { acc with cmos = add_cobj Cmo.read f acc.cmos }
  | ".cmt" -> { acc with cmts = add_cobj Cmt.read f acc.cmts }
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

  type query = [ `Digest of digest | `Name of string ]

  let query_of_dep (n, d) = match d with
  | None -> `Name n
  | Some d -> `Digest d

  type 'a occs =
    { cmis : ('a * cmi) list;
      cmtis : ('a * cmti) list;
      cmos : ('a * cmo) list;
      cmxs : ('a * cmx) list;
      cmts : ('a * cmt) list; }

  type 'a t = { digests : 'a occs Digest.Map.t;
                names : 'a occs String.Map.t }

  let empty_occs = { cmis = []; cmtis = []; cmos = []; cmxs = []; cmts = [] }
  let empty = { digests = Digest.Map.empty; names = String.Map.empty; }

  let add_cobjs digests names tag cobjs =
    let add_digest get_digest add_obj acc obj =
      let d = get_digest obj in
      let occs = match Digest.Map.find d acc with
      | None -> empty_occs | Some r -> r
      in
      Digest.Map.add d (add_obj obj occs) acc
    in
    let add_name get_name add_obj acc obj =
      let d = get_name obj in
      let occs = match String.Map.find d acc with
      | None -> empty_occs | Some r -> r
      in
      String.Map.add d (add_obj obj occs) acc
    in
    let add_cmi cmi acc = { acc with cmis = (tag, cmi) :: acc.cmis } in
    let add_cmti cmti acc = { acc with cmtis = (tag, cmti) :: acc.cmtis } in
    let add_cmo cmo acc = { acc with cmos = (tag, cmo) :: acc.cmos } in
    let add_cmx cmx acc = { acc with cmxs = (tag, cmx) :: acc.cmxs } in
    let add_cmt cmt acc = { acc with cmts = (tag, cmt) :: acc.cmts } in
    let rec add_objs add_obj get_digests get_name ds ns = function
    | [] -> ds, ns
    | obj :: objs ->
        let add_digest ds get_digest = add_digest get_digest add_obj ds obj in
        let ds = List.fold_left add_digest ds get_digests in
        let ns = add_name get_name add_obj ns obj in
        add_objs add_obj get_digests get_name ds ns objs
    in
    let ds,ns = digests, names in
    let ds,ns = add_objs add_cmi [Cmi.digest] Cmi.name ds ns (cmis cobjs) in
    let ds,ns = add_objs add_cmti [Cmti.digest] Cmti.name ds ns (cmtis cobjs) in
    let ds,ns = add_objs add_cmo [Cmo.cmi_digest] Cmo.name ds ns (cmos cobjs) in
    let ds,ns = add_objs add_cmx [Cmx.cmi_digest] Cmx.name ds ns (cmxs cobjs) in
    let ds,ns =
      add_objs add_cmx [Cmx.digest;Cmx.cmi_digest] Cmx.name ds ns (cmxs cobjs)
    in
    let ds, ns = add_objs add_cmt [Cmt.cmi_digest] Cmt.name ds ns (cmts cobjs)
    in
    ds,ns

  let of_set ?(init = empty) v cobjs =
    let digests, names = add_cobjs init.digests init.names v cobjs in
    { digests; names; }

  (* Queries *)

  let find i q = match q with
  | `Digest d -> Digest.Map.find d i.digests
  | `Name n -> String.Map.find n i.names

  let query i q = match find i q with
  | None -> ([], [], [], [], [])
  | Some occs -> (occs.cmis, occs.cmtis, occs.cmos, occs.cmxs, occs.cmts)

  let cmis_for_interface i q =
    match find i q with None -> [] | Some occs -> occs.cmis

  let cmtis_for_interface i q =
    match find i q with None -> [] | Some occs -> occs.cmtis

  let cmos_for_interface i q =
    match find i q with None -> [] | Some occs -> occs.cmos

  let cmxs_for_interface i q = match find i q with
  | None -> []
  | Some occs ->
      match q with
      | `Name _ -> occs.cmxs
      | `Digest d ->
          let has_cmi_digest (_, cmx) = Cmx.cmi_digest cmx = d in
          List.filter has_cmi_digest occs.cmxs

  let cmts_for_interface i q =
    match find i q with None -> [] | Some occs -> occs.cmts

end

type 'a index = 'a Index.t

(* Dependency resolution *)

type ('a, 'b) dep_resolution =
  [ `None | `Some of ('a * 'b) | `Amb of ('a * 'b) list ]

type ('a, 'b) dep_resolver = dep -> ('a * 'b) list -> ('a, 'b) dep_resolution

let obj_for_interface objs_for_interface ~resolve index dep =
  resolve dep (objs_for_interface index (Index.query_of_dep dep))

let cmi_for_interface ~resolve =
  obj_for_interface Index.cmis_for_interface ~resolve

let cmo_for_interface ~resolve =
  obj_for_interface Index.cmos_for_interface ~resolve

let cmx_for_interface ~resolve =
  obj_for_interface Index.cmxs_for_interface ~resolve

(* Recursive resolution *)

type ('a, 'b) dep_src = ('a * 'b) list

type ('a, 'o) rec_dep_resolution =
  [ `Resolved of ('a * 'o) * ('a, 'o) dep_src
  | `Unresolved of dep * [ `None | `Amb of ('a * 'o) list ] * ('a, 'o) dep_src
  | `Conflict of string * ('a, 'o) dep_src list Digest.map ]

let pp_rec_dep_resolution pp_obj ppf r =
  let pp_src ppf srcs = match srcs with
  | [] -> ()
  | srcs -> Fmt.pf ppf "@,dep source:@, @[<v>%a@]@]" (Fmt.list pp_obj) srcs
  in
  let pp_dep ppf (n, dep) = match dep with
  | None -> Fmt.string ppf n
  | Some dep -> Fmt.pf ppf "@[<1>%s@ %a@]" n Digest.pp dep
  in
  let pp_reason ppf = function
  | `None -> Fmt.pf ppf "unresolved"
  | `Amb amb -> Fmt.pf ppf "ambiguous resolution, could be one of:@, %a"
                  Fmt.(vbox @@ list pp_obj) amb
  in
  let pp_conflict ppf (d, srcs) =
    Fmt.pf ppf "@[<v>%a @, %a@]" Digest.pp d pp_src (List.hd srcs)
  in
  match r with
  | `Resolved (obj, src) ->
      Fmt.pf ppf "@[<v>%a: resolved%a@]" pp_obj obj pp_src src
  | `Unresolved (dep, reason, src) ->
      Fmt.pf ppf "@[<v>%a: %a%a@]" pp_dep dep pp_reason reason pp_src src
  | `Conflict (n, dm) ->
      Fmt.pf ppf "@[<v>%s: conflicting implementations:@, %a@]"
        n Fmt.(vbox @@ iter_bindings Digest.Map.iter pp_conflict) dm

(* N.B. it is difficult to determine the evaluation order while resolving
   names since an unresolved part of the DAG might get resolved later
   which might in turn change the load order. *)

let rec_objs_for_interfaces
    obj_for_interface obj_name obj_digest obj_deps ~resolve index deps
  =
  let check_conflict ((n, digest), src1) d0 src0 res = match digest with
  | Some d1 when not (Digest.equal d0 d1) ->
      let dm = Digest.Map.add d0 [src0] Digest.Map.empty in
      let dm = Digest.Map.add d1 [src1] dm in
      String.Map.add n (`Conflict (n, dm)) res
  | _ -> res
  in
  let update_conflict ((n, digest), src) dm res = match digest with
  | None -> res
  | Some d ->
      let dm = match Digest.Map.find d dm with
      | None -> Digest.Map.add d [src] dm
      | Some srcs -> Digest.Map.add d (src :: srcs) dm
      in
      String.Map.add n (`Conflict (n, dm)) res
  in
  let find_obj ((n, digest as dep), src) res ds =
    match obj_for_interface ~resolve index dep with
    | (`None | `Amb _ as r)->
        String.Map.add n (`Unresolved (dep, r, src)) res, ds
    | `Some obj ->
        let res = String.Map.add n (`Resolved (obj, src)) res in
        let res_src = obj :: src in
        let deps = List.rev_map (fun d -> d, res_src) (obj_deps (snd obj)) in
        let ds = List.rev_append deps ds in
        res, ds
  in
  let rec loop res = function
  | [] -> res
  | ((n, digest), _  as d) :: ds ->
      match String.Map.find n res with
      | None ->
          let res, ds = find_obj d res ds in
          loop res ds
      | Some (`Resolved (obj, src)) ->
          let res = check_conflict d (obj_digest (snd obj)) src res in
          loop res ds
      | Some (`Unresolved ((_, Some digest), _, src)) ->
          let res = check_conflict d digest src res in
          loop res ds
      | Some (`Unresolved ((_, None), _, _)) ->
          begin match digest with
          | None -> loop res ds
          | Some _ ->
              let res, ds = find_obj d res ds in
              loop res ds
          end
      | Some (`Conflict (n, dm)) ->
          let res = update_conflict d dm res in
          loop res ds
  in
  loop String.Map.empty deps

let rec_cmis_for_interfaces ~resolve index deps =
  rec_objs_for_interfaces
    cmi_for_interface Cmi.name Cmi.digest Cmi.deps ~resolve index deps

let rec_cmos_for_interfaces ~resolve index deps =
  rec_objs_for_interfaces
    cmo_for_interface Cmo.name Cmo.cmi_digest Cmo.cmi_deps ~resolve index deps

let fold_rec_dep_resolutions ~deps f res acc =
  (* Topological sort by depth first exploration of the DAG. *)
  let rec loop seen acc = function
  | ((n, r) :: rs as l) :: todo ->
      begin match String.Set.mem n seen with
      | true -> loop seen acc (rs :: todo)
      | false ->
          let seen = String.Set.add n seen in
          match r with
          | `Conflict _ | `Unresolved _ -> loop seen (f n r acc) (rs :: todo)
          | `Resolved (obj, _) ->
              let add_dep acc (n, _) = match String.Set.mem n seen with
              | true -> (* early filter *) acc
              | false -> (n, String.Map.get n res) :: acc
              in
              match List.fold_left add_dep [] (deps (snd obj)) with
              | [] (* early filter *) -> loop seen (f n r acc) (rs :: todo)
              | deps -> loop seen acc (deps :: l :: todo)
      end
  | [] :: ((n, r) :: rs) :: todo -> loop seen (f n r acc) (rs :: todo)
  | [] :: ([] :: todo) -> loop seen acc todo
  | [] :: [] -> acc
  | [] -> assert false
  in
  loop String.Set.empty acc ((String.Map.bindings res) :: [])

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
