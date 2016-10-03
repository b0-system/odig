(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup
open Odig
open Odig.Private

(* META file normalization

   Given a package expression:

   1. Drop the "description", "version", "exist_if" definitions, normalize
      the remaining ones (see below) and sort them by polymorphic compare.
   2. Add en empty "requires" if no "requires" is present.
   2. Normalize all the subpackages expressions and sort them by name.

   Given a definition:

   1. If it is the "requires" definition, tokenize its value on space or
      commas, sort the tokens and concatenate them seperated by space.
   2. If it is the "archive" definition, normalize
      archive({native,byte},plugin) and archive(plugin,{native,byte}) to
      to a plugin({native,byte}) definition.
   3. Always sort the predicates of the definition. *)

let normalize_preds def_preds = List.sort compare def_preds
let normalize_def d = match d.Fl_metascanner.def_var with
| "requires" ->
    let is_sep c = Char.Ascii.is_white c || Char.equal c ',' in
    let pkgs = String.fields ~empty:false ~is_sep d.Fl_metascanner.def_value in
    let pkgs = List.sort String.compare pkgs in
    let def_value = String.concat ~sep:" " pkgs in
    let def_preds = normalize_preds d.Fl_metascanner.def_preds in
    { d with Fl_metascanner.def_value; def_preds }
| "archive" ->
    let def_var, def_preds = match d.Fl_metascanner.def_preds with
    | [`Pred ("native" | "byte" as b); `Pred "plugin"]
    | [`Pred "plugin"; `Pred ("native" | "byte" as b )] -> "plugin", [`Pred b]
    | def_preds -> d.Fl_metascanner.def_var, def_preds
    in
    let def_preds = normalize_preds def_preds in
    { d with Fl_metascanner.def_var; def_preds }
| _ ->
    let def_preds = normalize_preds d.Fl_metascanner.def_preds in
    { d with Fl_metascanner.def_preds }

let add_miss_requires defs =
  match List.find (fun d -> d.Fl_metascanner.def_var = "requires") defs with
  | v -> defs
  | exception Not_found ->
      { Fl_metascanner.def_var = "requires"; def_flav = `BaseDef;
        def_preds = []; def_value = "" } :: defs

let rec normalize_pkg pkg =
  let keep_def d = match d.Fl_metascanner.def_var with
  | "description" | "version" | "exists_if" -> false
  | _ -> true
  in
  let pkg_defs = List.filter keep_def pkg.Fl_metascanner.pkg_defs in
  let pkg_defs = List.rev_map normalize_def pkg_defs in
  let pkg_defs = add_miss_requires pkg_defs in
  let pkg_defs = List.sort compare pkg_defs in
  let normalize_child (n, exp) = (n, normalize_pkg exp) in
  let sort_child (n, _) (n', _) = String.compare n n' in
  let pkg_children =
    List.rev_map normalize_child pkg.Fl_metascanner.pkg_children
  in
  let pkg_children = List.sort sort_child pkg_children in
  { Fl_metascanner.pkg_defs; pkg_children }

(* META lookup, reading and writing *)

let find_meta pkg =
  let meta = Fpath.(Pkg.libdir pkg / "META") in
  OS.File.exists meta >>| function false -> None | true -> Some meta

let with_meta ~multi ~warn pkg process = find_meta pkg >>= function
| Some meta -> process pkg meta ~multi
| None ->
    let level = if warn then Logs.Warning else Logs.Error in
    Logs.msg level (fun m -> m "%s: no META file found" (Pkg.name pkg));
    Ok ()

let read_meta m =
  let parse ic () = try Ok (Fl_metascanner.parse ic) with
  | Stream.Error err -> R.error_msg err
  in
  R.join @@ OS.File.with_ic m parse ()

let write_meta dst pkg =
  let write oc pkg = Ok (Fl_metascanner.print oc pkg) in
  R.join @@ OS.File.with_oc dst write pkg

(* META file generation for a PKG.

   Given a package PKG, for each cmx, cmxs, or cmxa its file name F is
   mapped to a (sub)package name NAME(F) according to its pattern as
   follows:

    PKG -> pkg (the toplevel definitions)
    PKG[-_]bla -> pkg.bla
    bla -> pkg.bla

   If F is in a subdirectory SUB the path to the subdir is transformed to
   a package path e.g. jsoo/PKG_bla -> pkg.jsoo.bla.

   The definitions for this package name are then simply (according to the
   actual existence of the files).

    directory = "SUB"           # If F is in a subdirectory
    archive(byte) = "F.cma"
    archive(native) = "F.cmxa"
    plugin(byte) = "F.cma"
    plugin(native) = "F.cmxs"
    requires = ... # See below

   The "requires" field is then inferred as follows. For each member of
   the cma and cmxa archive, dependencies of cmi digests are looked up
   and matched against implementations in cma/cmxa archives. Once found
   their name is converted to a package name as mentioned above and added
   to the requires list (if the cmi is implemented more than once
   this will result in bogus reqs).
*)

let obj_rel_path pkg get_path obj =
  match Fpath.relativize ~root:(Pkg.libdir pkg) (get_path obj) with
  | None -> assert false
  | Some rel -> rel

let obj_subpkg_name pkg get_path obj =
  let path = Fpath.rem_ext (obj_rel_path pkg get_path obj) in
  let rpath = List.rev (Fpath.segs path) in
  let name, rpath = List.(hd rpath, tl rpath) in
  let rpath = match String.cut ~sep:(Pkg.name pkg) name with
  | Some ("", rest) ->
      if rest = "" then [] else
      begin match String.head rest with
      | Some ('-' | '_') -> (String.with_range ~first:1 rest) :: rpath
      | _ -> name :: rpath
      end
  | _ -> name :: rpath
  in
  List.rev rpath

let subpkg_name pkg sub = String.concat ~sep:"." @@ (Pkg.name pkg) :: sub

let subpkgs pkg =
  let add_obj get_path acc o = (obj_subpkg_name pkg get_path o, o) :: acc in
  let subs get_path get_objs cobjs =
    List.fold_left (add_obj get_path) [] (get_objs cobjs)
  in
  let cobjs = Pkg.cobjs pkg in
  let cmas = subs Cobj.Cma.path Cobj.cmas cobjs in
  let cmxas = subs Cobj.Cmxa.path Cobj.cmxas cobjs in
  let cmxss = subs Cobj.Cmxs.path Cobj.cmxss cobjs in
  let names =
    List.(sort_uniq compare (rev_append (rev_map fst cmas) @@
          rev_append (rev_map fst cmxas) (rev_map fst cmxss)))
  in
  names, cmas, cmxas, cmxss

let obj_pkg_def get_path var pred obj =
  let def_var = var in
  let def_flav = `BaseDef in
  let def_preds = [`Pred pred] in
  let def_value = Fpath.filename @@ get_path obj in
  { Fl_metascanner.def_var; def_flav; def_preds; def_value }

let pkg_requires pkg cmi_digests =
  let names =
    begin
      Cobj_index.create (Pkg.conf pkg) >>| fun index ->
      let add_digest digest acc =
        let _, _, cmos, cmxs = Cobj_index.find_digest index digest in
        let add_obj get_ar get_p acc (pkg, obj) =
          if (Pkg.name pkg = "ocaml") then acc else
          match get_ar obj with
          | None -> acc
          | Some ar ->
              let sub = obj_subpkg_name pkg get_p ar in
              let name = subpkg_name pkg sub in
              String.Set.add name acc
        in
        let acc =
          List.fold_left (add_obj Cobj.Cmo.cma Cobj.Cma.path) acc cmos
        in
        List.fold_left (add_obj Cobj.Cmx.cmxa Cobj.Cmxa.path) acc cmxs
      in
      Cobj.Digest.Set.fold add_digest cmi_digests String.Set.empty
    end
    |> Logs.on_error_msg ~use:(fun _ -> String.Set.empty)
  in
  let def_var = "requires" in
  let def_flav = `BaseDef in
  let def_value = String.concat ~sep:" " (String.Set.elements names) in
  { Fl_metascanner.def_var ; def_flav; def_preds = []; def_value }

let add_sub_defs pkg sub cmas cmxas cmxss acc =
  let acc, cmi_digests = match List.assoc sub cmas with
  | exception Not_found -> acc, Cobj.Digest.Set.empty
  | cma ->
      obj_pkg_def Cobj.Cma.path "archive" "byte" cma ::
      obj_pkg_def Cobj.Cma.path "plugin" "byte" cma :: acc,
      Cobj.Cma.cmi_deps cma
  in
  let acc, cmi_digests = match List.assoc sub cmxas with
  | exception Not_found -> acc, cmi_digests
  | cmxa ->
      obj_pkg_def Cobj.Cmxa.path "archive" "native" cmxa :: acc,
      Cobj.Cmxa.cmi_deps ~init:cmi_digests cmxa
  in
  let acc = match List.assoc sub cmxss with
  | exception Not_found -> acc
  | cmxs ->
      obj_pkg_def Cobj.Cmxs.path "plugin" "native" cmxs :: acc
  in
  (pkg_requires pkg cmi_digests) :: acc

let dir_def dir =
  { Fl_metascanner.def_var = "directory"; def_flav = `BaseDef;
    def_preds = []; def_value = dir; }

let pkg_pkg pkg =
  let empty = { Fl_metascanner.pkg_defs = []; pkg_children = [] } in
  let empty_dir n =
    { Fl_metascanner.pkg_defs = [dir_def n]; pkg_children = [] }
  in
  let names, cmas, cmxas, cmxss = subpkgs pkg in
  let add p sub =
    let rec loop p = function
    | [n] ->
        let pkg_defs = add_sub_defs pkg sub cmas cmxas cmxss [] in
        let child = match List.assoc n p.Fl_metascanner.pkg_children with
        | exception Not_found -> { Fl_metascanner.pkg_defs; pkg_children = [] }
        | child -> { child with Fl_metascanner.pkg_defs }
        in
        let pkg_children = List.remove_assoc n p.Fl_metascanner.pkg_children in
        let pkg_children = (n, child) :: pkg_children in
        { p with Fl_metascanner.pkg_children }
    | n :: ns ->
        let pkg_children = p.Fl_metascanner.pkg_children in
        begin match List.assoc n pkg_children with
        | exception Not_found ->
            let child = loop (empty_dir n) ns in
            let pkg_children = (n, child) :: pkg_children in
            { p with Fl_metascanner.pkg_children }
        | child ->
            let child = loop child ns in
            let pkg_children = List.remove_assoc n pkg_children in
            let pkg_children = (n, child) :: pkg_children in
            {p with Fl_metascanner.pkg_children }
        end
    | [] ->
        { p with Fl_metascanner.pkg_defs =
                   add_sub_defs pkg sub cmas cmxas cmxss [] }
    in
    loop p sub
  in
  List.fold_left add empty names

(* Commands *)

let meta_raw _ meta ~multi =
  let multi = if multi then strf ":%a:\n" Fpath.pp meta else "" in
  OS.File.read meta >>= fun contents ->
  Fmt.pr "%s%s@." (* fs *) multi contents;
  Ok ()

let meta_raw ~multi ~warn pkg = with_meta ~multi ~warn pkg meta_raw

let meta_norm _ meta ~multi =
  let multi = if multi then strf ":%a:\n" Fpath.pp meta else "" in
  read_meta meta >>= fun pkg ->
  let pkg = normalize_pkg pkg in
  Fmt.pr "%s%!" multi;
  write_meta OS.File.dash pkg >>= fun () ->
  Fmt.pr "@."; Ok ()

let meta_norm ~multi ~warn pkg = with_meta ~multi ~warn pkg meta_norm

let meta_gen ~multi ~warn pkg =
  let multi = if multi then strf ":%s:\n" (Pkg.name pkg) else "" in
  let pkg = pkg_pkg pkg in
  let pkg = normalize_pkg pkg in
  Fmt.pr "%s%!" multi;
  write_meta OS.File.dash pkg >>= fun () ->
  Fmt.pr "@."; Ok ()

let meta_comp pkg meta ~multi =
  let diff o n = Cmd.(v "diff" % "-u" % p o % p n) in
  let multi = if multi then strf ":%a:\n" Fpath.pp meta else "" in
  read_meta meta >>= fun opkg ->
  let opkg = normalize_pkg opkg in
  let gpkg = pkg_pkg pkg in
  let gpkg = normalize_pkg gpkg in
  OS.File.tmp "meta-orig-%s"
  >>= fun opkgf -> OS.File.tmp "meta-gen-%s"
  >>= fun gpkgf -> write_meta opkgf opkg
  >>= fun () -> write_meta gpkgf gpkg
  >>= fun () -> OS.Cmd.(run_out (diff opkgf gpkgf) |> out_string)
  >>= function
  | "", _ -> Ok ()
  | diff, _ -> Fmt.pr "%s%s\n%!" multi diff; Ok ()

let meta_comp ~multi ~warn pkg = with_meta ~multi ~warn pkg meta_comp

let metagen conf pkgs mode =
  let warn = pkgs = `All in
  begin
    Cli.lookup_pkgs conf pkgs >>= fun pkgs ->
    let multi = Pkg.Set.cardinal pkgs > 1 in
    let cmd = match mode with
    | `Raw -> meta_raw
    | `Norm -> meta_norm
    | `Gen -> meta_gen
    | `Cmp -> meta_comp
    in
    Log.on_iter_error_msg Pkg.Set.iter (cmd ~multi ~warn) pkgs;
    Ok 0
  end
  |> Cli.handle_error

(* Command line interface *)

open Cmdliner

let mode =
  let raw =
    let doc = "Output installed META file(s)." in
    Arg.info ["r"; "raw"] ~doc
  in
  let norm =
    let doc = "Output normalized installed META file(s)." in
    Arg.info ["n"; "normalize"] ~doc
  in
  let gen =
    let doc = "Output generated META file(s)." in
    Arg.info ["g"; "generate"] ~doc
  in
  let cmp =
    let doc = "Output comparison betwen normalized and installed META file." in
    Arg.info ["c"; "compare"] ~doc
  in
  Arg.(value & vflag `Cmp [`Raw, raw; `Norm, norm; `Gen, gen; `Cmp, cmp;])


let doc = "Generate package META files and compare them to existing ones"
let cmd =
  let info = Term.info "metagen" ~version:"%%VERSION%%" ~doc in
  let term = Term.(const metagen $ Odig_cli.conf () $ Cli.pkgs_or_all $ mode) in
  term, info

let () = match Term.eval cmd with
| `Error _ -> exit 1
| _ -> if Logs.err_count () > 0 then exit 1 else exit 0


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
