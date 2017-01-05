(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* odoc generation

   We consider that what needs to be documented for a package are all
   compilation units that have a cmi file. We do all the dependency
   analysis on cmi files, however to generate their corresponding
   .odoc file we check if there's not a cmt or cmti file (in that
   order) to use at the same location instead of the cmi. *)

let css_file conf = Fpath.(Odig_etc.dir / "odoc.css")
let htmldir conf =
  let root = Fpath.(Odig_conf.cachedir conf / "odoc") in
  function None -> root | Some p -> Fpath.(root / Odig_pkg.name p)

let compile_dst pkg src =
  let pkgdir = Odig_pkg.libdir pkg in
  let cachedir = Odig_pkg.cachedir pkg in
  match Fpath.rem_prefix pkgdir src with
  | None -> assert false
  | Some p -> Fpath.(cachedir // p -+ ".odoc")

let find_best_src_for_odoc pkg cmi =
  let cobjs = Odig_pkg.cobjs pkg in
  let find obj_cmi_digest obj_path ext objs =
    let p = Fpath.set_ext ext (Odig_cobj.Cmi.path cmi) in
    let digest = Odig_cobj.Cmi.digest cmi in
    let is_src o = digest = obj_cmi_digest o && Fpath.equal p (obj_path o) in
    try Some (obj_path @@ List.find is_src objs) with Not_found -> None
  in
  match Odig_cobj.(find Cmti.digest Cmti.path ".cmti" (cmtis cobjs)) with
  | Some cmti -> cmti
  | None ->
      match Odig_cobj.(find Cmt.cmi_digest Cmt.path ".cmt" (cmts cobjs)) with
      | Some cmt -> cmt
      | None -> Odig_cobj.Cmi.path cmi

let cmi_deps pkg cmi =
  let cmi_path = Odig_cobj.Cmi.path cmi in
  let add_cmi i acc (name, d) = match d with
  | None -> acc
  | Some d ->
      match Odig_cobj.Index.cmis_for_interface i (`Digest d) with
      | [] ->
          Logs.warn
            (fun m -> m "%s: %a: No cmi found for %s (%s)"
                (Odig_pkg.name pkg) Fpath.pp cmi_path name (Digest.to_hex d));
          acc
      | cmi :: cmis ->
          (* Any should do FIXME really ? *)
          cmi :: acc
  in
  Odig_pkg.conf_cobj_index (Odig_pkg.conf pkg)
  >>= fun i ->
  let deps = Odig_cobj.Cmi.deps cmi in
  Ok (List.fold_left (add_cmi i) [] deps)

let incs_of_deps ?(odoc = false) deps =
  let add acc ((`Pkg pkg), cmi) =
    let path = Odig_cobj.Cmi.path cmi in
    let path = if odoc then compile_dst pkg path else path in
    Fpath.(Set.add (parent path) acc)
  in
  let incs = Fpath.Set.elements @@ List.fold_left add Fpath.Set.empty deps in
  Cmd.(of_values ~slip:"-I" p incs)

let rec build_cmi_deps ~odoc seen pkg cmi = (* FIXME not t.r. *)
  let build seen (pkg, cmi) =
    Logs.on_error_msg ~use:(fun _ -> seen)
      (_compile_to_odoc ~odoc ~force:false (* really ? *) seen pkg cmi)
  in
  (cmi_deps pkg cmi >>| fun deps ->
   deps, List.fold_left build seen deps)
  |> Logs.on_error_msg ~use:(fun _ -> [], seen)

and _compile_to_odoc ~odoc ~force seen (`Pkg pkg) cmi =
  let cmi_path = Odig_cobj.Cmi.path cmi in
  if Fpath.Set.mem cmi_path seen then (Ok seen) else
  let seen = Fpath.Set.add cmi_path seen in
  let dst = compile_dst pkg cmi_path in
  let cobjs_trail = Odig_pkg.cobjs_trail pkg in
  let dst_trail = Odig_btrail.v ~id:(Fpath.to_string dst) in
  let is_fresh =
    if force then Ok false else match Odig_btrail.status dst_trail with
    | `Stale -> Ok false
    | `Fresh ->
        (* FIXME this is ugly *)
        if Odig_btrail.witness dst_trail = Some "ERROR" then Ok true else
        OS.File.exists dst
  in
  is_fresh >>= function
  | true -> Ok seen
  | false ->
      (* FIXME we should do the trail on deps *)
      let deps, seen = build_cmi_deps ~odoc seen pkg cmi in
      let incs = incs_of_deps deps in
      let src = find_best_src_for_odoc pkg cmi in
      let pkg = Cmd.(v "--pkg" % Odig_pkg.name pkg) in
      let odoc = Cmd.(odoc % "compile" %% incs %% pkg % "-o" % p dst %
                      p src)
      in
      OS.Dir.create ~path:true (Fpath.parent dst) >>= fun _ ->
      OS.Cmd.run_status odoc >>= begin function
      | `Exited 0 -> Odig_digest.file dst >>| fun d -> Some d
      | _ -> Ok (Some "ERROR" (* FIXME *))
      end
      >>| fun digest ->
      Odig_btrail.set_witness ~preds:([cobjs_trail]) dst_trail digest;
      seen

and compile_to_odoc ~odoc ~force pkg cmi =
  _compile_to_odoc ~odoc ~force Fpath.Set.empty pkg cmi >>| fun _ -> ()

let compile ~odoc ~force pkg =
  let cmis = Odig_cobj.cmis (Odig_pkg.cobjs pkg) in
  let compile_to_odoc = compile_to_odoc ~odoc ~force (`Pkg pkg) in
  Odig_log.time
    (fun _ m -> m "Compiled odoc files of %s" @@ Odig_pkg.name pkg)
    (Odig_log.on_iter_error_msg List.iter compile_to_odoc) cmis;
  Ok ()

let html_of_odoc ~odoc ~force pkg cmi =
  (* Force is ignored, html may create new links because of new pkgs.
     FIXME have a more fine dep analysis of this. *)
  let cmi_path = Odig_cobj.Cmi.path cmi in
  let odoc_file = compile_dst pkg cmi_path in
  cmi_deps pkg cmi >>= fun deps ->
  let incs = incs_of_deps ~odoc:true deps in
  let htmlroot = htmldir (Odig_pkg.conf pkg) None in
  OS.Cmd.run Cmd.(odoc % "html" %% incs % "-o" % p htmlroot % p odoc_file)

let html_index ~odoc ~force pkg =
  let htmldir = htmldir (Odig_pkg.conf pkg) in
  let incs =
    let cmis = Odig_cobj.cmis (Odig_pkg.cobjs pkg) in
    let to_dep cmi = `Pkg pkg, cmi in
    incs_of_deps ~odoc:true (List.rev_map to_dep cmis)
  in
  let name = Odig_pkg.name pkg in
  let page = Odig_api_doc.pkg_page_mld ~tool:`Odoc ~htmldir pkg in
  let htmlroot = htmldir None in
  OS.File.tmp "odig-index-%s.mld"
  >>= fun index_file -> OS.File.write index_file page
  >>= fun () ->
  OS.Cmd.run Cmd.(odoc % "html" %% incs % "-o" % p htmlroot %
                  "--index-for" % name % p index_file)

let html ~odoc ~force pkg =
  let htmldir = htmldir (Odig_pkg.conf pkg) (Some pkg) in
  let cmis = Odig_cobj.cmis (Odig_pkg.cobjs pkg) in
  let html pkg =
    let html_of_odoc = html_of_odoc ~odoc ~force pkg in
    Odig_log.on_iter_error_msg List.iter html_of_odoc cmis;
    html_index ~odoc ~force pkg
  in
  OS.Dir.create ~path:true htmldir >>= fun _ ->
  Odig_log.time
    (fun _ m -> m "Compiled HTML files of %s" @@ Odig_pkg.name pkg)
    html pkg

let htmldir_css_and_index conf =
  let partition htmldir pkgs =
    let classify p (has_doc, no_doc as acc) =
      begin
        OS.Dir.exists (htmldir (Some p)) >>| function
        | true -> (p :: has_doc, no_doc)
        | false -> (has_doc, p :: no_doc)
      end
      |> Odig_log.on_error_msg ~use:(fun _ -> acc)
    in
    let has_doc, no_doc = Odig_pkg.Set.fold classify pkgs ([], []) in
    List.rev has_doc, List.rev no_doc
  in
  let htmldir = htmldir conf in
  let htmlroot = htmldir None in
  Odig_pkg.set conf
  >>= function pkgs -> Ok (partition htmldir pkgs)
  >>= fun (has_doc, no_doc) ->
  Ok (Odig_api_doc.pkg_index ~tool:`Odoc ~htmldir conf ~has_doc ~no_doc)
  >>= fun index -> OS.File.write Fpath.(htmlroot / "index.html") index
  >>= fun () -> OS.File.read (css_file conf)
  >>= fun css -> OS.File.write Fpath.(htmlroot / "odoc.css") css

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
