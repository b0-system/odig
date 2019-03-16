(*---------------------------------------------------------------------------
   Copyright (c) 2018 The odig programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Odig_support
open B0_std
open B00

let index_stamp = "%%VERSION%%"

let link_if_exists src dst = match src with
| None -> ()
| Some src ->
    Os.Path.symlink ~force:true ~make_path:true ~src dst |> Log.if_error ~use:()

(* Theme handling *)

let ocaml_manual_pkg = "ocaml-manual"
let theme_dir = "_odoc-theme"

let set_theme conf t = (* Not symlinking because of file: and FF. *)
  Log.time (fun _ m -> m "setting theme") @@ fun () ->
  let src = Odoc_theme.path t in
  let dst = Fpath.(Conf.htmldir conf / theme_dir) in
  let replace src dst =
    let allow_hardlinks = true and make_path = true and recurse = true in
    Result.bind (Os.Path.delete ~recurse:true dst) @@ fun _ ->
    Os.Dir.copy ~allow_hardlinks ~make_path ~recurse ~src dst
  in
  Result.bind (replace src dst) @@ fun () ->
  let manual_dir = Fpath.(Conf.htmldir conf / ocaml_manual_pkg) in
  match Os.Dir.exists manual_dir |> Log.if_error ~use:false with
  | false -> Ok ()
  | true ->
      let theme_man_css = Fpath.(src / "manual.css") in
      let manual_css = Fpath.(manual_dir / "manual.css") in
      match Os.File.exists theme_man_css |> Log.if_error ~use:false with
      | false ->
          let css = Fpath.(Conf.docdir conf / ocaml_manual_pkg / "manual.css")
          in
          Os.File.copy ~force:true ~make_path:true ~src:css manual_css
      | true ->
          let dst = Fpath.(manual_dir / theme_dir) in
          (* We copy the theme again in ocaml-manual because of FF... *)
          Result.bind (replace src dst) @@ fun () ->
          let css = "@charset UTF-8;\n@import url(\"_odoc-theme/manual.css\");"
          in
          Os.File.write ~force:true ~make_path:true manual_css css

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
    pkg_deps : bool;
    tag_index : bool;
    cobjs_by_modname : Doc_cobj.t list String.Map.t;
    mutable cobjs_by_digest : Doc_cobj.t list Digest.Map.t;
    mutable cobj_deps : (B0_odoc.Compile.Dep.t list Memo.Fut.t) Fpath.Map.t;
    mutable pkgs_todo : Pkg.Set.t;
    mutable pkgs_seen : Pkg.Set.t; }

let builder m conf ~index_title ~index_intro ~pkg_deps ~tag_index pkgs_todo =
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
  { m; conf; odocdir; htmldir; index_title; index_intro; pkg_deps; tag_index;
    cobjs_by_modname; cobjs_by_digest; cobj_deps; pkgs_todo; pkgs_seen }

let pkg_htmldir b pkg = Fpath.(b.htmldir / Pkg.name pkg)
let pkg_odocdir b pkg = Fpath.(b.odocdir / Pkg.name pkg)

let require_pkg b pkg =
  if Pkg.Set.mem pkg b.pkgs_seen || Pkg.Set.mem pkg b.pkgs_todo then () else
  (Log.debug (fun m -> m "Package request %a" Pkg.pp pkg);
   b.pkgs_todo <- Pkg.Set.add pkg b.pkgs_todo)

let odoc_file_for_cobj b cobj =
  let pkg = Doc_cobj.pkg cobj in
  let cobj = Doc_cobj.path cobj in
  let cobj = Option.get (Fpath.rem_prefix (Pkg.path pkg) cobj) in
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
        Memo.mkdir b.m (Fpath.parent odoc_file) @@ fun _ ->
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
     to be built; unless [b.pkg_deps] is false. *)
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
              begin match b.pkg_deps with
              | true ->
                  require_pkg b (Doc_cobj.pkg cobj);
                  k (odoc_file_for_cobj b cobj :: acc)
              | false ->
                  let pkg = Doc_cobj.pkg cobj in
                  if Pkg.Set.mem pkg b.pkgs_todo || Pkg.Set.mem pkg b.pkgs_seen
                  then k (odoc_file_for_cobj b cobj :: acc)
                  else loop cs
              end
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
    let reads = match Opam.file pkg with
    | None -> reads
    | Some file -> Memo.file_ready b.m file; file :: reads
    in
    let stamp =
      (* Influences the index content *)
      let readmes = Docdir.readme_files (Pkg_info.docdir pkg_info) in
      let changes = Docdir.changes_files (Pkg_info.docdir pkg_info) in
      let licenses = Docdir.license_files (Pkg_info.docdir pkg_info) in
      let files = List.(rev_append readmes (rev_append changes licenses)) in
      let data = index_stamp :: List.rev_map Fpath.to_string files in
      Hash.to_bytes (Memo.hash_string b.m (String.concat "" data))
    in
    Memo.write b.m ~stamp ~reads index_mld @@ fun () ->
    let with_tag_links = b.tag_index in
    Ok (Odig_odoc_page.index_mld b.conf pkg pkg_info ~with_tag_links
          ~user_index)
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

let write_ocaml_manual b =
  (* Not symlinking because of file: and FF *)
  (* FIXME this is out of b0 we should make a decision about copy files & co *)
  let manual_pkg_dir = Fpath.(Conf.docdir b.conf / ocaml_manual_pkg) in
  let manual_index = Fpath.(manual_pkg_dir / "index.html") in
  let src = manual_pkg_dir in
  let dst = Fpath.(Conf.htmldir b.conf / ocaml_manual_pkg) in
  match Os.File.exists manual_index |> Log.if_error ~use:false with
  | false -> Ok None
  | true ->
      let recurse = true and make_path = true and allow_hardlinks = true in
      Result.bind (Os.Path.delete ~recurse dst) @@ fun _ ->
      Result.bind (Os.Dir.copy ~allow_hardlinks ~make_path ~recurse ~src dst)
      @@ fun _ -> Ok (Some "ocaml-manual/index.html")

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

let write_pkgs_index b ~ocaml_manual_uri =
  let index = Fpath.(b.htmldir / "index.html") in
  let index_title = b.index_title in
  let pkg_index p = Fpath.(b.htmldir / Pkg.name p / "index.html") in
  let reads = Pkg.Set.fold (fun p acc -> pkg_index p :: acc) b.pkgs_seen [] in
  let reads = match b.index_intro with None -> reads | Some f -> f :: reads in
  index_intro_to_html b @@ fun raw_index_intro ->
  Memo.write b.m ~stamp:index_stamp ~reads index @@ fun () ->
  Ok (Odig_odoc_page.pkg_list b.conf ~index_title ~raw_index_intro
        ~tag_index:b.tag_index ~ocaml_manual_uri)

let rec build b = match Pkg.Set.choose b.pkgs_todo with
| exception Not_found ->
    Memo.stir ~block:true b.m;
    begin match Pkg.Set.is_empty b.pkgs_todo with
    | false -> build b
    | true ->
        write_support_files b;
        let ocaml_manual_uri = write_ocaml_manual b |> Log.if_error ~use:None in
        write_pkgs_index b ~ocaml_manual_uri ;
        Memo.finish b.m
    end
| pkg ->
    b.pkgs_todo <- Pkg.Set.remove pkg b.pkgs_todo;
    b.pkgs_seen <- Pkg.Set.add pkg b.pkgs_seen;
    let gens = pkg_to_html b pkg in
    if not gens then (b.pkgs_seen <- Pkg.Set.remove pkg b.pkgs_seen);
    build b

let pp_never ppf fs =
  Fmt.pf ppf "@[<v>Roots never became ready:@, %a" Fpath.Set.dump fs

let gen conf ~force ~index_title ~index_intro ~pkg_deps ~tag_index pkgs_todo =
  try
    Result.bind (Conf.memo conf) @@ fun memo ->
    let b =
      builder memo conf ~index_title ~index_intro ~pkg_deps ~tag_index pkgs_todo
    in
    build b |> Log.if_error_pp pp_never ~use:();
    find_and_set_theme conf;
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
