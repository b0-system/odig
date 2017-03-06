(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* FIXME
   * In general need a mecanism to refine load order (note however
     that e.g. [#load_rec] says the order is unspecified).
   * mli only handling strategy. For now unresolved deps are ignored.
     We could look them up for cmi and if exist add them to
     the PATH.
   * should force also reload stdlib.cma ? *)

(* Announce and help *)

let pp_code ppf c = Fmt.(styled `Bold string) ppf c
let pp_odig = Fmt.styled_unit `Yellow "Odig"
let pp_version = Fmt.styled_unit `Cyan "%%VERSION%%"
let announce () =
  Odig_log.app (fun m -> m "%a %a loaded. Type %a for more info."
                   pp_odig () pp_version () pp_code "Odig.help ();;");
  ()

let help () =
  Odig_log.app (fun m -> m "Commands:");
  Odig_log.app (fun m -> m "  %a     load module %a"
                   pp_code "Odig.load \"M\"" pp_code "M");
  Odig_log.app (fun m -> m "  %a load local libraries"
                   pp_code "Odig.load_libs ()");
  Odig_log.app (fun m -> m "  %a load libraries of package %a"
                   pp_code "Odig.load_pkg \"p\"" pp_code "p");
  Odig_log.app (fun m -> m "  %a    list what is currently loaded"
                   pp_code "Odig.status ()");
  ()

let debug () = Logs.Src.set_level Odig_log.src (Some Logs.Debug)

(* Init configuration. *)

let conf = ref None

let init ?conf:c () =
  (* FIXME sort out logs setup *)
  let c = match c with
  | Some c -> Ok c
  | None ->
      (Odig_conf.(of_file default_file) >>| fun conf -> Ok conf)
      |> Odig_log.on_error ~pp:R.pp_msg ~use:(fun e -> Error e)
  in
  conf := Some c

let rec get_conf () = match !conf with
| None -> init (); get_conf ()
| Some c -> c

(* Toplevel includes and objects *)

module Tinc = struct
  let incs = ref Fpath.Set.empty
  let mem inc = Fpath.Set.mem inc !incs
  let assume inc = incs := Fpath.Set.add inc !incs
  let add inc =
    Odig_ocamltop.add_inc inc
    >>| fun () -> incs := Fpath.Set.add inc !incs; ()

  let rem inc =
    incs := Fpath.Set.remove inc !incs;
    Odig_ocamltop.rem_inc inc

  let reset () =
    Odig_log.on_iter_error_msg Fpath.Set.iter Odig_ocamltop.rem_inc !incs;
    incs := Fpath.Set.empty;
    ()
end

let assume_inc = Tinc.assume

module Tobj = struct
  let loaded = ref Fpath.Set.empty
  let is_loaded obj = Fpath.Set.mem obj !loaded
  let add obj = loaded := Fpath.Set.add obj !loaded; ()
  let assume = add
  let load obj = Odig_ocamltop.load_obj obj >>| fun () -> add obj
  let load_src src = Odig_ocamltop.load_ml src >>| fun () -> add src
  let reset () = loaded := Fpath.Set.empty; ()
end

let assume_obj = Tobj.assume

let pp_labelled_path style label ppf p =
  Fmt.pf ppf "[%a] %a" Fmt.(styled style string) label Fpath.pp p

let pp_inc = pp_labelled_path `Yellow "INC"
let pp_obj = pp_labelled_path `Blue "OBJ"
let pp_src = pp_labelled_path `Magenta "SRC"

let reset () =
  (* FIXME should we reset the configuration ? *)
  Tinc.reset ();
  Tobj.reset ();
  ()

let status () =
  Logs.app (fun m ->
      m "@[<v>%a@,@,%a@]"
        (Fpath.Set.pp pp_inc) !Tinc.incs (Fpath.Set.pp pp_obj) !Tobj.loaded)

(* Low-level loading *)

let load_init_file cma =
  let init_base = Fpath.(basename @@ rem_ext cma) ^ "_top_init.ml" in
  let init = Fpath.(parent cma / init_base) in
  OS.File.exists init >>= function
  | false -> Ok ()
  | true ->
      Tobj.load_src init >>| fun () ->
      Odig_log.app (fun m -> m "%a" pp_src init)

let load_obj ~init obj =
  Tinc.add (Fpath.parent obj) >>= fun () ->
  Tobj.load obj >>= fun () ->
  Odig_log.app (fun m -> m "%a" pp_obj obj);
  match init && Fpath.has_ext ".cma" obj with
  | true -> load_init_file obj
  | false -> Ok ()

let load_objs ~force ~init objs =
  let should_load = match force with
  | false -> fun o -> not (Tobj.is_loaded o)
  | true ->
      (* FIXME should we reload the stlib ? should we reload odig's deps ? *)
      fun o -> match Fpath.filename o with
      | "stdlib.cma" -> false
      | _ -> true
  in
  let rec loop = function
  | [] -> Ok ()
  | obj :: objs ->
      match should_load obj with
      | false -> loop objs
      | true -> load_obj ~init obj >>= fun () -> loop objs
  in
  loop objs

(* Dependency resolvers *)

let cmo_in_cma (_, obj) = Odig_cobj.Cmo.cma obj <> None
let local_obj (scope, _) = match scope with `Local -> true | _ -> false
let pkg_obj (scope, _) = match scope with `Pkg _ -> true | _ -> false

let not_vmthreads (scope, o) =
  (* Detect vmthread to get rid of stdlib ambiguity.
     FIXME is there a way to know which one should be selected ? *)
  match scope with
  | `Local -> true
  | `Pkg p when Odig_pkg.name p <> "ocaml" -> true
  | `Pkg _ ->
      match Odig_cobj.Cmo.cma o with
      | None -> true
      | Some cma ->
          match Fpath.(basename @@ parent (Odig_cobj.Cma.path cma)) with
          | "vmthreads" -> false
          | _ -> true

let sat pred = List.filter pred
let resolve = function
| [] -> `None
| [obj] -> `Some obj
| objs -> `Amb objs

let try_resolve pred objs = match resolve (pred objs) with
| `Some _ | `Amb _ as v -> v
| `None -> `Amb objs

let resolve_local _ objs = match resolve (sat local_obj objs) with
| `None | `Some _ as v -> v
| `Amb objs -> try_resolve (sat cmo_in_cma) objs

let resolve_local_or_pkg _ objs = match resolve objs with
| `None | `Some _ as v -> v
| `Amb objs ->
    match resolve (sat local_obj objs) with
    | `Some _ as v -> v
    | `Amb objs -> try_resolve (sat cmo_in_cma) objs
    | `None ->
        match resolve (sat pkg_obj objs) with
        | `None | `Some _ as v -> v
        | `Amb objs ->
            match resolve (sat cmo_in_cma objs) with
            | `Some _ as v -> v
            | `None -> `Amb objs
            | `Amb objs -> try_resolve (sat not_vmthreads) objs

let resolve_mod mod_name (name, _) objs =
  if mod_name = name then resolve objs else `None

(* Local index with packages. *)

type local_index = [ `Pkg of Odig_pkg.t | `Local ] Odig_cobj.index

let local_index conf cobjs =
  Odig_pkg.conf_cobj_index conf >>| fun pkg_index ->
  let init = (pkg_index :> local_index) in
  Odig_cobj.Index.of_set ~init `Local cobjs

(* Loaders *)

let cmas_cmi_roots cobjs =
  let keep_cma cma = not (String.is_suffix "_top" (Odig_cobj.Cma.name cma)) in
  let add_cma acc cma = match keep_cma cma with
  | false -> acc
  | true ->
      let src cmo = [`Local, cmo] in
      let add_cmo acc cmo = (Odig_cobj.Cmo.to_cmi_dep cmo, src cmo) :: acc in
      List.fold_left add_cmo acc (Odig_cobj.Cma.cmos cma)
  in
  List.fold_left add_cma [] (Odig_cobj.cmas cobjs)

let pp_cmo_obj ppf (_, o) =
  Fmt.pf ppf "@[<1>%s %a@]"
    (Odig_cobj.Cmo.name o) Fpath.pp (Odig_cobj.Cmo.path o)

let rec_cmos_for_interfaces ~resolve index cmis =
  (* FIXME lookup unresolved for cmis and add incs ? *)
  let pp_res = Odig_cobj.pp_rec_dep_resolution pp_cmo_obj in
  let cmo_deps cmo = match Odig_cobj.Cmo.cma cmo with
  | None -> Odig_cobj.Cmo.cmi_deps cmo
  | Some cma -> Odig_cobj.Cma.cmi_deps cma
  in
  let res = Odig_cobj.rec_cmos_for_interfaces ~cmo_deps ~resolve index cmis in
  let add _ r acc =
    acc >>= fun acc ->
    Odig_log.debug (fun m -> m "%a"
                     (Odig_cobj.pp_rec_dep_resolution pp_cmo_obj) r);
    match r with
    | `Resolved ((_, cmo), _) -> Ok (cmo :: acc)
    | `Unresolved (dep, `None, src) -> (* might be due to cmi only *) Ok acc
    | `Conflict _ as r -> R.error_msgf "%a" pp_res r
    | `Unresolved (_, `Amb objs, _) as r -> R.error_msgf "%a" pp_res r
  in
  Odig_cobj.fold_rec_dep_resolutions ~deps:cmo_deps add res (Ok [])
  >>| fun acc -> List.rev acc

let cmos_to_paths cmos = (* preserve order, rem dupes *)
  let rec loop seen acc = function
  | [] -> List.rev acc
  | cmo :: cmos ->
      let p = Odig_cobj.Cmo.path cmo (* N.B. may be a path to cma *) in
      match Fpath.Set.mem p seen with
      | true -> loop seen acc cmos
      | false -> loop (Fpath.Set.add p seen) (p :: acc) cmos
  in
  loop Fpath.Set.empty [] cmos

let local_cobjs dir = match dir with
| Some dir ->
    OS.Dir.must_exist dir
    >>| fun _ -> Odig_cobj.set_of_dir dir
| None ->
    let absent = Fpath.v "_build" in
    let dir = OS.Env.(value "ODIG_TOP_LOCAL_DIR" ~absent path) in
    OS.Dir.exists dir >>| function
    | false -> Odig_cobj.empty_set
    | true -> Odig_cobj.set_of_dir dir

let local_setup ?dir () =
  get_conf ()
  >>= fun conf -> local_cobjs dir
  >>= fun cobjs -> local_index conf cobjs
  >>| fun index -> (cobjs, index)

let load ?(force = false) ?(deps = true) ?(init = true) ?dir m =
  (* FIXME add a way to ignore local *)
  let m = String.Ascii.capitalize m in
  let roots = [(m, None), []] in
  let resolve = if deps then resolve_local_or_pkg else resolve_mod m in
  begin
    local_setup ?dir ()
    >>= fun (_, index) -> rec_cmos_for_interfaces ~resolve index roots
    >>= function
    | [] -> R.error_msgf "%s: found no object to load" m
    | cmos -> load_objs ~force ~init (cmos_to_paths cmos)
  end
  |> Logs.on_error_msg ~use:(fun _ -> ())

let load_libs ?(force = false) ?(deps = true) ?(init = true) ?dir () =
  let resolve = if deps then resolve_local_or_pkg else resolve_local in
  begin
    local_setup ?dir ()
    >>= fun (cobjs, index) -> match Odig_cobj.cmas cobjs with
    | [] -> R.error_msgf "Found no library to load"
    | _ ->
        let cmis = cmas_cmi_roots cobjs in
        rec_cmos_for_interfaces ~resolve index cmis
        >>= fun cmos -> load_objs ~force ~init (cmos_to_paths cmos)
  end
  |> Logs.on_error_msg ~use:(fun _ -> ())

let load_pkg ?(force = false) ?(deps = true) ?(init = true) name =
  (* FIXME limit to pkg deps *)
  let resolve = if deps then resolve_local_or_pkg else resolve_local in
  begin
    get_conf ()
    >>= fun conf -> Odig_pkg.name_of_string name
    >>= fun name -> Odig_pkg.lookup conf name
    >>= fun pkg -> Ok (Odig_pkg.cobjs pkg)
    >>= fun cobjs -> local_index conf cobjs
    >>= fun index -> Ok (cmas_cmi_roots cobjs)
    >>= fun roots -> rec_cmos_for_interfaces ~resolve index roots
    >>= fun cmos -> load_objs ~force ~init (cmos_to_paths cmos)
  end
  |> Odig_log.on_error_msg ~use:(fun _ -> ())

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
