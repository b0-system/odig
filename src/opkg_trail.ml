(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)
open Bos_setup

module type S = sig
  type status = [ `Fresh | `Stale ]
  type t

  val v : id:string -> t
  val id : t -> string
  val preds : t -> t list
  val succs : t -> t list
  val witness : t -> Digest.t option
  val status : t -> status

  val set_witness :
    ?succs:[`Delete | `Stale | `Nop] -> ?preds:t list -> t ->
    Digest.t option -> unit

  val delete : ?succs:[`Delete | `Stale | `Nop] -> t -> unit

  val pp_dot : root:Fpath.t -> t Fmt.t

  val equal : t -> t -> bool
  val compare : t -> t -> int

  val universe : unit -> t list
  val read : ?create:bool -> Fpath.t -> (unit, R.msg) result
  val write : Fpath.t -> (unit, R.msg) result
  val pp_dot_universe : root:Fpath.t -> unit Fmt.t
end

type trail_status = [ `Fresh | `Stale ]

module rec Trail : sig
  type t =
    { id : string;
      mutable witness : Digest.t option;
      mutable status : trail_status;
      mutable preds : Tset.t;
      mutable succs : Tset.t; }

  val compare : t -> t -> int
end = struct
  type t =
    { id : string;
      mutable witness : Digest.t option;
      mutable status : trail_status;
      mutable preds : Tset.t;
      mutable succs : Tset.t; }

  let compare t0 t1 = String.compare t0.id t1.id
end
and Tset : (Asetmap.Set.S with type elt = Trail.t) = Asetmap.Set.Make (Trail)

module Make () : S = struct

  (* Universe *)

  type universe = Tset.t
  let empty_universe = Tset.empty
  let universe = ref empty_universe

  (* Trails *)

  type status = trail_status

  type t = Trail.t

  let v ~id =
    let candidate = { id; Trail.witness = None; status = `Stale;
                      preds = Tset.empty; succs = Tset.empty }
    in
    match Tset.find (* looks up by id *) candidate !universe with
    | Some t -> t
    | None ->
        universe := Tset.add candidate !universe;
        candidate

  let id t = t.Trail.id
  let witness t = t.Trail.witness
  let preds t = Tset.elements t.Trail.preds
  let succs t = Tset.elements t.Trail.succs
  let status t = t.Trail.status

  let rem_succ succ p = p.Trail.succs <- Tset.remove succ p.Trail.succs
  let rem_pred pred p = p.Trail.preds <- Tset.remove pred p.Trail.preds

  let make_preds succ preds =
    let add_succ succ acc p =
      p.Trail.succs <- Tset.add succ p.Trail.succs;
      Tset.add p acc
    in
    List.fold_left (add_succ succ) Tset.empty preds

  let rec stale_succs = function
  | [] -> ()
  | s :: ss ->
      let mark t acc = match t.Trail.status with
      | `Stale -> acc
      | `Fresh -> t.Trail.status <- `Stale; t.Trail.succs :: acc
      in
      stale_succs (Tset.fold mark s ss)

  let _delete t =
    Tset.iter (rem_succ t) t.Trail.preds;
    universe := Tset.remove t !universe;
    ()

  let rec delete_succs = function
  | [] -> ()
  | s :: ss ->
      let delete t acc = _delete t; t.Trail.succs :: acc in
      delete_succs (Tset.fold delete s ss);    ()

  let set_witness ?(succs = `Stale) ?(preds = []) t d =
    Tset.iter (rem_succ t) t.Trail.preds;
    t.Trail.preds <- make_preds t preds;
    if d <> t.Trail.witness then begin
      t.Trail.witness <- d;
      match succs with
      | `Stale -> stale_succs [t.Trail.succs]
      | `Delete -> delete_succs [t.Trail.succs]
      | `Nop -> ()
    end;
    t.Trail.status <- `Fresh

  let delete ?(succs = `Delete) t =
    _delete t;
    match succs with
    | `Delete -> delete_succs [t.Trail.succs]
    | `Stale ->
        Tset.iter (rem_pred t) t.Trail.succs;
        stale_succs [t.Trail.succs]
    | `Nop -> ()

  let extents t =
    let rec add_set kind acc todo = match Tset.choose todo with
    | None -> acc
    | Some t ->
        let set = kind t in
        let acc = Tset.union set acc in
        let todo = Tset.(union (remove t todo) set) in
        add_set kind acc todo
    in
    let start = Tset.singleton t in
    let acc = add_set (fun t -> t.Trail.preds) Tset.empty start in
    let acc = add_set (fun t -> t.Trail.succs) acc start in
    acc

  (* Dot printing *)

  (* FIXME use Opkg_dot *)

  let pp_dot_label ~root ppf t =
    let label = match Fpath.of_string t.Trail.id with
    | Error _ -> t.Trail.id
    | Ok p ->
        if Fpath.is_rel p then t.Trail.id else
        match Fpath.relativize ~root p with
        | None -> t.Trail.id
        | Some p -> Fpath.to_string p
    in
    Fmt.string ppf label

  let pp_dot_status ppf = function
  | `Fresh -> ()
  | `Stale -> Fmt.pf ppf ",color=red"

  let pp_dot_trail_node ~root ppf t =
    Fmt.pf ppf "\"%s\"[label=\"%a\"%a];@,"
      t.Trail.id (pp_dot_label ~root) t pp_dot_status t.Trail.status

  let pp_dot_succ_edges ppf t =
    let pp_succ ppf s =
      Fmt.pf ppf "\"%s\" -> \"%s\";" t.Trail.id s.Trail.id
    in
    Fmt.iter Tset.iter pp_succ ppf t.Trail.succs

  let pp_dot_digraph pp_statements ppf v =
    Fmt.pf ppf "@[<v>digraph trails@,{ rankdir=LR;@,";
    pp_statements ppf v;
    Fmt.pf ppf "@,}@]";
    ()

  let pp_dot_trail_set ~root =
    let pp_trail ppf t =
      pp_dot_trail_node ~root ppf t;
      pp_dot_succ_edges ppf t
    in
    let pp_statements = Fmt.iter Tset.iter pp_trail in
    pp_dot_digraph pp_statements

  let pp_dot ~root ppf t = pp_dot_trail_set ~root ppf (extents t)

  (* Predicates and comparison *)

  let equal t0 t1 = String.equal t0.Trail.id t1.Trail.id
  let compare = Trail.compare

  (* Universe *)

  let magic = "opkg-%%VERSION%%-ocaml-" ^ Sys.ocaml_version

  let read ?create:(c = true) f =
    let read ic () =
      let m = really_input_string ic (String.length magic) in
      match m = magic with
      | true -> universe := (input_value ic : universe); Ok ()
      | false ->
          R.error_msgf "%a: invalid magic number %S, expected %S"
            Fpath.pp f m magic
    in
    OS.File.exists f >>= function
    | false when c -> Ok ()
    | _ -> R.join @@ OS.File.with_ic f read ()

  let write f =
    let write oc universe =
      try
        output_string oc magic;
        output_value oc universe;
        flush oc;
        Ok ()
      with Sys_error e -> R.error_msgf "%a: %s" Fpath.pp f e
    in
    R.join @@ OS.File.with_oc f write !universe

  let pp_dot_universe ~root ppf () = pp_dot_trail_set ~root ppf !universe
  let universe () = Tset.elements !universe
end

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
