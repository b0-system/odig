(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Odig_support
open B0_std
open B00

let index_salt = "1"

let link_if_exists src dst = match src with
| None -> ()
| Some src ->
    Os.Path.symlink ~force:true ~make_path:true ~src dst |> Log.if_error ~use:()

(* Theme handling *)

let theme_dir = "_odoc-theme"
let set_theme conf t =
  let src = Odoc_theme.path t in
  let dst = Fpath.(Conf.htmldir conf / theme_dir) in
  Os.Path.symlink ~force:true ~make_path:true ~src dst

let find_and_set_theme conf =
  let set t = set_theme conf t |> Log.if_error ~level:Log.Warning ~use:() in
  let ts = Odoc_theme.of_dir (Conf.sharedir conf) in
  let theme = Conf.odoc_theme conf in
  match Odoc_theme.find theme ts with
  | Ok t -> set t
  | Error e ->
      Log.warn begin fun m ->
        m "@[<v>%s@,Using default theme %s@]" e Odoc_theme.default
      end;
      match Odoc_theme.find Odoc_theme.default ts with
      | Error e -> Log.warn (fun m -> m "Can't find default theme %s" e)
      | Ok t -> set t

(* Builder *)

type builder =
  { m : Memo.t;
    conf : Conf.t;
    odocdir : Fpath.t;
    htmldir : Fpath.t;
    index_title : string option;
    index_intro : Fpath.t option;
    cobjs_by_modname : Doc_cobj.t list String.Map.t;
    mutable cobjs_by_digest : Doc_cobj.t list Digest.Map.t;
    mutable cobj_deps : (B0_odoc.Compile.Dep.t list Memo.Fut.t) Fpath.Map.t;
    mutable pkgs_todo : Pkg.Set.t;
    mutable pkgs_seen : Pkg.Set.t; }

let builder m conf index_title index_intro pkgs_todo =
  let cachedir = Conf.cachedir conf in
  let odocdir = Fpath.(cachedir / "odoc") in
  let htmldir = Conf.htmldir conf in
  let cobjs_by_modname =
    let add p i acc = Doc_cobj.by_modname ~init:acc (Pkg_info.doc_cobjs i) in
    Pkg.Map.fold add (Conf.pkg_infos conf) String.Map.empty
  in
  let cobjs_by_digest = Digest.Map.empty in
  let cobj_deps = Fpath.Map.empty in
  let pkgs_todo = Pkg.Set.of_list pkgs_todo in
  let pkgs_seen = Pkg.Set.empty in
  { m; conf; odocdir; htmldir; index_title; index_intro; cobjs_by_modname;
    cobjs_by_digest; cobj_deps; pkgs_todo; pkgs_seen }

let pkg_htmldir b pkg = Fpath.(b.htmldir / Pkg.name pkg)
let pkg_odocdir b pkg = Fpath.(b.odocdir / Pkg.name pkg)

let require_pkg b pkg =
  if Pkg.Set.mem pkg b.pkgs_seen || Pkg.Set.mem pkg b.pkgs_todo then () else
  (Log.debug (fun m -> m "Package request %a" Pkg.pp pkg);
   b.pkgs_todo <- Pkg.Set.add pkg b.pkgs_todo)

let odoc_file_for_cobj b cobj =
  let chop_libdir_prefix pkg cobj = (* assert [cobj] in libdir of [pkg] *)
    let libdir = Pkg.path pkg in
    let libdir = Fpath.(to_string @@ to_dir_path @@ libdir) in
    let cobj = Fpath.to_string cobj in
    Fpath.v (String.with_index_range ~first:(String.length libdir) cobj)
  in
  let pkg = Doc_cobj.pkg cobj in
  let cobj = chop_libdir_prefix pkg (Doc_cobj.path cobj) in
  Fpath.(pkg_odocdir b pkg // cobj -+ ".odoc")

let odoc_file_for_mld b pkg mld = (* assume mld names are flat *)
  let page = Fmt.str "page-%s" (Fpath.basename mld) in
  Fpath.(pkg_odocdir b pkg / page -+ ".odoc")

let require_cobj_deps b cobj = (* Also used to find the digest of cobj *)
  let add_cobj_by_digest b cobj d =
    let cobjs = try Digest.Map.find d b.cobjs_by_digest with Not_found -> [] in
    b.cobjs_by_digest <- Digest.Map.add d (cobj :: cobjs) b.cobjs_by_digest
  in
  let set_cobj_deps b cobj dep =
    b.cobj_deps <- Fpath.Map.add (Doc_cobj.path cobj) dep b.cobj_deps
  in
  match Fpath.Map.find (Doc_cobj.path cobj) b.cobj_deps with
  | deps -> deps
  | exception Not_found ->
      let fut_deps, set_deps = Memo.Fut.create b.m in
      let odoc_file = odoc_file_for_cobj b cobj in
      let deps_file = Fpath.(odoc_file + ".deps") in
      set_cobj_deps b cobj fut_deps;
      begin
        Memo.file_ready b.m (Doc_cobj.path cobj);
        (* FIXME should redirections in memo create dirs ? *)
        Memo.mkdir b.m (Fpath.parent odoc_file) @@ fun () ->
        B0_odoc.Compile.Dep.write b.m (Doc_cobj.path cobj) ~o:deps_file;
        B0_odoc.Compile.Dep.read b.m deps_file @@ fun deps ->
        let rec loop acc = function
        | [] -> Memo.Fut.set set_deps acc
        | d :: ds ->
            match B0_odoc.Compile.Dep.name d = Doc_cobj.modname cobj with
            | true ->
                add_cobj_by_digest b cobj (B0_odoc.Compile.Dep.digest d);
                loop acc ds
            | false ->
                loop (d :: acc) ds
        in
        loop [] deps
      end;
      fut_deps

let cobj_deps b cobj k = Memo.Fut.wait (require_cobj_deps b cobj) k
let cobj_deps_to_odoc_deps b deps k =
  (* For each dependency this tries to find a cmi, cmti or cmt file
     that matches the dependency name and digest. We first look by
     dependency name in the universe and then request on the fly the
     computation of their digest via [require_cobj_deps] which updates
     b.cobjs_by_digest as a side effect. Once the proper compilation
     object has been found we then return the odoc file for that
     file. Since we need to make sure that this odoc file actually
     gets built its package is added to the set of packages that need
     to be built. *)
  let candidate_cobjs dep =
    let n = B0_odoc.Compile.Dep.name dep in
    let cobjs = match String.Map.find n b.cobjs_by_modname with
    | cobjs -> cobjs
    | exception Not_found ->
        Log.debug (fun m -> m "Cannot find compilation object for %s" n);
        []
    in
    dep, List.map (fun cobj -> cobj, (require_cobj_deps b cobj)) cobjs
  in
  let resolve_dep (dep, candidates) acc k =
    let rec loop = function
    | [] ->
        Log.debug begin fun m ->
          m "Cannot resolve dependency for %a" B0_odoc.Compile.Dep.pp dep
        end;
        k acc
    | (cobj, deps) :: cs ->
        Memo.Fut.wait deps begin fun _ ->
          let digest = B0_odoc.Compile.Dep.digest dep in
          match Digest.Map.find digest b.cobjs_by_digest with
          | exception Not_found -> loop cs
          | cobj :: _ (* FIXME Log on debug. *) ->
              require_pkg b (Doc_cobj.pkg cobj);
              k (odoc_file_for_cobj b cobj :: acc)
          | [] -> assert false
        end
    in
    loop candidates
  in
  let dep_candidates_list = List.map candidate_cobjs deps in
  let rec loop cs acc = match cs with
  | [] -> k acc
  | c :: cs -> resolve_dep c acc (loop cs)
  in
  loop dep_candidates_list []

let cobj_to_odoc b cobj =
  let to_odoc = odoc_file_for_cobj b cobj in
  let writes = Fpath.(to_odoc + ".writes") in
  begin
    B0_odoc.Compile.Writes.write b.m (Doc_cobj.path cobj) ~to_odoc ~o:writes;
    cobj_deps b cobj @@ fun deps ->
    cobj_deps_to_odoc_deps b deps @@ fun odoc_deps ->
    B0_odoc.Compile.Writes.read b.m writes @@ fun writes ->
    let pkg = Pkg.name (Doc_cobj.pkg cobj) in
    let hidden = Doc_cobj.hidden cobj in
    let cobj = Doc_cobj.path cobj in
    B0_odoc.Compile.cmd b.m ~hidden ~odoc_deps ~writes ~pkg cobj ~o:to_odoc
  end;
  to_odoc

let mld_to_odoc b pkg pkg_odocs mld =
  let odoc = odoc_file_for_mld b pkg mld in
  let writes = Fpath.(odoc + ".writes") in
  begin
    B0_odoc.Compile.Writes.write b.m mld ~to_odoc:odoc ~o:writes;
    B0_odoc.Compile.Writes.read b.m writes @@ fun writes ->
    let pkg = Pkg.name pkg in
    let odoc_deps = pkg_odocs
      (* XXX odoc compile-deps does not work on .mld files, so we
         simply depend on all of the package's odoc files. This is
         needed for example for {!modules } to work in the index.

         trefis says: In the long term this will be solved since all
         reference resolution will happen at the `html-deps` step. For
         now that seems a good approximation. *)
    in
    B0_odoc.Compile.cmd b.m ~odoc_deps ~writes ~pkg mld ~o:odoc
  end;
  odoc

let index_mld_for_pkg b pkg pkg_info pkg_odocs ~user_index_mld =
  let index_mld = Fpath.(pkg_odocdir b pkg / "index.mld") in
  let write_index_mld ~user_index =
    let reads = Option.to_list user_index_mld in
    Memo.write b.m ~salt:index_salt ~reads index_mld @@ fun () ->
    Ok (Odig_odoc_page.index_mld b.conf pkg pkg_info ~user_index)
  in
  begin match user_index_mld with
  | None -> write_index_mld ~user_index:None
  | Some i -> Memo.read b.m i @@ fun s -> write_index_mld ~user_index:(Some s)
  end;
  index_mld

let mlds_to_odoc b pkg pkg_info pkg_odocs mlds =
  let rec loop ~made_index odocs = function
  | mld :: mlds ->
      Memo.file_ready b.m mld;
      let mld, made_index = match Fpath.basename mld = "index.mld" with
      | false -> mld, made_index
      | true ->
          let user_index_mld = Some mld in
          index_mld_for_pkg b pkg pkg_info pkg_odocs ~user_index_mld, true
      in
      loop ~made_index (mld_to_odoc b pkg pkg_odocs mld :: odocs) mlds
  | [] when made_index -> odocs
  | [] ->
      let user_index_mld = None in
      let mld = index_mld_for_pkg b pkg pkg_info pkg_odocs ~user_index_mld in
      (mld_to_odoc b pkg pkg_odocs mld :: odocs)
  in
  loop ~made_index:false [] mlds

let html_deps_resolve b deps k =
  let deps = List.rev_map B0_odoc.Html.Dep.to_compile_dep deps in
  cobj_deps_to_odoc_deps b deps k

let odoc_to_html b ~odoc_deps odoc =
  let theme_uri = theme_dir in
  let writes = Fpath.(odoc -+ ".html.writes") in
  B0_odoc.Html.Writes.write b.m ~odoc_deps odoc ~to_dir:b.htmldir ~o:writes;
  B0_odoc.Html.Writes.read b.m writes @@ fun writes ->
  B0_odoc.Html.cmd b.m ~theme_uri ~odoc_deps ~writes odoc ~to_dir:b.htmldir

let link_odoc_assets b pkg pkg_info =
  let src = Docdir.odoc_assets_dir (Pkg_info.docdir pkg_info) in
  let dst = Fpath.(pkg_htmldir b pkg / "_assets") in
  link_if_exists src dst

let link_odoc_docdir b pkg pkg_info =
  let src = Docdir.dir (Pkg_info.docdir pkg_info) in
  let dst = Fpath.(pkg_htmldir b pkg / "_docdir") in
  link_if_exists src dst

let pkg_to_html b pkg =
  let pkg_info = try Pkg.Map.find pkg (Conf.pkg_infos b.conf) with
  | Not_found -> assert false
  in
  let cobjs = Pkg_info.doc_cobjs pkg_info in
  let mlds = Docdir.odoc_pages (Pkg_info.docdir pkg_info) in
  match cobjs = [] && mlds = [] with
  | true -> false
  | false ->
      let odocs = List.map (cobj_to_odoc b) cobjs in
      let mld_odocs = mlds_to_odoc b pkg pkg_info odocs mlds in
      let odoc_files = List.rev_append odocs mld_odocs in
      let pkg_odoc_dir = pkg_odocdir b pkg in
      let deps_file = Fpath.(pkg_odoc_dir / Pkg.name pkg + ".html.deps") in
      B0_odoc.Html.Dep.write b.m ~odoc_files pkg_odoc_dir ~o:deps_file;
      B0_odoc.Html.Dep.read b.m deps_file begin fun deps ->
        html_deps_resolve b deps @@ fun odoc_deps ->
        List.iter (odoc_to_html b ~odoc_deps) odoc_files;
        link_odoc_assets b pkg pkg_info;
        link_odoc_docdir b pkg pkg_info;
      end;
      true

let write_support_files b =
  let to_dir = b.htmldir in
  let o = Fpath.(b.odocdir / "support-files.writes") in
  let without_theme = true in
  B0_odoc.Support_files.Writes.write b.m ~without_theme ~to_dir ~o;
  B0_odoc.Support_files.Writes.read b.m o @@ fun writes ->
  B0_odoc.Support_files.cmd b.m ~writes ~without_theme ~to_dir

let index_intro_to_html b k = match b.index_intro with
| None -> k None
| Some mld ->
    let is_odoc _ _ f acc = if Fpath.has_ext ".odoc" f then f :: acc else acc in
    let odoc_deps = Os.Dir.fold_files ~recurse:true is_odoc b.odocdir [] in
    let odoc_deps = Memo.fail_error odoc_deps in
    let o = Fpath.(b.odocdir / "index-header.html") in
    Memo.file_ready b.m mld;
    B0_odoc.Html_fragment.cmd b.m ~odoc_deps mld ~o;
    Memo.read b.m o @@ fun index_header -> k (Some index_header)

let write_pkgs_index b =
  let index = Fpath.(b.htmldir / "index.html") in
  let index_title = b.index_title in
  let pkg_index p = Fpath.(b.htmldir / Pkg.name p / "index.html") in
  let reads = Pkg.Set.fold (fun p acc -> pkg_index p :: acc) b.pkgs_seen [] in
  let reads = match b.index_intro with None -> reads | Some f -> f :: reads in
  index_intro_to_html b @@ fun raw_index_intro ->
  Memo.write b.m ~salt:index_salt ~reads index @@ fun () ->
  Ok (Odig_odoc_page.pkg_list b.conf ~index_title ~raw_index_intro)

let rec build b = match Pkg.Set.choose b.pkgs_todo with
| exception Not_found ->
    Memo.stir ~block:true b.m;
    if Pkg.Set.is_empty b.pkgs_todo
    then (write_support_files b; write_pkgs_index b; Memo.finish b.m)
    else build b
| pkg ->
    b.pkgs_todo <- Pkg.Set.remove pkg b.pkgs_todo;
    b.pkgs_seen <- Pkg.Set.add pkg b.pkgs_seen;
    let gens = pkg_to_html b pkg in
    if not gens then (b.pkgs_seen <- Pkg.Set.remove pkg b.pkgs_seen);
    build b

let pp_never ppf fs =
  Fmt.pf ppf "@[<v>Roots never became ready:@, %a" Fpath.Set.dump fs

let gen conf ~force ~index_title ~index_intro pkgs_todo =
  try
    Result.bind (Conf.memo conf) @@ fun memo ->
    find_and_set_theme conf;
    let b = builder memo conf index_title index_intro pkgs_todo in
    build b |> Log.if_error_pp pp_never ~use:();
    Log.info (fun m -> m ~header:"STATS" "%a" B0_ui.Memo.pp_stats memo);
    Ok ()
  with Failure e -> Error e

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
