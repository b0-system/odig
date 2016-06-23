(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

open Bos_setup

(* Finding the -I for a mli file. *)

let mli_cmi_deps pkg mli =
  let add_cmi i acc (name, d) = match d with
  | None -> acc
  | Some d ->
      let cmis, _, _, _ = Opkg_cobj_index.find_digest i d in
      match cmis with
      | [] ->
          Opkg_log.debug
            (fun m -> m "%s: %a: No cmi found for %s (%s)"
                (Opkg_pkg.name pkg) Fpath.pp mli name (Digest.to_hex d));
          acc
      | (_, cmi) :: cmis ->
          (* Any should do (though could introduce clashes through -I) *)
          cmi :: acc
  in
  let cmi = Fpath.(mli -+ ".cmi") in
  OS.File.exists cmi >>= function
  | false -> Ok []
  | true ->
      Opkg_cobj.Cmi.read cmi
      >>= fun cmi -> Opkg_cobj_index.create (Opkg_pkg.conf pkg)
      >>= fun i ->
      let deps = Opkg_cobj.Cmi.deps cmi in
      Ok (List.fold_left (add_cmi i) [] deps)

let mli_incs pkg mli =
  let add_inc acc cmi = Fpath.(Set.add (parent (Opkg_cobj.Cmi.path cmi)) acc) in
  begin
    let init = Fpath.Set.singleton (Fpath.parent mli) in
    mli_cmi_deps pkg mli >>| fun cmis ->
    Fpath.Set.elements @@ List.fold_left add_inc init cmis
  end
  |> Opkg_log.on_error_msg ~use:(fun _ -> [])

(* ocamldoc generation *)

let htmldir conf = Fpath.(Opkg_conf.cachedir conf / "ocamldoc")
let pkg_htmldir pkg =
  let htmldir = htmldir (Opkg_pkg.conf pkg) in
  Fpath.(htmldir / Opkg_pkg.name pkg)

let css_file conf = Fpath.(Opkg_etc.dir / "ocamldoc.css")

let compile_dst pkg mli =
  let pkgdir = Opkg_pkg.libdir pkg in
  let cachedir = Opkg_pkg.cachedir pkg in
  match Fpath.rem_prefix pkgdir mli with
  | None -> assert false
  | Some p -> Fpath.(cachedir // p -+ ".ocodoc")

let compile_mli ~ocamldoc ~force pkg mli =
  let mli = Opkg_cobj.Mli.path mli in
  let dst = compile_dst pkg mli in
  let cobjs_trail = Opkg_pkg.cobjs_trail pkg in
  let dst_trail = Opkg_btrail.v ~id:(Fpath.to_string dst) in
  let no_warn = Cmd.(v "-hide-warnings" % "-w" % "-a") in
  let incs = Cmd.(of_values ~slip:"-I" p @@ mli_incs pkg mli) in
  let odoc = Cmd.(ocamldoc %% no_warn % "-dump" % p dst %% incs % p mli) in
  let is_fresh =
    if force then Ok false else match Opkg_btrail.status dst_trail with
    | `Stale -> Ok false
    | `Fresh ->
        (* FIXME this is ugly *)
        if Opkg_btrail.witness dst_trail = Some "ERROR" then Ok true else
        OS.File.exists dst
  in
  is_fresh >>= function
  | true -> Ok ()
  | false ->
      OS.Dir.create ~path:true (Fpath.parent dst) >>= fun _ ->
      OS.Cmd.run_status odoc >>= begin function
      | `Exited 0 -> Opkg_digest.file dst >>| fun d -> Some d
      | _ ->
          OS.File.delete dst (* ocamldoc leaves leftovers *)
          >>| fun () -> Some "ERROR" (* FIXME *)
      end >>| fun digest ->
      Opkg_btrail.set_witness ~preds:([cobjs_trail]) dst_trail digest

let compile ~ocamldoc ~force pkg =
  let mlis = Opkg_cobj.mlis (Opkg_pkg.cobjs pkg) in
  let compile_mli = compile_mli ~ocamldoc ~force pkg in
  Opkg_log.time
    (fun _ m -> m "Compiled ocamldoc odoc files of %s" (Opkg_pkg.name pkg))
    (Opkg_log.on_iter_error_msg List.iter compile_mli) mlis;
  Ok ()

let pkg_odocs pkg =
  let add_odoc (seen, odocs as acc) mli =
    let odoc = compile_dst pkg mli in
    begin OS.File.exists odoc >>| function
    | false -> acc
    | true ->
        let fname = Fpath.filename odoc in
        match String.Set.mem fname seen with
        | false -> (String.Set.add fname seen, odoc :: odocs)
        | true ->
            Opkg_log.info
              (fun m -> m ~header:"HEURISTIC"
                  "%s: Multiple %s file, skipping %a"
                  (Opkg_pkg.name pkg) fname Fpath.pp odoc);
            acc
    end
    |> Logs.on_error_msg ~use:(fun _ -> acc)
  in
  let mlis = Opkg_cobj.mlis (Opkg_pkg.cobjs pkg) in
  let mlis = List.rev_map Opkg_cobj.Mli.path mlis in
  let mlis =
    (* part of the dupe heuristics, take smallest path on dupe *)
    List.sort Fpath.compare mlis
  in
  snd @@ List.fold_left add_odoc (String.Set.empty, []) mlis

let make_version p =
  match Opkg_pkg.version p |> R.ignore_error ~use:(fun _ -> None) with
  | None -> ""
  | Some v -> " " ^ v

let html_index_page pkg ocdocs =
  let mod_of_ocdoc ocdoc =
    String.Ascii.capitalize Fpath.(filename @@ rem_ext ocdoc)
  in
  let mods = List.map mod_of_ocdoc ocdocs in
  let mod_list = String.concat ~sep:" " @@  List.sort String.compare mods in
  strf "{1 {{:../index.html}Packages} – %s%s {%%html:%s%%}}\n\
        {2:api API}
        {!modules: %s}\n\
        {!indexlist}\n\
        {2:info Information}\n\
        {%%html:%s%%}"
    (Opkg_pkg.name pkg) (make_version pkg)
    (Opkg_api_doc.pkg_title_links ~htmldir:pkg_htmldir pkg)
    mod_list
    (Opkg_api_doc.pkg_info ~htmldir:pkg_htmldir pkg)

let html ~ocamldoc ~force pkg =
  let htmldir = pkg_htmldir pkg in
  let pkg_to_html pkg =
    let mlis = Opkg_cobj.mlis (Opkg_pkg.cobjs pkg) in
    match mlis with
    | [] ->
        Opkg_log.info (fun m -> m "%s: No mli files found" (Opkg_pkg.name pkg));
        OS.Dir.delete ~recurse:true htmldir
    | _ ->
        match pkg_odocs pkg with
        | [] ->
            Opkg_log.info
              (fun m -> m "%s: No odoc files generated" (Opkg_pkg.name pkg));
            OS.Dir.delete ~recurse:true htmldir
        | ocdocs ->
            let html_trail = Opkg_btrail.v ~id:(Fpath.to_string htmldir) in
            let ocdoc_trails =
              List.map (fun o -> Opkg_btrail.v ~id:(Fpath.to_string o)) ocdocs
            in
            let is_fresh =
              if force then Ok false else
              match Opkg_btrail.status html_trail with
              | `Fresh -> OS.Dir.exists htmldir
              | `Stale -> Ok false
            in
            is_fresh >>= function
            | true -> Ok ()
            | false ->
                OS.File.tmp "opkg-ocpage-%s" >>= fun intro_file ->
                let loads = Cmd.(of_values ~slip:"-load" p ocdocs) in
                let css = Cmd.(v "-css-style" % "../style.css") in
                let html = Cmd.(v "-html" % "-charset" % "utf-8") in
                let intro = Cmd.(v "-intro" % p intro_file) in
  (*            let title = Cmd.(v "-t" % Opkg_pkg.name pkg) in *)
                let odoc = Cmd.(ocamldoc % "-hide-warnings" %% loads %
                                "-sort" %% html %% css % "-colorize-code" %%
                                intro % "-short-functors" % "-d" % p htmldir)
            in
            OS.File.write intro_file (html_index_page pkg ocdocs)
            >>= fun () -> OS.Cmd.run_status odoc
            >>= begin function
            | `Exited 0 ->
                (* We don't really care about the digest *)
                Opkg_digest.mtimes [htmldir] >>| fun d -> Some d
            | _ ->
                OS.Dir.delete ~recurse:true htmldir >>| fun () -> None
            end >>| fun digest ->
            Opkg_btrail.set_witness ~preds:ocdoc_trails html_trail digest
  in
  OS.Dir.create ~path:true htmldir >>= fun _ ->
  Opkg_log.time
    (fun _ m -> m "Compiled HTML files of %s" (Opkg_pkg.name pkg))
    pkg_to_html pkg

let rec htmldir_css_and_index conf =
  let partition pkgs =
    let classify p (has_doc, no_doc as acc) =
      begin
        OS.Dir.exists (pkg_htmldir p) >>| function
        | true -> (p :: has_doc, no_doc)
        | false -> (has_doc, p :: no_doc)
      end
      |> Opkg_log.on_error_msg ~use:(fun _ -> acc)
    in
    let has_doc, no_doc = Opkg_pkg.Set.fold classify pkgs ([], []) in
    List.rev has_doc, List.rev no_doc
  in
  let htmldir = htmldir conf in
  Opkg_pkg.set conf
  >>= function pkgs -> Ok (partition pkgs)
  >>= fun (has_doc, no_doc) ->
  Ok (Opkg_api_doc.pkg_index conf ~tool:`Ocamldoc ~htmldir ~has_doc ~no_doc)
  >>= fun index -> OS.File.write Fpath.(htmldir / "index.html") index
  >>= fun () -> OS.File.read (css_file conf)
  >>= fun css -> OS.File.write Fpath.(htmldir / "style.css") css

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
