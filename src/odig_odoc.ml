(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

open Odig_support
open B00_std
open B00_std.Fut.Syntax
open B00

let odig_version = "%%VERSION%%"

let link_if_exists src dst = match src with
| None -> ()
| Some src ->
    Os.Path.symlink ~force:true ~make_path:true ~src dst |> Log.if_error ~use:()

(* Theme handling *)

let ocaml_manual_pkg = "ocaml-manual"

let get_theme conf =
  let ts = B00_odoc.Theme.of_dir (Conf.share_dir conf) in
  let odig_theme =
    let odig t = B00_odoc.Theme.name t = B00_odoc.Theme.odig_default in
    match List.find odig ts with exception Not_found -> None | t -> Some t
  in
  let name = Conf.odoc_theme conf in
  let fallback = match odig_theme with
  | Some t -> Some (B00_odoc.Theme.name t)
  | None -> Some (B00_odoc.Theme.odoc_default)
  in
  Log.if_error ~level:Log.Warning ~use:odig_theme @@
  Result.bind (B00_odoc.Theme.find ~fallback name ts) @@ fun t ->
  Ok (Some t)

let write_ocaml_manual_theme conf m theme =
  let write_original_css conf ~o =
    let css = Fpath.(Conf.doc_dir conf / ocaml_manual_pkg / "manual.css") in
    ignore @@
    let* () = B00.Memo.delete m o in
    B00.Memo.file_ready m css;
    Memo.copy m ~src:css o;
    Fut.return ()
  in
  let manual_dir = Fpath.(Conf.html_dir conf / ocaml_manual_pkg) in
  match Os.Dir.exists manual_dir |> Log.if_error ~use:false with
  | false -> ()
  | true ->
      let manual_css = Fpath.(manual_dir / "manual.css") in
      let theme_manual_css = match theme with
      | None -> None
      | Some t ->
          let css = Fpath.(B00_odoc.Theme.path t / "manual.css") in
          if Os.File.exists css |> Log.if_error ~use:false
          then Some (t, css)
          else None
      in
      match theme_manual_css with
      | None -> write_original_css conf ~o:manual_css
      | Some (t, css) ->
          (* We copy the theme again in ocaml-manual because of FF. *)
          let to_dir = Fpath.(manual_dir / B00_odoc.Theme.default_uri) in
          ignore @@
          let* () = B00.Memo.delete m to_dir in
          B00_odoc.Theme.write m t ~to_dir;
          (Memo.write m manual_css @@ fun () ->
           Ok "@charset UTF-8;\n@import url(\"_odoc-theme/manual.css\");");
          Fut.return ()

let write_theme conf m theme =
  let to_dir = Fpath.(Conf.html_dir conf / B00_odoc.Theme.default_uri) in
  let* () = B00.Memo.delete m to_dir in
  (match theme with None -> () | Some t -> B00_odoc.Theme.write m t ~to_dir);
  write_ocaml_manual_theme conf m theme;
  Fut.return ()

(* Builder *)

type resolver =
  { mutable cobjs_by_digest : Doc_cobj.t list Digest.Map.t;
    mutable cobj_deps : (B00_odoc.Compile.Dep.t list Fut.t) Fpath.Map.t;
    mutable pkgs_todo : Pkg.Set.t;
    mutable pkgs_seen : Pkg.Set.t; }

type builder =
  { m : Memo.t;
    conf : Conf.t;
    odoc_dir : Fpath.t;
    html_dir : Fpath.t;
    theme : B00_odoc.Theme.t option;
    index_title : string option;
    index_intro : Fpath.t option;
    pkg_deps : bool;
    tag_index : bool;
    cobjs_by_modname : Doc_cobj.t list String.Map.t;
    r : resolver; }

let builder m conf ~index_title ~index_intro ~pkg_deps ~tag_index pkgs_todo =
  let cache_dir = Conf.cache_dir conf in
  let odoc_dir = Fpath.(cache_dir / "odoc") in
  let html_dir = Conf.html_dir conf in
  let theme = get_theme conf in
  let cobjs_by_modname =
    let add p i acc = Doc_cobj.by_modname ~init:acc (Pkg_info.doc_cobjs i) in
    Pkg.Map.fold add (Conf.pkg_infos conf) String.Map.empty
  in
  let cobjs_by_digest = Digest.Map.empty in
  let cobj_deps = Fpath.Map.empty in
  let pkgs_todo = Pkg.Set.of_list pkgs_todo in
  let pkgs_seen = Pkg.Set.empty in
  { m; conf; odoc_dir; html_dir; theme; index_title; index_intro; pkg_deps;
    tag_index; cobjs_by_modname;
    r = { cobjs_by_digest; cobj_deps; pkgs_todo; pkgs_seen } }

let require_pkg b pkg =
  if Pkg.Set.mem pkg b.r.pkgs_seen || Pkg.Set.mem pkg b.r.pkgs_todo then () else
  (Log.debug (fun m -> m "Package request %a" Pkg.pp pkg);
   b.r.pkgs_todo <- Pkg.Set.add pkg b.r.pkgs_todo)

let pkg_assets_dir = "_assets"
let pkg_html_dir b pkg = Fpath.(b.html_dir / Pkg.name pkg)
let pkg_odoc_dir b pkg = Fpath.(b.odoc_dir / Pkg.name pkg)

let odoc_file_for_cobj b cobj =
  let pkg = Doc_cobj.pkg cobj in
  let root = Pkg.path pkg in
  let dst = pkg_odoc_dir b pkg in
  let cobj = Doc_cobj.path cobj in
  Fpath.(reroot ~root ~dst cobj -+ ".odoc")

let odoc_file_for_mld b pkg mld = (* assume mld names are flat *)
  let page = Fmt.str "page-%s" (Fpath.basename mld) in
  Fpath.(pkg_odoc_dir b pkg / page -+ ".odoc")

let require_cobj_deps b cobj = (* Also used to find the digest of cobj *)
  let add_cobj_by_digest b cobj d =
    let cobjs = try Digest.Map.find d b.r.cobjs_by_digest with
    | Not_found -> []
    in
    b.r.cobjs_by_digest <- Digest.Map.add d (cobj :: cobjs) b.r.cobjs_by_digest
  in
  let set_cobj_deps b cobj dep =
    b.r.cobj_deps <- Fpath.Map.add (Doc_cobj.path cobj) dep b.r.cobj_deps
  in
  match Fpath.Map.find_opt (Doc_cobj.path cobj) b.r.cobj_deps with
  | Some deps -> deps
  | None ->
      let m = Memo.with_mark b.m (Pkg.name (Doc_cobj.pkg cobj)) in
      let fut_deps, set_deps = Fut.create () in
      let odoc_file = odoc_file_for_cobj b cobj in
      let deps_file = Fpath.(odoc_file + ".deps") in
      set_cobj_deps b cobj fut_deps;
      begin
        Memo.file_ready m (Doc_cobj.path cobj);
        B00_odoc.Compile.Dep.write m (Doc_cobj.path cobj) ~o:deps_file;
        ignore @@
        let* deps = B00_odoc.Compile.Dep.read m deps_file in
        let rec loop acc = function
        | [] -> set_deps acc; Fut.return ()
        | d :: ds ->
            match B00_odoc.Compile.Dep.name d = Doc_cobj.modname cobj with
            | true ->
                add_cobj_by_digest b cobj (B00_odoc.Compile.Dep.digest d);
                loop acc ds
            | false ->
                loop (d :: acc) ds
        in
        loop [] deps
      end;
      fut_deps

let cobj_deps b cobj = require_cobj_deps b cobj
let cobj_deps_to_odoc_deps b deps =
  (* For each dependency this tries to find a cmi, cmti or cmt file
     that matches the dependency name and digest. We first look by
     dependency name in the universe and then request on the fly the
     computation of their digest via [require_cobj_deps] which updates
     b.cobjs_by_digest as a side effect. Once the proper compilation
     object has been found we then return the odoc file for that
     file. Since we need to make sure that this odoc file actually
     gets built its package is added to the set of packages that need
     to be built; unless [b.pkg_deps] is false. *)
  let candidate_cobjs dep =
    let n = B00_odoc.Compile.Dep.name dep in
    let cobjs = match String.Map.find_opt n b.cobjs_by_modname with
    | Some cobjs -> cobjs
    | None ->
        Log.debug (fun m -> m "Cannot find compilation object for %s" n);
        []
    in
    dep, List.map (fun cobj -> cobj, (require_cobj_deps b cobj)) cobjs
  in
  let resolve_dep (dep, candidates) acc =
    let rec loop = function
    | [] ->
        Log.debug begin fun m ->
          m "Cannot resolve dependency for %a" B00_odoc.Compile.Dep.pp dep
        end;
        Fut.return acc
    | (cobj, deps) :: cs ->
        Fut.bind deps @@ fun _ ->
        let digest = B00_odoc.Compile.Dep.digest dep in
        match Digest.Map.find_opt digest b.r.cobjs_by_digest with
        | None -> loop cs
        | Some (cobj :: _ (* FIXME Log on debug. *)) ->
            begin match b.pkg_deps with
            | true ->
                require_pkg b (Doc_cobj.pkg cobj);
                Fut.return (odoc_file_for_cobj b cobj :: acc)
            | false ->
                let pkg = Doc_cobj.pkg cobj in
                if Pkg.Set.mem pkg b.r.pkgs_todo ||
                   Pkg.Set.mem pkg b.r.pkgs_seen
                then Fut.return (odoc_file_for_cobj b cobj :: acc)
                else loop cs
            end
        | Some [] -> assert false
    in
    loop candidates
  in
  let dep_candidates_list = List.map candidate_cobjs deps in
  let rec loop cs acc = match cs with
  | [] -> Fut.return acc
  | c :: cs -> Fut.bind (resolve_dep c acc) (loop cs)
  in
  loop dep_candidates_list []

let cobj_to_odoc b cobj =
  let odoc = odoc_file_for_cobj b cobj in
  begin
    ignore @@
    let* deps = cobj_deps b cobj in
    let* odoc_deps = cobj_deps_to_odoc_deps b deps in
    let pkg = Pkg.name (Doc_cobj.pkg cobj) in
    let hidden = Doc_cobj.hidden cobj in
    let cobj = Doc_cobj.path cobj in
    B00_odoc.Compile.to_odoc b.m ~hidden ~pkg ~odoc_deps cobj ~o:odoc;
    Fut.return ()
  end;
  odoc

let mld_to_odoc b pkg pkg_odocs mld =
  let odoc = odoc_file_for_mld b pkg mld in
  let pkg = Pkg.name pkg in
  let odoc_deps =
    (* XXX odoc compile-deps does not work on .mld files, so we
       simply depend on all of the package's odoc files. This is
       needed for example for {!modules } to work in the index.
       trefis says: In the long term this will be solved since all
       reference resolution will happen at the `html-deps` step. For
       now that seems a good approximation. *)
    pkg_odocs
  in
  B00_odoc.Compile.to_odoc b.m ~pkg ~odoc_deps mld ~o:odoc;
  odoc

let index_mld_for_pkg b pkg pkg_info _pkg_odocs ~user_index_mld =
  let index_mld = Fpath.(pkg_odoc_dir b pkg / "index.mld") in
  let write_index_mld ~user_index =
    let reads = Option.to_list user_index_mld in
    let reads = match Opam.file pkg with
    | None -> reads
    | Some file -> Memo.file_ready b.m file; file :: reads
    in
    let stamp =
      (* Influences the index content; we could relativize file paths *)
      let fields = List.rev_map snd Pkg_info.field_names in
      let data = List.rev_map (fun f -> Pkg_info.get f pkg_info) fields in
      let data = odig_version :: (Pkg.name pkg) :: List.concat data in
      Hash.to_bytes (Memo.hash_string b.m (String.concat "" data))
    in
    Memo.write b.m ~stamp ~reads index_mld @@ fun () ->
    let with_tag_links = b.tag_index in
    Ok (Odig_odoc_page.index_mld b.conf pkg pkg_info ~with_tag_links
          ~user_index)
  in
  begin match user_index_mld with
  | None -> write_index_mld ~user_index:None
  | Some i ->
      ignore @@
      let* s = Memo.read b.m i in
      write_index_mld ~user_index:(Some s);
      Fut.return ()
  end;
  index_mld

let mlds_to_odoc b pkg pkg_info pkg_odocs mlds =
  let rec loop ~user_index_mld pkg_odocs = function
  | mld :: mlds ->
      Memo.file_ready b.m mld;
      let odocs, user_index_mld = match Fpath.basename mld = "index.mld" with
      | false -> mld_to_odoc b pkg pkg_odocs mld :: pkg_odocs, user_index_mld
      | true -> pkg_odocs, Some mld
      in
      loop ~user_index_mld odocs mlds
  | [] ->
      (* We do the index at the end due to a lack of functioning
         of `compile-deps` on mld files this increases the chances
         we get the correct links towards other mld files since those
         will be in [odocs]. *)
      let mld = index_mld_for_pkg b pkg pkg_info pkg_odocs ~user_index_mld in
      (mld_to_odoc b pkg pkg_odocs mld :: pkg_odocs)
  in
  loop ~user_index_mld:None [] mlds

let html_deps_resolve b deps =
  let deps = List.rev_map B00_odoc.Html.Dep.to_compile_dep deps in
  cobj_deps_to_odoc_deps b deps

let link_odoc_assets b pkg pkg_info =
  let src = Doc_dir.odoc_assets_dir (Pkg_info.doc_dir pkg_info) in
  let dst = Fpath.(pkg_html_dir b pkg / pkg_assets_dir) in
  link_if_exists src dst

let link_odoc_doc_dir b pkg pkg_info =
  let src = Doc_dir.dir (Pkg_info.doc_dir pkg_info) in
  let dst = Fpath.(pkg_html_dir b pkg / "_doc-dir") in
  link_if_exists src dst

let pkg_to_html b pkg =
  let b = { b with m = Memo.with_mark b.m (Pkg.name pkg) } in
  let pkg_info = try Pkg.Map.find pkg (Conf.pkg_infos b.conf) with
  | Not_found -> assert false
  in
  let cobjs = Pkg_info.doc_cobjs pkg_info in
  let mlds = Doc_dir.odoc_pages (Pkg_info.doc_dir pkg_info) in
  if cobjs = [] && mlds = [] then Fut.return () else
  let pkg_html_dir = pkg_html_dir b pkg in
  let pkg_odoc_dir = pkg_odoc_dir b pkg in
  let* () = Memo.delete b.m pkg_html_dir in
  let* () = Memo.delete b.m pkg_odoc_dir in
  let odocs = List.map (cobj_to_odoc b) cobjs in
  let mld_odocs = mlds_to_odoc b pkg pkg_info odocs mlds in
  let odoc_files = List.rev_append odocs mld_odocs in
  let deps_file = Fpath.(pkg_odoc_dir / Pkg.name pkg + ".html.deps") in
  B00_odoc.Html.Dep.write b.m ~odoc_files pkg_odoc_dir ~o:deps_file;
  let* deps = B00_odoc.Html.Dep.read b.m deps_file in
  let* odoc_deps_res = html_deps_resolve b deps in
  (* XXX html deps is a bit broken make sure we have at least our
     own files as deps maybe related to compiler-deps not working on .mld
     files *)
  let odoc_deps = Fpath.uniquify (List.rev_append odoc_files odoc_deps_res) in
  let theme_uri = match b.theme with
  | Some _ -> Some B00_odoc.Theme.default_uri | None -> None
  in
  let html_dir = b.html_dir in
  let to_html = B00_odoc.Html.write b.m ?theme_uri ~html_dir ~odoc_deps in
  List.iter to_html odoc_files;
  link_odoc_assets b pkg pkg_info;
  link_odoc_doc_dir b pkg pkg_info;
  Fut.return ()

let index_intro_to_html b = match b.index_intro with
| None -> Fut.return None
| Some mld ->
    let mld = Fpath.(Conf.cwd b.conf // mld) in
    let is_odoc _ _ f acc = if Fpath.has_ext ".odoc" f then f :: acc else acc in
    let odoc_deps = Os.Dir.fold_files ~recurse:true is_odoc b.odoc_dir [] in
    let odoc_deps = Memo.fail_if_error b.m odoc_deps in
    let o = Fpath.(b.odoc_dir / "index-header.html") in
    Memo.file_ready b.m mld;
    B00_odoc.Html_fragment.cmd b.m ~odoc_deps mld ~o;
    let* index_header = Memo.read b.m o in
    Fut.return (Some index_header)

let write_pkgs_index b ~ocaml_manual_uri =
  let add_pkg_data pkg_infos acc p = match Pkg.Map.find p pkg_infos with
  | exception Not_found -> acc
  | info ->
      let version = Pkg_info.get `Version info in
      let synopsis = Pkg_info.get `Synopsis info in
      let tags = Pkg_info.get `Tags info in
      let ( ++ ) = List.rev_append in
      version ++ synopsis ++ tags ++ acc
  in
  let* raw_index_intro = index_intro_to_html b in
  let pkg_infos = Conf.pkg_infos b.conf in
  let pkgs = Odig_odoc_page.pkgs_with_html_docs b.conf in
  let stamp = match raw_index_intro with None -> [] | Some s -> [s] in
  let stamp = List.fold_left (add_pkg_data pkg_infos) stamp pkgs in
  let stamp = match ocaml_manual_uri with
  | None -> stamp
  | Some s -> (s :: stamp)
  in
  let stamp = String.concat " " (odig_version :: stamp) in
  let index = Fpath.(b.html_dir / "index.html") in
  let index_title = b.index_title in
  (Memo.write b.m ~stamp index @@ fun () ->
   Ok (Odig_odoc_page.pkg_list b.conf ~index_title ~raw_index_intro
         ~tag_index:b.tag_index ~ocaml_manual_uri pkgs));
  Fut.return ()

let write_ocaml_manual b =
  let manual_pkg_dir = Fpath.(Conf.doc_dir b.conf / ocaml_manual_pkg) in
  let manual_index = Fpath.(manual_pkg_dir / "index.html") in
  let dst = Fpath.(Conf.html_dir b.conf / ocaml_manual_pkg) in
  match Os.File.exists manual_index |> Log.if_error ~use:false with
  | false -> None
  | true ->
      begin
        ignore @@
        let* () = Memo.delete b.m dst in
        let copy_file m ~src_root ~dst_root src =
          let dst = Fpath.reroot ~root:src_root ~dst:dst_root src in
          B00.Memo.file_ready m src;
          B00.Memo.copy m ~src dst
        in
        let src = manual_pkg_dir in
        let files = Os.Dir.fold_files ~recurse:true Os.Dir.path_list src [] in
        let files = Memo.fail_if_error b.m files in
        List.iter (copy_file b.m ~src_root:src ~dst_root:dst) files;
        Fut.return ()
      end;
      Some "ocaml-manual/index.html"

let rec build b = match Pkg.Set.choose b.r.pkgs_todo with
| exception Not_found ->
    Memo.stir ~block:true b.m;
    begin match Pkg.Set.is_empty b.r.pkgs_todo with
    | false -> build b
    | true ->
        let without_theme = match b.theme with None -> true | Some _ -> false in
        let html_dir = b.html_dir and build_dir = b.odoc_dir in
        B00_odoc.Support_files.write b.m ~without_theme ~html_dir ~build_dir;
        let ocaml_manual_uri = write_ocaml_manual b in
        ignore (write_pkgs_index b ~ocaml_manual_uri);
        write_theme b.conf b.m b.theme;
    end
| pkg ->
    b.r.pkgs_todo <- Pkg.Set.remove pkg b.r.pkgs_todo;
    b.r.pkgs_seen <- Pkg.Set.add pkg b.r.pkgs_seen;
    ignore (pkg_to_html b pkg);
    build b

let write_log_file c memo =
  Log.if_error ~use:() @@
  B00_cli.Memo.Log.(write (Conf.b0_log_file c) (of_memo memo))

let gen c ~force ~index_title ~index_intro ~pkg_deps ~tag_index pkgs_todo =
  Result.bind (Conf.memo c) @@ fun m ->
  let b =
    builder m c ~index_title ~index_intro ~pkg_deps ~tag_index pkgs_todo
  in
  Os.Exit.on_sigint ~hook:(fun () -> write_log_file c m) @@ fun () ->
  Memo.run_proc m (fun () -> build b);
  Memo.stir ~block:true m;
  write_log_file c m;
  Log.time (fun _ m -> m "deleting trash") begin fun () ->
    Log.if_error ~use:() (B00.Memo.delete_trash ~block:false m)
  end;
  match Memo.status b.m with
  | Ok () as v -> v
  | Error e ->
      let read_howto = Fmt.any "odig log -r " in
      let write_howto = Fmt.any "odig log -w " in
      B000_conv.Op.pp_aggregate_error ~read_howto ~write_howto () Fmt.stderr e;
      Error "Documentation might be incomplete (see: odig log -e)."

let install_theme c theme =
  Result.bind (Conf.memo c) @@ fun m ->
  Memo.run_proc m (fun () -> write_theme c m theme);
  Memo.stir ~block:true m;
  match Memo.status m with
  | Ok () as v -> v
  | Error e -> Error "Could not set theme"

(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers

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
